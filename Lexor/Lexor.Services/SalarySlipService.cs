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
                throw new KeyNotFoundException(
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

                throw new KeyNotFoundException(
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

            var updatedCount = await _dbContext.Set<SalarySlip>()
                .Where(ss => ss.Month == request.Month
                          && ss.Year == request.Year
                          && ss.State == approvedStateName)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(s => s.State, paidStateName)
                    .SetProperty(s => s.PaidAt, now)
                    .SetProperty(s => s.MarkedAsPaidByAdminId, currentUserId));

            if (updatedCount == 0)
                throw new KeyNotFoundException(
                    $"Ne postoje plate za mjesec {SalarySlipCalculation.GetMonthName(request.Month)} i godinu {request.Year} u statusu čekanja na plaćanje.");

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

                throw new KeyNotFoundException(
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
                throw new KeyNotFoundException(
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
                    throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Employee), request.EmployeeId));

                throw new KeyNotFoundException(
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

            BaseSalarySlipState state = _salarySlipState.GetSalarySlipState(nameof(InitialSalarySlipState));
            var result = await state.GenerateSalarySlipsForPeriod(request);
            return result;
        }

        private static string MapStatusToStateName(SalarySlipStatus status) => status switch
        {
            SalarySlipStatus.Pending => nameof(PendingSalarySlipState),
            SalarySlipStatus.Paid => nameof(PaidSalarySlipState),
            _ => throw new InvalidOperationException("Nevažeći status platne liste.")
        };
    }
}
