using Lexor.Model.Exceptions;
using FluentValidation;
using FluentValidation.Results;
using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using Lexor.Services.StateMachine.LeaveStateMachine;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services
{
    public class LeaveService : BaseCRUDService<Leave, LeaveResponse, LeaveSearchObject, LeaveInsertRequest, LeaveUpdateRequest>, ILeaveService
    {
        private readonly BaseLeaveState _baseLeaveState;
        private readonly IValidator<LeaveRejectRequest> _leaveRejectionValidator;

        public LeaveService(LexorDbContext dbContext, IMapper mapper, IValidator<LeaveInsertRequest> insertValidator, IValidator<LeaveUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor, BaseLeaveState baseLeaveState, IValidator<LeaveRejectRequest> leaveRejectionValidator) : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {
            _baseLeaveState = baseLeaveState;
            _leaveRejectionValidator = leaveRejectionValidator;
        }

        protected override IQueryable<Leave> ApplyFilters(IQueryable<Leave> query, LeaveSearchObject? search)
        {
            if (search?.LeaveTypeId.HasValue == true)
            {
                query = query.Where(l => l.LeaveTypeId == search.LeaveTypeId);
            }

            if (!string.IsNullOrEmpty(search?.State))
            {
                query = query.Where(l => l.State == search.State);
            }

            if (_userAccessor.IsBackOffice())
            {
                // admin may optionally filter by any employee
                if (search?.EmployeeId.HasValue == true)
                    query = query.Where(l => l.EmployeeId == search.EmployeeId);

                // admin may also search by employee full name
                if (!string.IsNullOrWhiteSpace(search?.EmployeeName))
                {
                    var term = search.EmployeeName.ToLower();
                    query = query.Where(l =>
                        (l.Employee.User.FirstName + " " + l.Employee.User.LastName)
                            .ToLower().Contains(term));
                }
            }
            else
            {
                // non-admin: server forces scope to own leaves regardless of what client sent
                var currentUserId = _userAccessor.GetUserId();
                query = query.Where(l => l.Employee.UserId == currentUserId);
            }

            return query;
        }

        public override async Task<LeaveResponse> GetByIdAsync(int id)
        {
            var response = await base.GetByIdAsync(id);

            response.AllowedActions = await GetAllowedActions(id);

            if (!_userAccessor.IsBackOffice())
            {
                var currentUserId = _userAccessor.GetUserId();
                if (response.Employee?.User?.Id != currentUserId)
                    throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));
                response.Employee = null;    // For employees the property "Employee" in LeaveResponse object stays null
            }
            return response;
        }

        public async override Task<PageResult<LeaveResponse>> GetAllAsync(LeaveSearchObject? search = null)
        {
            var response = await base.GetAllAsync(search);
            if (response != null && response.Items.Count > 0)
            {
                // The list query already loaded each row; derive allowed actions from the
                // item's State instead of re-querying the DB per row (avoids N+1).
                var isAdmin = _userAccessor.IsBackOffice();
                foreach (var item in response.Items)
                {
                    if (!isAdmin)
                        item.Employee = null;  // For employees the property "Employee" in LeaveResponse object stays null
                    item.AllowedActions = AllowedActionsForState(item.State, item.DateFrom);
                }
            }
            return response;
        }

        // Allowed actions depend on the current state plus a couple of date-based
        // business rules (no DB access needed — the row is already loaded).
        private List<string> AllowedActionsForState(string? state, DateOnly dateFrom)
        {
            if (string.IsNullOrEmpty(state)) return new List<string>();
            var actions = _baseLeaveState.GetLeaveState(state).GetAllowedActions();
            return ApplyDateRules(actions, state, dateFrom);
        }

        // Strips actions that are no longer valid given the leave's dates so the
        // UI doesn't offer them (§7: unavailable actions must not be offered).
        private static List<string> ApplyDateRules(List<string> actions, string? state, DateOnly dateFrom)
        {
            // An approved leave can only be cancelled while it hasn't started yet.
            if (state == nameof(ApprovedLeaveState)
                && dateFrom <= DateOnly.FromDateTime(DateTime.UtcNow))
            {
                actions = actions
                    .Where(a => a != nameof(BaseLeaveState.CancelAsync))
                    .ToList();
            }
            return actions;
        }
        // An employee may not request a new leave that overlaps one they already have PENDING or
        // APPROVED. Rejected or cancelled leaves do NOT block — that period can be requested again.
        private async Task EnsureNoActiveOverlapAsync(int employeeId, DateOnly from, DateOnly to, int? excludeId = null)
        {
            var pending = nameof(PendingLeaveState);
            var approved = nameof(ApprovedLeaveState);
            var clash = await _dbContext.Set<Leave>()
                .Where(l => l.EmployeeId == employeeId
                         && (l.State == pending || l.State == approved)
                         && (excludeId == null || l.Id != excludeId)
                         && l.DateFrom <= to && l.DateTo >= from)
                .Select(l => new { l.State, l.DateFrom, l.DateTo })
                .FirstOrDefaultAsync();

            if (clash != null)
            {
                var what = clash.State == approved ? "odobreno odsustvo" : "zahtjev za odsustvo na čekanju";
                throw new BusinessException(
                    $"Već imate {what} u periodu {clash.DateFrom:dd.MM.yyyy} – {clash.DateTo:dd.MM.yyyy}. " +
                    "Ne možete zatražiti novo odsustvo koje se preklapa s tim periodom.");
            }
        }

        public async Task EmployeeIsPermitted(int id)
        {
            var currentUserId = _userAccessor.GetUserId();
            if (!_userAccessor.IsBackOffice())
            {
                // verify the leave record belongs to the employee
                var ownerUserId = await _dbContext.Set<Leave>()
                    .Where(l => l.Id == id)
                    .Select(l => (int?)l.Employee.UserId)
                    .FirstOrDefaultAsync();

                // employee is trying to access leaveID that is not his
                if (currentUserId != ownerUserId)
                    throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));
            }
        }

        public override async Task<LeaveResponse> InsertAsync(LeaveInsertRequest request)
        {
            var validationResult = await _insertValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new ValidationException(validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));
            var currentUserId = _userAccessor.GetUserId();

            var employeeId = await _dbContext.Set<Employee>()
                .Where(e => e.UserId == currentUserId)
                .Select(e => (int?)e.Id)
                .FirstOrDefaultAsync()
                ?? throw new ValidationException("Trenutni korisnik nije povezan sa zaposlenikom.");

            await EnsureNoActiveOverlapAsync(employeeId, request.DateFrom, request.DateTo);

            BaseLeaveState state = _baseLeaveState.GetLeaveState(nameof(InitialLeaveState));
            var result = await state.InsertAsync(request, employeeId);
            result.Employee = null;
            return result;
        }

        public override async Task<LeaveResponse> UpdateAsync(int id, LeaveUpdateRequest request)
        {
            await EmployeeIsPermitted(id);

            var validationResult = await _updateValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new ValidationException(validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));


            var entity = await _dbContext.Set<Leave>().FindAsync(id);
            if (entity == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));

            await EnsureNoActiveOverlapAsync(
                entity.EmployeeId,
                request.DateFrom ?? entity.DateFrom,
                request.DateTo ?? entity.DateTo,
                excludeId: id);

            BaseLeaveState state = _baseLeaveState.GetLeaveState(entity.State);
            var result = await state.UpdateAsync(id, request);
            result.Employee = null;
            return result;
        }

        public override Task DeleteAsync(int id)
        {
            throw new BusinessException("Brisanje odsustva nije podržano. Otkazani zahtjevi ostaju u sistemu radi historije.");
        }

        // An admin who is also an employee must not decide on their OWN leave request.
        private async Task EnsureNotOwnRequest(Leave entity)
        {
            var currentUserId = _userAccessor.GetUserId();
            var ownEmployeeId = await _dbContext.Set<Employee>()
                .Where(e => e.UserId == currentUserId)
                .Select(e => (int?)e.Id)
                .FirstOrDefaultAsync();

            if (ownEmployeeId.HasValue && ownEmployeeId.Value == entity.EmployeeId)
                throw new BusinessException("Ne možete odlučivati o vlastitom zahtjevu za odsustvo.");
        }

        public async Task<LeaveResponse> ApproveAsync(int id)
        {
            var entity = await _dbContext.Set<Leave>().FindAsync(id);
            if (entity == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));

            await EnsureNotOwnRequest(entity);

            BaseLeaveState state = _baseLeaveState.GetLeaveState(entity.State);
            return await state.ApproveAsync(id);
        }

        public async Task<LeaveResponse> RejectAsync(int id, LeaveRejectRequest request)
        {
            var validationErrors = await _leaveRejectionValidator.ValidateAsync(request);
            if (!validationErrors.IsValid)
                throw new ValidationException(validationErrors.Errors.Select(e => _mapper.Map<ValidationFailure>(e)));

            var entity = await _dbContext.Set<Leave>().FindAsync(id);
            if (entity == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));

            await EnsureNotOwnRequest(entity);

            BaseLeaveState state = _baseLeaveState.GetLeaveState(entity.State);
            return await state.RejectAsync(id, request.RejectionReason);
        }

        public async Task<LeaveResponse> CancelAsync(int id, string? reason)
        {
            await EmployeeIsPermitted(id);

            var entity = await _dbContext.Set<Leave>().FindAsync(id);
            if (entity == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));
            BaseLeaveState state = _baseLeaveState.GetLeaveState(entity.State);
            var result = await state.CancelAsync(id, reason);
            result.Employee = null; // For employees the property "Employee" in LeaveResponse object stays null
            return result;
        }

        protected override IQueryable<Leave> IncludeRelatedEntities(LeaveSearchObject? search, IQueryable<Leave> query)
        {
            query = query
                    .Include(l => l.LeaveType)
                    .Include(l => l.Employee)
                    .ThenInclude(e => e.User);
            return query;
        }

        public async Task<List<string>> GetAllowedActions(int id)
        {
            await EmployeeIsPermitted(id);
            var entity = await _dbContext.Set<Leave>().FindAsync(id);
            if (entity == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));
            var actions = _baseLeaveState.GetLeaveState(entity.State).GetAllowedActions();
            return ApplyDateRules(actions, entity.State, entity.DateFrom);
        }

    }
}
