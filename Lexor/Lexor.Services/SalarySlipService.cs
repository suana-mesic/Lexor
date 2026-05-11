using FluentValidation;
using FluentValidation.Results;
using Lexor.Model.Constants;
using Lexor.Model.Enums;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using Lexor.Services.LeaveStateMachine;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;

namespace Lexor.Services
{
    public class SalarySlipService : BaseReadService<SalarySlip, SalarySlipResponse, SalarySlipCalculationSearchObject>, ISalarySlipService
    {
        protected readonly IValidator<SalarySlipCalculationRequest> _salarySlipCalculationValidator;
        protected readonly IValidator<SalarySlipSingleRecalculationRequest> _salarySlipSingleRecalcValidator;
        protected readonly IValidator<SalarySlipAllRecalculationRequest> _salarySlipAllRecalcValidator;
        protected readonly IValidator<SalarySlipPayAllRequest> _salarySlipPayAllValidator;
        protected readonly IValidator<SalarySlipPaySingleRequest> _salarySlipPaySingleValidator;
        protected readonly IAuthenticatedUserAccessor _userAccessor;

        public SalarySlipService(
            LexorDbContext dbContext,
            IMapper mapper,
            IValidator<SalarySlipCalculationRequest> salarySlipCalculationValidator,
            IValidator<SalarySlipSingleRecalculationRequest> salarySlipRecalcValidator,
            IValidator<SalarySlipAllRecalculationRequest> salarySlipAllRecalcValidator,
            IValidator<SalarySlipPayAllRequest> salarySlipPayAllValidator,
            IValidator<SalarySlipPaySingleRequest> salarySlipPaySingleValidator,
            IAuthenticatedUserAccessor userAccessor) : base(dbContext, mapper)
        {
            _salarySlipCalculationValidator = salarySlipCalculationValidator;
            _salarySlipSingleRecalcValidator = salarySlipRecalcValidator;
            _salarySlipAllRecalcValidator = salarySlipAllRecalcValidator;
            _salarySlipPayAllValidator = salarySlipPayAllValidator;
            _salarySlipPaySingleValidator = salarySlipPaySingleValidator;
            _userAccessor = userAccessor;
        }

        protected override IQueryable<SalarySlip> ApplyFilters(IQueryable<SalarySlip> query, SalarySlipCalculationSearchObject? search)
        {
            if (search?.Year.HasValue == true)
                query = query.Where(ss => ss.Year == search.Year);

            if (search?.Month.HasValue == true)
                query = query.Where(ss => ss.Month == search.Month);

            if (search?.Status.HasValue == true)
                query = query.Where(ss => ss.Status == search.Status);

            if (_userAccessor.IsInRole(RoleNames.Administrator))
            {
                // admin may optionally filter by any employee
                if (search?.EmployeeId.HasValue == true)
                    query = query.Where(ss => ss.EmployeeId == search.EmployeeId);
            }
            else
            {
                // non-admin: server forces scope to own slips regardless of what client sent
                var currentUserId = _userAccessor.GetUserId();
                query = query.Where(ss => ss.Employee.UserId == currentUserId);
            }

            return query;
        }

        protected override IQueryable<SalarySlip> IncludeRelatedEntities(SalarySlipCalculationSearchObject? search, IQueryable<SalarySlip> query = null)
        {
            // Items are intentionally NOT loaded for list view; only the detail (GetByIdAsync) needs the breakdown.
            return query
                .Include(ss => ss.Employee)
                    .ThenInclude(e => e.User);
        }

        public override async Task<SalarySlipResponse> GetByIdAsync(int id)
        {
            // Single query: load slip with everything needed for both ownership check and detail view.
            var entity = await _dbContext.Set<SalarySlip>()
                .Include(ss => ss.Employee).ThenInclude(e => e.User)
                .Include(ss => ss.Items)
                .FirstOrDefaultAsync(ss => ss.Id == id)
                ?? throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(SalarySlip), id));

            // Non-admin: must be the owner of SalarySlip.
            if (!_userAccessor.IsInRole(RoleNames.Administrator))
            {
                var currentUserId = _userAccessor.GetUserId();
                if (entity.Employee.UserId != currentUserId)
                    throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(SalarySlip), id));
            }

            return _mapper.Map<SalarySlipResponse>(entity);
        }

        public async Task<int> MarkAllSalariesAsPaid(SalarySlipPayAllRequest request)
        {
            var validationErrors = await _salarySlipPayAllValidator.ValidateAsync(request);
            if (!validationErrors.IsValid)
                throw new ValidationException(validationErrors.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));

            var pendingSalaries = await _dbContext.Set<SalarySlip>()
                .Where(ss => ss.Month == request.Month
                          && ss.Year == request.Year
                          && ss.Status == SalarySlipStatus.Pending)
                .ToListAsync();

            if (!pendingSalaries.Any())
                throw new KeyNotFoundException(
                    $"Ne postoje plate za mjesec {SalarySlipCalculation.GetMonthName(request.Month)} i godinu {request.Year} u statusu čekanja na plaćanje.");

            foreach (var salarySlip in pendingSalaries)
            {
                salarySlip.Status = SalarySlipStatus.Paid;
                salarySlip.PaidAt = DateTime.UtcNow;
                salarySlip.MarkedAsPaidByAdminId = _userAccessor.GetUserId();
            }
            await _dbContext.SaveChangesAsync();

            return pendingSalaries.Count;
        }

        public async Task<SalarySlipResponse> MarkSingleSalaryAsPaid(SalarySlipPaySingleRequest request)
        {
            var validationErrors = await _salarySlipPaySingleValidator.ValidateAsync(request);
            if (!validationErrors.IsValid)
                throw new ValidationException(validationErrors.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));

            var pendingSalary = await _dbContext.Set<SalarySlip>()
                .Where(ss => ss.Month == request.Month
                          && ss.Year == request.Year
                          && ss.EmployeeId == request.EmployeeId
                          && ss.Status == SalarySlipStatus.Pending)
                .FirstOrDefaultAsync();

            if (pendingSalary == null)
            {
                var employeeFullName = await _dbContext.Set<Employee>()
                    .Where(e => e.Id == request.EmployeeId)
                    .Select(e => e.User.FirstName + " " + e.User.LastName)
                    .FirstOrDefaultAsync();

                throw new KeyNotFoundException(
                    $"Ne postoji plata za uposlenika {employeeFullName}, mjesec {SalarySlipCalculation.GetMonthName(request.Month)} i godinu {request.Year} u statusu čekanja na plaćanje.");
            }

            pendingSalary.Status = SalarySlipStatus.Paid;
            pendingSalary.PaidAt = DateTime.UtcNow;
            pendingSalary.MarkedAsPaidByAdminId = _userAccessor.GetUserId();

            await _dbContext.SaveChangesAsync();

            return await GetByIdAsync(pendingSalary.Id);
        }

        public async Task<int> RecalculateAllSalaries(SalarySlipAllRecalculationRequest request)
        {
            var validationErrors = await _salarySlipAllRecalcValidator.ValidateAsync(request);
            if (!validationErrors.IsValid)
                throw new ValidationException(validationErrors.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));

            // 1) Find ALL existing non-paid slips for given month & year
            var existingSlips = await _dbContext.Set<SalarySlip>()
                .Include(ss => ss.Items)
                .Where(ss => ss.Year == request.Year
                          && ss.Month == request.Month
                          && ss.Status != SalarySlipStatus.Paid)
                .ToListAsync();

            if (!existingSlips.Any())
                throw new KeyNotFoundException(
                    $"Nisu pronađene obračunate i neplaćene plate za mjesec {SalarySlipCalculation.GetMonthName(request.Month)} i godinu {request.Year}.");

            // 2) Remove all old slips + their items, otherwise we'd end up with duplicates
            //    (and InsertOrRecalculateSalaries would skip these employees as already processed)
            var allItems = existingSlips.SelectMany(s => s.Items).ToList();
            _dbContext.Set<SalarySlipItem>().RemoveRange(allItems);
            _dbContext.Set<SalarySlip>().RemoveRange(existingSlips);
            await _dbContext.SaveChangesAsync();

            // 3) Reuse the calculation logic for the whole period
            var calculation = new SalarySlipCalculationRequest
            {
                Month = request.Month,
                Year = request.Year
            };

            return await InsertOrRecalculateSalaries(calculation);
        }

        public async Task<SalarySlipResponse> RecalculateSingleSalary(SalarySlipSingleRecalculationRequest request)
        {
            var validationErrors = await _salarySlipSingleRecalcValidator.ValidateAsync(request);
            if (!validationErrors.IsValid)
                throw new ValidationException(validationErrors.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));

            // 1) Find existing non-paid slip for this employee & period
            var existingSlip = await _dbContext.Set<SalarySlip>()
                .Include(ss => ss.Items)
                .Where(ss => ss.EmployeeId == request.EmployeeId
                          && ss.Year == request.Year
                          && ss.Month == request.Month
                          && ss.Status != SalarySlipStatus.Paid)
                .FirstOrDefaultAsync();

            if (existingSlip == null)
            {
                var employeeFullName = await _dbContext.Set<Employee>()
                    .Where(e => e.Id == request.EmployeeId)
                    .Select(e => e.User.FirstName + " " + e.User.LastName)
                    .FirstOrDefaultAsync();

                if (string.IsNullOrWhiteSpace(employeeFullName))
                    throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Employee), request.EmployeeId));

                throw new KeyNotFoundException(
                    $"Ne postoji podatak o plati za uposlenika {employeeFullName}, mjesec {SalarySlipCalculation.GetMonthName(request.Month)} i godinu {request.Year}.");
            }

            // 2) Remove old slip + its items, otherwise we'd end up with duplicates
            _dbContext.Set<SalarySlipItem>().RemoveRange(existingSlip.Items);
            _dbContext.Set<SalarySlip>().Remove(existingSlip);
            await _dbContext.SaveChangesAsync();

            // 3) Reuse the calculation logic, scoped to a single employee
            var calculation = new SalarySlipCalculationRequest
            {
                EmployeeId = request.EmployeeId,
                Month = request.Month,
                Year = request.Year
            };
            var count = await InsertOrRecalculateSalaries(calculation);

            if (count == 0)
                throw new InvalidOperationException("Nije moguće generisati novi obračun za odabranog uposlenika.");

            // Fetch the newly generated slip for return
            var newSlipId = await _dbContext.Set<SalarySlip>()
                .Where(ss => ss.EmployeeId == request.EmployeeId
                          && ss.Year == request.Year
                          && ss.Month == request.Month)
                .Select(ss => ss.Id)
                .FirstOrDefaultAsync();

            return await GetByIdAsync(newSlipId);
        }

        public async Task<int> InsertOrRecalculateSalaries(SalarySlipCalculationRequest request)
        {
            var validationErrors = await _salarySlipCalculationValidator.ValidateAsync(request);
            if (!validationErrors.IsValid)
                throw new ValidationException(validationErrors.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));

            // 1) Active payroll settings (latest valid for current period)
            var settings = await _dbContext.Set<PayrollSettings>()
                .Where(ps => ps.ValidFrom <= DateTime.UtcNow
                          && (ps.ValidTo == null || ps.ValidTo >= DateTime.UtcNow))
                .OrderByDescending(ps => ps.ValidFrom)
                .FirstOrDefaultAsync()
                ?? throw new KeyNotFoundException("Ne postoje važeće postavke obračuna za trenutni period.");

            // 2) Skip employees who already have a slip for this period
            var alreadyProcessed = new List<int>();
            if (request.EmployeeId == null)
            {
                alreadyProcessed = await _dbContext.Set<SalarySlip>()
                    .Where(ss => ss.Year == request.Year && ss.Month == request.Month)
                    .Select(ss => ss.EmployeeId)
                    .ToListAsync();
            }

            Console.WriteLine($"[DEBUG] alreadyProcessed count: {alreadyProcessed.Count}");

            // 3) Active employees with their active contract.
            //    If EmployeeId is given (recalc path), restrict to that one employee.
            var employees = await _dbContext.Set<Employee>()
                .Where(e => e.IsActive
                         && !alreadyProcessed.Contains(e.Id)
                         && (request.EmployeeId == null || e.Id == request.EmployeeId))
                .Include(e => e.Contracts)
                .Include(e => e.User)
                .ToListAsync();

            Console.WriteLine($"[DEBUG] active employees: {employees.Count}");
            foreach (var emp in employees)
            {
                var activeContracts = emp.Contracts.Count(c => c.IsActive);
                Console.WriteLine($"[DEBUG] Employee Id={emp.Id} ({emp.User?.FirstName} {emp.User?.LastName}), total contracts={emp.Contracts.Count}, active={activeContracts}");
            }

            // 4) Working days in this calendar month (Mon-Fri)
            var workingDays = SalarySlipCalculation.GetWorkingDaysInMonth(request.Year, request.Month);

            var generated = new List<SalarySlip>();

            foreach (var employee in employees)
            {
                // Use active contract; skip if employee has none
                var contract = employee.Contracts.FirstOrDefault(c => c.IsActive);
                if (contract == null)
                {
                    Console.WriteLine($"[DEBUG] SKIP employee {employee.Id} — no active contract");
                    continue;
                }

                var workHoursPerDay = contract.WorkHoursPerDay;
                var standardMonthlyHours = workingDays * workHoursPerDay;
                var hourlyRate = standardMonthlyHours > 0
                    ? contract.BrutoSalary / standardMonthlyHours
                    : 0m;

                var bruto = contract.BrutoSalary;

                // 5) Overtime: per day, count hours above WorkHoursPerDay
                var attendances = await _dbContext.Set<Attendance>()
                    .Where(a => a.EmployeeId == employee.Id
                             && a.Date.Year == request.Year
                             && a.Date.Month == request.Month
                             && a.WorkedHours.HasValue)
                    .ToListAsync();

                var overtimeHours = attendances
                    .Sum(a => Math.Max(0m, (a.WorkedHours ?? 0m) - workHoursPerDay));

                var overtimeAmount = Math.Round(overtimeHours * hourlyRate * settings.OvertimeMultiplier, 2);

                // 6) Unpaid leave days in this period (only Approved leaves with !LeaveType.IsPaid)
                var approvedState = nameof(ApprovedLeaveState);
                var unpaidLeaves = await _dbContext.Set<Leave>()
                    .Include(l => l.LeaveType)
                    .Where(l => l.EmployeeId == employee.Id
                             && l.State == approvedState
                             && !l.LeaveType.IsPaid
                             && l.DateFrom.Year == request.Year
                             && l.DateFrom.Month == request.Month)
                    .ToListAsync();

                var unpaidDays = unpaidLeaves.Sum(l => l.NumberOfDays);
                var unpaidAmount = Math.Round(unpaidDays * workHoursPerDay * hourlyRate, 2);

                // 7) Adjusted bruto (contracted bruto + overtime − unpaid leave)
                var adjustedBruto = bruto + overtimeAmount - unpaidAmount;

                // 8) Contributions (calculated from adjusted bruto)
                var pioMio = Math.Round(adjustedBruto * settings.PioMioRate / 100m, 2);
                var health = Math.Round(adjustedBruto * settings.HealthInsuranceRate / 100m, 2);
                var unemployment = Math.Round(adjustedBruto * settings.UnemploymentRate / 100m, 2);
                var totalContributions = pioMio + health + unemployment;

                // 9) Tax base = adjusted bruto − contributions − personal deduction
                var taxBase = Math.Max(0m, adjustedBruto - totalContributions - settings.PersonalDeduction);
                var tax = Math.Round(taxBase * settings.IncomeTaxRate / 100m, 2);

                // 10) Net = adjusted bruto − contributions − tax
                var net = adjustedBruto - totalContributions - tax;

                // 11) Build entity + breakdown items
                var slip = new SalarySlip
                {
                    EmployeeId = employee.Id,
                    PayrollSettingsId = settings.Id,
                    Year = request.Year,
                    Month = request.Month,
                    BrutoSalary = bruto,
                    AdjustedBruto = adjustedBruto,
                    TotalContributions = totalContributions,
                    TaxBase = taxBase,
                    Tax = tax,
                    NetSalary = net,
                    Status = SalarySlipStatus.Pending,
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

            // 12) Reload generated slips with includes for response mapping
            return generated.Count;
        }
    }
}
