using Lexor.Model.Exceptions;
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
            throw new BusinessException("Nije moguće obračunati plate u trenutnom stanju.");
        }
        public virtual Task<SalarySlipResponse> RecalculateSingleSalary(SalarySlipSingleRecalculationRequest request)
        {
            throw new BusinessException("Nije moguće ponovo obračunati platu u trenutnom stanju.");
        }

        public virtual Task<SalarySlipResponse> MarkSingleSalaryAsPaid(SalarySlipPaySingleRequest request)
        {
            throw new BusinessException("Nije moguće označiti platu kao plaćenu u trenutnom stanju.");
        }

        public virtual Task<SalarySlipResponse> MarkSingleSalaryAsApproved(SalarySlipApproveSingleRequest request)
        {
            throw new BusinessException("Nije moguće označiti platu kao odobrenu u trenutnom stanju.");
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
                    throw new BusinessException("Platna lista je u nevažećem stanju.");
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
                ?? throw new NotFoundException($"Ne postoje važeće postavke obračuna za period {request.Month}/{request.Year}.");

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
            var completedState = nameof(CompletedLeaveState);
            var monthStart = new DateOnly(request.Year, request.Month, 1);
            var monthEnd = new DateOnly(request.Year, request.Month, DateTime.DaysInMonth(request.Year, request.Month));
            // DateTime bounds of the same month, for overlap checks against Contract's DateTime fields.
            var monthStartDt = monthStart.ToDateTime(TimeOnly.MinValue);
            var monthEndDt = monthEnd.ToDateTime(TimeOnly.MinValue);

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
                         && (l.State == approvedState || l.State == completedState)
                         && !l.LeaveType.IsPaid
                         && l.DateFrom <= monthEnd
                         && l.DateTo >= monthStart)
                .GroupBy(l => l.EmployeeId)
                .ToDictionaryAsync(g => g.Key, g => g.ToList());

            // 5) Working days in this calendar month — use the period-correct settings
            //    resolved above, not a second "latest settings" load.
            var workingDays = SalarySlipCalculation.GetWorkingDaysInMonth(request.Year, request.Month, settings);

            var generated = new List<SalarySlip>();

            // Working days (per PayrollSettings work-day mask) between two dates, inclusive.
            int WorkingDaysInRange(DateOnly from, DateOnly to)
            {
                var count = 0;
                for (var d = from; d <= to; d = d.AddDays(1))
                    if (settings.IsWorkDay(d.DayOfWeek)) count++;
                return count;
            }

            foreach (var employee in employees)
            {
                // Pick the contract in effect during the payroll PERIOD (not "today" and not by the
                // IsActive flag). A contract counts if it OVERLAPS the payroll month at all, so a
                // mid-month hire (contract starting e.g. on the 23rd) is still picked up for that month.
                // Future-dated contracts (starting after the month ends) are ignored. If several overlap,
                // the latest-starting one wins.
                var contract = employee.Contracts
                    .Where(c => c.StartDate.Date <= monthEndDt
                             && (c.EndDate == null || c.EndDate.Value.Date >= monthStartDt))
                    .OrderByDescending(c => c.StartDate)
                    .FirstOrDefault();
                if (contract == null)
                    continue;

                var workHoursPerDay = contract.WorkHoursPerDay;
                var standardMonthlyHours = workingDays * workHoursPerDay;
                var hourlyRate = standardMonthlyHours > 0
                    ? contract.BrutoSalary / standardMonthlyHours
                    : 0m;

                var bruto = contract.BrutoSalary;

                // 6) Overtime: only on WORKING days, hours above WorkHoursPerDay (e.g. stayed 9h instead of 8h).
                // A 30-minute daily grace period applies (common payroll practice): a day counts as
                // overtime only if the extra time exceeds it, so a few stray minutes past the end of the
                // day are not paid as overtime. Once past the grace, the full extra time is counted.
                const decimal overtimeGraceHours = 0.5m;
                var attendances = attendancesByEmployee.GetValueOrDefault(employee.Id, new List<Attendance>());
                var overtimeHours = attendances
                    .Where(a => settings.IsWorkDay(a.Date.DayOfWeek))
                    .Select(a => Math.Max(0m, (a.WorkedHours ?? 0m) - workHoursPerDay))
                    .Where(extra => extra > overtimeGraceHours)
                    .Sum();
                var overtimeAmount = Math.Round(overtimeHours * hourlyRate * settings.OvertimeMultiplier, 2);

                // 7) Unpaid leave days in this period
                var unpaidLeaves = unpaidLeavesByEmployee.GetValueOrDefault(employee.Id, new List<Leave>());
                // Count only the WORKING days of each leave that fall INSIDE this payroll month.
                var unpaidDays = unpaidLeaves.Sum(l =>
                {
                    var from = l.DateFrom > monthStart ? l.DateFrom : monthStart;
                    var to = l.DateTo < monthEnd ? l.DateTo : monthEnd;
                    return WorkingDaysInRange(from, to);
                });
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
                // Personal deduction reduces ONLY the tax base (not net pay). Show it as the
                // amount subtracted to reach the tax base, immediately followed by the tax base.
                if (settings.PersonalDeduction > 0)
                {
                    slip.Items.Add(new SalarySlipItem
                    {
                        ItemType = SalarySlipItemType.PersonalDeduction,
                        Name = "Lični odbitak",
                        Description = "Umanjuje poreznu osnovicu",
                        Amount = settings.PersonalDeduction
                    });
                }
                slip.Items.Add(new SalarySlipItem
                {
                    ItemType = SalarySlipItemType.TaxBase,
                    Name = "Porezna osnovica",
                    Amount = Math.Round(taxBase, 2)
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
