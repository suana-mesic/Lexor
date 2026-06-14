using Lexor.Model.Enums;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using Lexor.Services.StateMachine.LeaveStateMachine;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Lexor.Services.StateMachine.SalarySlipStateMachine
{
    public class BaseSalarySlipState
    {
        protected readonly LexorDbContext _dbContext;
        protected readonly IMapper _mapper;
        protected readonly IAuthenticatedUserAccessor _userAccessor;
        private readonly IServiceProvider _serviceProvider;

        public BaseSalarySlipState(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _userAccessor = userAccessor;
            _serviceProvider = serviceProvider;
        }

        public virtual Task<int> GenerateSalarySlipsForPeriod(SalarySlipCalculationRequest request)
        {
            throw new InvalidOperationException("Nije moguće obračunati plate u trenutnom stanju.");
        }
        public virtual Task<SalarySlipResponse> RecalculateSingleSalary(SalarySlipSingleRecalculationRequest request)
        {
            throw new InvalidOperationException("Nije moguće ponovo obračunati platu u trenutnom stanju.");
        }

        public virtual Task<SalarySlipResponse> MarkSingleSalaryAsPaid(SalarySlipPaySingleRequest request)
        {
            throw new InvalidOperationException("Nije moguće označiti platu kao plaćenu u trenutnom stanju.");
        }

        public virtual Task<SalarySlipResponse> MarkSingleSalaryAsApproved(SalarySlipApproveSingleRequest request)
        {
            throw new InvalidOperationException("Nije moguće označiti platu kao odobrenu u trenutnom stanju.");
        }


        public BaseSalarySlipState GetSalarySlipState(string stateName)
        {
            switch (stateName)
            {
                case nameof(InitialSalarySlipState):
                    return _serviceProvider.GetService<InitialSalarySlipState>()!;
                case nameof(PendingSalarySlipState):
                    return _serviceProvider.GetService<PendingSalarySlipState>()!;
                case nameof(ApprovedSalarySlipState):
                    return _serviceProvider.GetService<ApprovedSalarySlipState>()!;
                case nameof(PaidSalarySlipState):
                    return _serviceProvider.GetService<PaidSalarySlipState>()!;
                default:
                    throw new InvalidOperationException($"Stanje plate {stateName} je nepoznato.");
            }
        }

        public virtual List<string> GetAllowedActions()
        {
            return new List<string>();
        }

        // Shared salary slip generation logic. Each state's public method decides WHETHER to call this;
        // the helper itself carries no state semantics, just the math + EF work.
        protected async Task<int> GenerateSlipsCore(SalarySlipCalculationRequest request)
        {
            // 1) Active payroll settings — chosen for the payroll period itself, not "today".
            //    Otherwise retroactive calculations would use the wrong (current) settings.
            var periodDate = new DateTime(request.Year, request.Month, 15);
            var settings = await _dbContext.Set<PayrollSettings>()
                .Where(ps => ps.ValidFrom <= periodDate
                          && (ps.ValidTo == null || ps.ValidTo >= periodDate))
                .OrderByDescending(ps => ps.ValidFrom)
                .FirstOrDefaultAsync()
                ?? throw new KeyNotFoundException($"Ne postoje važeće postavke obračuna za period {request.Month}/{request.Year}.");

            // 2) Always skip employees who already have a slip for this period (defense in depth
            //    against duplicate creation in both bulk and single-employee paths).
            var alreadyProcessedQuery = _dbContext.Set<SalarySlip>()
                .Where(ss => ss.Year == request.Year && ss.Month == request.Month);
            if (request.EmployeeId != null)
                alreadyProcessedQuery = alreadyProcessedQuery.Where(ss => ss.EmployeeId == request.EmployeeId);
            var alreadyProcessed = await alreadyProcessedQuery
                .Select(ss => ss.EmployeeId)
                .ToListAsync();

            // 3) Active employees with their active contract.
            var employees = await _dbContext.Set<Employee>()
                .Where(e => e.IsActive
                         && !alreadyProcessed.Contains(e.Id)
                         && (request.EmployeeId == null || e.Id == request.EmployeeId))
                .Include(e => e.Contracts)
                .Include(e => e.User)
                .ToListAsync();

            if (!employees.Any())
                return 0;

            // 4) Batch-load attendances and unpaid leaves for ALL selected employees at once
            //    to avoid N+1 queries inside the per-employee loop.
            var employeeIds = employees.Select(e => e.Id).ToList();
            var approvedState = nameof(ApprovedLeaveState);

            var attendancesByEmployee = await _dbContext.Set<Attendance>()
                .Where(a => employeeIds.Contains(a.EmployeeId)
                         && a.Date.Year == request.Year
                         && a.Date.Month == request.Month
                         && a.WorkedHours.HasValue)
                .GroupBy(a => a.EmployeeId)
                .ToDictionaryAsync(g => g.Key, g => g.ToList());

            var unpaidLeavesByEmployee = await _dbContext.Set<Leave>()
                .Include(l => l.LeaveType)
                .Where(l => employeeIds.Contains(l.EmployeeId)
                         && l.State == approvedState
                         && !l.LeaveType.IsPaid
                         && l.DateFrom.Year == request.Year
                         && l.DateFrom.Month == request.Month)
                .GroupBy(l => l.EmployeeId)
                .ToDictionaryAsync(g => g.Key, g => g.ToList());

            var payrollSettings = await _dbContext.PayrollSettings
                .OrderByDescending(x => x.ValidFrom)
                .FirstAsync();

            // 5) Working days in this calendar month (Mon-Fri)
            var workingDays = SalarySlipCalculation.GetWorkingDaysInMonth(request.Year, request.Month, payrollSettings);

            var generated = new List<SalarySlip>();

            foreach (var employee in employees)
            {
                // Use active contract; skip employees without one (e.g. recently deactivated).
                var contract = employee.Contracts.FirstOrDefault(c => c.IsActive);
                if (contract == null)
                    continue;

                var workHoursPerDay = contract.WorkHoursPerDay;
                var standardMonthlyHours = workingDays * workHoursPerDay;
                var hourlyRate = standardMonthlyHours > 0
                    ? contract.BrutoSalary / standardMonthlyHours
                    : 0m;

                var bruto = contract.BrutoSalary;

                // 6) Overtime: per day, count hours above WorkHoursPerDay
                var attendances = attendancesByEmployee.GetValueOrDefault(employee.Id, new List<Attendance>());
                var overtimeHours = attendances
                    .Sum(a => Math.Max(0m, (a.WorkedHours ?? 0m) - workHoursPerDay));
                var overtimeAmount = Math.Round(overtimeHours * hourlyRate * settings.OvertimeMultiplier, 2);

                // 7) Unpaid leave days in this period
                var unpaidLeaves = unpaidLeavesByEmployee.GetValueOrDefault(employee.Id, new List<Leave>());
                var unpaidDays = unpaidLeaves.Sum(l => l.NumberOfDays);
                var unpaidAmount = Math.Round(unpaidDays * workHoursPerDay * hourlyRate, 2);

                // 8) Adjusted bruto (contracted bruto + overtime − unpaid leave)
                var adjustedBruto = bruto + overtimeAmount - unpaidAmount;

                // 9) Contributions (calculated from adjusted bruto)
                var pioMio = Math.Round(adjustedBruto * settings.PioMioRate / 100m, 2);
                var health = Math.Round(adjustedBruto * settings.HealthInsuranceRate / 100m, 2);
                var unemployment = Math.Round(adjustedBruto * settings.UnemploymentRate / 100m, 2);
                var totalContributions = pioMio + health + unemployment;

                // 10) Tax base = adjusted bruto − contributions − personal deduction
                var taxBase = Math.Max(0m, adjustedBruto - totalContributions - settings.PersonalDeduction);
                var tax = Math.Round(taxBase * settings.IncomeTaxRate / 100m, 2);

                // 11) Net = adjusted bruto − contributions − tax
                var net = Math.Round(adjustedBruto - totalContributions - tax, 2);

                // 12) Build entity + breakdown items
                var slip = new SalarySlip
                {
                    EmployeeId = employee.Id,
                    PayrollSettingsId = settings.Id,
                    Year = request.Year,
                    Month = request.Month,
                    BrutoSalary = bruto,
                    AdjustedBruto = Math.Round(adjustedBruto, 2),
                    TotalContributions = totalContributions,
                    TaxBase = Math.Round(taxBase, 2),
                    Tax = tax,
                    NetSalary = net,
                    State = nameof(PendingSalarySlipState),
                    GeneratedAt = DateTime.UtcNow
                };

                slip.Items.Add(new SalarySlipItem
                {
                    ItemType = SalarySlipItemType.BrutoBase,
                    Name = "Ugovorena bruto plata",
                    Amount = bruto
                });

                if (overtimeHours > 0)
                {
                    slip.Items.Add(new SalarySlipItem
                    {
                        ItemType = SalarySlipItemType.Overtime,
                        Name = "Prekovremeni sati",
                        Description = $"{overtimeHours} h × {Math.Round(hourlyRate, 2)} KM × {settings.OvertimeMultiplier}",
                        Quantity = overtimeHours,
                        Rate = Math.Round(hourlyRate, 2),
                        Multiplier = settings.OvertimeMultiplier,
                        Amount = overtimeAmount
                    });
                }

                if (unpaidDays > 0)
                {
                    slip.Items.Add(new SalarySlipItem
                    {
                        ItemType = SalarySlipItemType.UnpaidLeave,
                        Name = "Neplaćeno odsustvo",
                        Description = $"{unpaidDays} dana × {workHoursPerDay} h × {Math.Round(hourlyRate, 2)} KM",
                        Quantity = unpaidDays,
                        Rate = Math.Round(hourlyRate, 2),
                        Amount = -unpaidAmount
                    });
                }

                slip.Items.Add(new SalarySlipItem
                {
                    ItemType = SalarySlipItemType.PioMio,
                    Name = "PIO/MIO",
                    Rate = settings.PioMioRate,
                    Amount = -pioMio
                });
                slip.Items.Add(new SalarySlipItem
                {
                    ItemType = SalarySlipItemType.Health,
                    Name = "Zdravstveno osiguranje",
                    Rate = settings.HealthInsuranceRate,
                    Amount = -health
                });
                slip.Items.Add(new SalarySlipItem
                {
                    ItemType = SalarySlipItemType.Unemployment,
                    Name = "Doprinos za nezaposlenost",
                    Rate = settings.UnemploymentRate,
                    Amount = -unemployment
                });
                slip.Items.Add(new SalarySlipItem
                {
                    ItemType = SalarySlipItemType.PersonalDeduction,
                    Name = "Lični odbitak",
                    Amount = -settings.PersonalDeduction
                });
                slip.Items.Add(new SalarySlipItem
                {
                    ItemType = SalarySlipItemType.IncomeTax,
                    Name = "Porez na dohodak",
                    Rate = settings.IncomeTaxRate,
                    Amount = -tax
                });

                _dbContext.Set<SalarySlip>().Add(slip);
                generated.Add(slip);
            }

            await _dbContext.SaveChangesAsync();

            return generated.Count;
        }
    }
}
