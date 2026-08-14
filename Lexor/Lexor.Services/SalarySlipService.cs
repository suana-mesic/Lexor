using Lexor.Model.Exceptions;
using FluentValidation;
using FluentValidation.Results;
using Lexor.Model.Constants;
using Lexor.Model.Enums;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using Lexor.Services.StateMachine.SalarySlipStateMachine;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Linq.Dynamic.Core;
using Lexor.Services.Reports;

namespace Lexor.Services
{
    public class SalarySlipService : BaseReadService<SalarySlip, SalarySlipResponse, SalarySlipCalculationSearchObject>, ISalarySlipService
    {
        private readonly IValidator<SalarySlipCalculationRequest> _salarySlipCalculationValidator;
        private readonly IValidator<SalarySlipSingleRecalculationRequest> _salarySlipSingleRecalcValidator;
        private readonly IValidator<SalarySlipAllRecalculationRequest> _salarySlipAllRecalcValidator;
        private readonly IValidator<SalarySlipPayAllRequest> _salarySlipPayAllValidator;
        private readonly IValidator<SalarySlipPaySingleRequest> _salarySlipPaySingleValidator;
        private readonly IValidator<SalarySlipApproveAllRequest> _salarySlipApproveAllValidator;
        private readonly IValidator<SalarySlipApproveSingleRequest> _salarySlipApproveSingleValidator;
        private readonly IAuthenticatedUserAccessor _userAccessor;
        private readonly BaseSalarySlipState _salarySlipState;
        public SalarySlipService(
            LexorDbContext dbContext,
            IMapper mapper,
            IValidator<SalarySlipCalculationRequest> salarySlipCalculationValidator,
            IValidator<SalarySlipSingleRecalculationRequest> salarySlipRecalcValidator,
            IValidator<SalarySlipAllRecalculationRequest> salarySlipAllRecalcValidator,
            IValidator<SalarySlipPayAllRequest> salarySlipPayAllValidator,
            IValidator<SalarySlipPaySingleRequest> salarySlipPaySingleValidator,
            IValidator<SalarySlipApproveAllRequest> salarySlipApproveAllValidator,
            IValidator<SalarySlipApproveSingleRequest> salarySlipApproveSingleValidator,
            IAuthenticatedUserAccessor userAccessor,
            ILogger<SalarySlipService> logger,
            BaseSalarySlipState salarySlipState) : base(dbContext, mapper)
        {
            _salarySlipCalculationValidator = salarySlipCalculationValidator;
            _salarySlipSingleRecalcValidator = salarySlipRecalcValidator;
            _salarySlipAllRecalcValidator = salarySlipAllRecalcValidator;
            _salarySlipPayAllValidator = salarySlipPayAllValidator;
            _salarySlipPaySingleValidator = salarySlipPaySingleValidator;
            _salarySlipApproveAllValidator = salarySlipApproveAllValidator;
            _salarySlipApproveSingleValidator = salarySlipApproveSingleValidator;
            _userAccessor = userAccessor;
            _salarySlipState = salarySlipState;
        }

        protected override IQueryable<SalarySlip> ApplyFilters(IQueryable<SalarySlip> query, SalarySlipCalculationSearchObject? search)
        {
            if (search?.Year.HasValue == true)
                query = query.Where(ss => ss.Year == search.Year);

            if (search?.Month.HasValue == true)
                query = query.Where(ss => ss.Month == search.Month);

            if (search?.Status.HasValue == true)
            {
                var stateName = MapStatusToStateName(search.Status.Value);
                query = query.Where(ss => ss.State == stateName);
            }

            if (_userAccessor.IsBackOffice())
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
                ?? throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(SalarySlip), id));

            // Non-admin: must be the owner of SalarySlip.
            if (!_userAccessor.IsBackOffice())
            {
                var currentUserId = _userAccessor.GetUserId();
                if (entity.Employee.UserId != currentUserId)
                    throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(SalarySlip), id));
            }

            return _mapper.Map<SalarySlipResponse>(entity);
        }
        public async Task<int> MarkAllSalariesAsApproved(SalarySlipApproveAllRequest request)
        {
            var validationErrors = await _salarySlipApproveAllValidator.ValidateAsync(request);
            if (!validationErrors.IsValid)
                throw new ValidationException(validationErrors.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));

            var pendingStateName = nameof(PendingSalarySlipState);
            var approvedStateName = nameof(ApprovedSalarySlipState);
            var currentUserId = _userAccessor.GetUserId();
            var now = DateTime.UtcNow;

            // ExecuteUpdateAsync sends ONE SQL UPDATE to the database that changes all matching rows at once.
            // With a foreach loop we would first load all 100 salary slips into memory, change each one in C#,
            // and then send the updates back to the database — that means a lot of queries and a lot of memory.
            // This way we send just one query, use almost no memory, and we don't need SaveChangesAsync.

            var updatedCount = await _dbContext.Set<SalarySlip>()
                .Where(ss => ss.Month == request.Month
                          && ss.Year == request.Year
                          && ss.State == pendingStateName)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(s => s.State, approvedStateName)
                    .SetProperty(s => s.ApprovedAt, now)
                    .SetProperty(s => s.MarkedAsApprovedByAdminId, currentUserId));

            if (updatedCount == 0)
                throw new NotFoundException(
                    $"Ne postoje plate za mjesec {SalarySlipCalculation.GetMonthName(request.Month)} i godinu {request.Year} u statusu čekanja na odobrenje.");

            return updatedCount;
        }

        public async Task<SalarySlipResponse> MarkSingleSalaryAsApproved(SalarySlipApproveSingleRequest request)
        {
            var validationErrors = await _salarySlipApproveSingleValidator.ValidateAsync(request);
            if (!validationErrors.IsValid)
                throw new ValidationException(validationErrors.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));

            var existingSalary = await _dbContext.Set<SalarySlip>()
                .Where(ss => ss.Month == request.Month
                          && ss.Year == request.Year
                          && ss.EmployeeId == request.EmployeeId)
                .FirstOrDefaultAsync();

            if (existingSalary == null)
            {
                var employeeFullName = await _dbContext.Set<Employee>()
                    .Where(e => e.Id == request.EmployeeId)
                    .Select(e => e.User.FirstName + " " + e.User.LastName)
                    .FirstOrDefaultAsync();

                throw new NotFoundException(
                    $"Ne postoji plata za uposlenika {employeeFullName}, mjesec {SalarySlipCalculation.GetMonthName(request.Month)} i godinu {request.Year}.");
            }

            BaseSalarySlipState state = _salarySlipState.GetSalarySlipState(existingSalary.State);
            var result = await state.MarkSingleSalaryAsApproved(request);
            return result;
        }

        public async Task<int> MarkAllSalariesAsPaid(SalarySlipPayAllRequest request)
        {
            var validationErrors = await _salarySlipPayAllValidator.ValidateAsync(request);
            if (!validationErrors.IsValid)
                throw new ValidationException(validationErrors.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));

            var approvedStateName = nameof(ApprovedSalarySlipState);
            var paidStateName = nameof(PaidSalarySlipState);
            var currentUserId = _userAccessor.GetUserId();
            var now = DateTime.UtcNow;

            var approvedTotal = await _dbContext.Set<SalarySlip>()
                .CountAsync(ss => ss.Month == request.Month
                               && ss.Year == request.Year
                               && ss.State == approvedStateName);

            if (approvedTotal == 0)
                throw new NotFoundException(
                    $"Ne postoje plate za mjesec {SalarySlipCalculation.GetMonthName(request.Month)} i godinu {request.Year} u statusu čekanja na plaćanje.");

            // Separation of duties (four-eyes): the payer must not have approved any of these slips.
            // Only enforced for an authenticated user (the seeder pays as the system with no user id).
            if (currentUserId != null)
            {
                var selfApproved = await _dbContext.Set<SalarySlip>()
                    .AnyAsync(ss => ss.Month == request.Month
                                 && ss.Year == request.Year
                                 && ss.State == approvedStateName
                                 && ss.MarkedAsApprovedByAdminId == currentUserId);
                if (selfApproved)
                    throw new BusinessException(
                        "Ne možete isplatiti plate koje ste sami odobrili. Isplatu mora izvršiti druga osoba (princip četvoro očiju).");
            }

            var updatedCount = await _dbContext.Set<SalarySlip>()
                .Where(ss => ss.Month == request.Month
                          && ss.Year == request.Year
                          && ss.State == approvedStateName)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(s => s.State, paidStateName)
                    .SetProperty(s => s.PaidAt, now)
                    .SetProperty(s => s.MarkedAsPaidByAdminId, currentUserId));

            return updatedCount;
        }

        public async Task<SalarySlipResponse> MarkSingleSalaryAsPaid(SalarySlipPaySingleRequest request)
        {
            var validationErrors = await _salarySlipPaySingleValidator.ValidateAsync(request);
            if (!validationErrors.IsValid)
                throw new ValidationException(validationErrors.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));


            var pendingSalary = await _dbContext.Set<SalarySlip>()
                .Where(ss => ss.Month == request.Month
                          && ss.Year == request.Year
                          && ss.EmployeeId == request.EmployeeId)
                .FirstOrDefaultAsync();

            if (pendingSalary == null)
            {
                var employeeFullName = await _dbContext.Set<Employee>()
                    .Where(e => e.Id == request.EmployeeId)
                    .Select(e => e.User.FirstName + " " + e.User.LastName)
                    .FirstOrDefaultAsync();

                throw new NotFoundException(
                    $"Ne postoji plata za uposlenika {employeeFullName}, mjesec {SalarySlipCalculation.GetMonthName(request.Month)} i godinu {request.Year}");
            }

            BaseSalarySlipState state = _salarySlipState.GetSalarySlipState(pendingSalary.State);
            var result = await state.MarkSingleSalaryAsPaid(request);
            return result;
        }

        public async Task<int> RecalculateAllSalaries(SalarySlipAllRecalculationRequest request)
        {
            var validationErrors = await _salarySlipAllRecalcValidator.ValidateAsync(request);
            if (!validationErrors.IsValid)
                throw new ValidationException(validationErrors.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));

            // 1) Find ALL existing non-paid slips for given month & year
            var paidStateNameAll = nameof(PaidSalarySlipState);
            var existingSlips = await _dbContext.Set<SalarySlip>()
                .Where(ss => ss.Year == request.Year
                          && ss.Month == request.Month
                          && ss.State != paidStateNameAll)
                .ToListAsync();

            if (!existingSlips.Any())
                throw new NotFoundException(
                    $"Nisu pronađene obračunate i neplaćene plate za mjesec {SalarySlipCalculation.GetMonthName(request.Month)} i godinu {request.Year}.");

            // 2) Remove old slips — Items cascade automatically via FK constraint
            _dbContext.Set<SalarySlip>().RemoveRange(existingSlips);
            await _dbContext.SaveChangesAsync();

            // 3) Regenerate entire period via Initial state — direct dispatch avoids double validation
            var calculation = new SalarySlipCalculationRequest
            {
                Month = request.Month,
                Year = request.Year
            };

            var initial = _salarySlipState.GetSalarySlipState(nameof(InitialSalarySlipState));
            return await initial.GenerateSalarySlipsForPeriod(calculation);
        }

        public async Task<SalarySlipResponse> RecalculateSingleSalary(SalarySlipSingleRecalculationRequest request)
        {
            var validationErrors = await _salarySlipSingleRecalcValidator.ValidateAsync(request);
            if (!validationErrors.IsValid)
                throw new ValidationException(validationErrors.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));

            // 1) Find existing non-paid slip for this employee & period
            //    Items are not needed here — cascade delete handles them when the state removes the slip.
            var existingSlip = await _dbContext.Set<SalarySlip>()
                .Where(ss => ss.EmployeeId == request.EmployeeId
                          && ss.Year == request.Year
                          && ss.Month == request.Month)
                .FirstOrDefaultAsync();

            if (existingSlip == null)
            {
                var employeeFullName = await _dbContext.Set<Employee>()
                    .Where(e => e.Id == request.EmployeeId)
                    .Select(e => e.User.FirstName + " " + e.User.LastName)
                    .FirstOrDefaultAsync();

                if (string.IsNullOrWhiteSpace(employeeFullName))
                    throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Employee), request.EmployeeId));

                throw new NotFoundException(
                    $"Ne postoji podatak o plati za uposlenika {employeeFullName}, mjesec {SalarySlipCalculation.GetMonthName(request.Month)} i godinu {request.Year}.");
            }

            BaseSalarySlipState state = _salarySlipState.GetSalarySlipState(existingSlip.State);
            var result = await state.RecalculateSingleSalary(request);
            return result;
        }

        public async Task<int> InsertOrRecalculateSalaries(SalarySlipCalculationRequest request)
        {
            var validationErrors = await _salarySlipCalculationValidator.ValidateAsync(request);
            if (!validationErrors.IsValid)
                throw new ValidationException(validationErrors.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));

            // Payroll can only be run once the period has fully ended (from the 1st of the
            // next month) — the current month's data (attendance/overtime/leave) isn't final yet.
            var now = DateTime.UtcNow;
            var isPastMonth = request.Year < now.Year
                || (request.Year == now.Year && request.Month < now.Month);
            if (!isPastMonth)
                throw new BusinessException("Obračun se može pokrenuti tek nakon što mjesec završi.");

            // A period-wide payroll run may only happen once; block re-running once slips exist.
            if (request.EmployeeId == null)
            {
                var alreadyRun = await _dbContext.Set<SalarySlip>()
                    .AnyAsync(ss => ss.Year == request.Year && ss.Month == request.Month);
                if (alreadyRun)
                    throw new BusinessException("Obračun za odabrani period je već pokrenut.");
            }

            BaseSalarySlipState state = _salarySlipState.GetSalarySlipState(nameof(InitialSalarySlipState));
            var result = await state.GenerateSalarySlipsForPeriod(request);
            return result;
        }

        private static string MapStatusToStateName(SalarySlipStatus status) => status switch
        {
            SalarySlipStatus.Pending => nameof(PendingSalarySlipState),
            SalarySlipStatus.Approved => nameof(ApprovedSalarySlipState),
            SalarySlipStatus.Paid => nameof(PaidSalarySlipState),
            _ => throw new BusinessException("Nevažeći status platne liste.")
        };

        // Finance overview for the accounting dashboard, over the most recent fully PAID month.
        public async Task<PayrollDashboardResponse> GetPayrollDashboardAsync()
        {
            var paidState = MapStatusToStateName(SalarySlipStatus.Paid);

            var latest = await _dbContext.Set<SalarySlip>()
                .Where(ss => ss.State == paidState)
                .OrderByDescending(ss => ss.Year).ThenByDescending(ss => ss.Month)
                .Select(ss => new { ss.Year, ss.Month })
                .FirstOrDefaultAsync();

            if (latest == null)
                return new PayrollDashboardResponse { HasData = false };

            var slips = await _dbContext.Set<SalarySlip>()
                .Where(ss => ss.State == paidState && ss.Year == latest.Year && ss.Month == latest.Month)
                .Include(ss => ss.Employee).ThenInclude(e => e.User)
                .Include(ss => ss.Items)
                .ToListAsync();

            decimal Overtime(SalarySlip s) =>
                s.Items.Where(i => i.ItemType == SalarySlipItemType.Overtime).Sum(i => i.Amount);
            decimal OvertimeHrs(SalarySlip s) =>
                s.Items.Where(i => i.ItemType == SalarySlipItemType.Overtime).Sum(i => i.Quantity ?? 0m);

            var response = new PayrollDashboardResponse
            {
                HasData = true,
                Year = latest.Year,
                Month = latest.Month,
                SlipCount = slips.Count,
                TotalGross = slips.Sum(s => s.AdjustedBruto),
                TotalNet = slips.Sum(s => s.NetSalary),
                TotalContributions = slips.Sum(s => s.TotalContributions),
                TotalTax = slips.Sum(s => s.Tax),
                TotalOvertime = slips.Sum(Overtime),
                TotalOvertimeHours = slips.Sum(OvertimeHrs),
                EmployeesWithOvertime = slips.Count(s => Overtime(s) > 0),
            };
            response.AverageNet = slips.Count > 0 ? Math.Round(response.TotalNet / slips.Count, 2) : 0m;
            response.BurdenRate = response.TotalGross > 0
                ? Math.Round((response.TotalContributions + response.TotalTax) / response.TotalGross * 100m, 1)
                : 0m;

            response.TopOvertime = slips
                .Select(s => new PayrollDashboardResponse.OvertimeLeaderItem
                {
                    FullName = $"{s.Employee.User.FirstName} {s.Employee.User.LastName}",
                    Hours = OvertimeHrs(s),
                    Amount = Overtime(s),
                })
                .Where(x => x.Amount > 0)
                .OrderByDescending(x => x.Amount)
                .Take(5)
                .ToList();

            return response;
        }

        public async Task<(byte[]Bytes, string FileName)> GetSlipPdfAsync(int id)
        {
            var slip = await GetByIdAsync(id);
            if (slip.Status != SalarySlipStatus.Paid)
                throw new BusinessException("PDF je dostupan samo za platne liste koje su plaćene.");
            var name =
                    $"{slip.Employee.User.FirstName}-{slip.Employee.User.LastName}".Replace(" ", "-");
            var fileName = $"platna-lista-{name}-{slip.Year}-{slip.Month:D2}.pdf";

            return (SalarySlipPdf.SingleSlip(slip), fileName);
        }

        public async Task<byte[]> GetMonthlyReportPdfAsync(int year, int month, int? employeeId = null)
        {
            if (month < 1 || month > 12)
                throw new BusinessException("Mjesec mora biti u rasponu od januara do decembra.");

            // Items are needed here (unlike the list view) so the report can show the overtime amount.
            IQueryable<SalarySlip> query = IncludeRelatedEntities(null, _dbContext.Set<SalarySlip>())
                .Include(ss => ss.Items);
            query = ApplyFilters(query, new SalarySlipCalculationSearchObject
            {
                Year = year,
                Month = month,
                EmployeeId = employeeId,
                Status = SalarySlipStatus.Paid
            });

            var slips = await query.ToListAsync();
            var responses = slips.Select(s => _mapper.Map<SalarySlipResponse>(s)).ToList();

            return SalarySlipPdf.MonthlyReport(year, month, responses);
        }
    }
}
