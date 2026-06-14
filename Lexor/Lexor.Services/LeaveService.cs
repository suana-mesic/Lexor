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

            if (_userAccessor.IsInRole(RoleNames.Administrator))
            {
                // admin may optionally filter by any employee
                if (search?.EmployeeId.HasValue == true)
                    query = query.Where(l => l.EmployeeId == search.EmployeeId);
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

            if (!_userAccessor.IsInRole(RoleNames.Administrator))
            {
                var currentUserId = _userAccessor.GetUserId();
                if (response.Employee?.User?.Id != currentUserId)
                    throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));
                response.Employee = null;    // For employees the property "Employee" in LeaveResponse object stays null
            }
            return response;
        }

        public async override Task<PageResult<LeaveResponse>> GetAllAsync(LeaveSearchObject? search = null)
        {
            var response = await base.GetAllAsync(search);
            if (response != null && response.Items.Count > 0)
            {
                foreach (var item in response.Items)
                {
                    if (!_userAccessor.IsInRole(RoleNames.Administrator))
                        item.Employee = null;  // For employees the property "Employee" in LeaveResponse object stays null
                    item.AllowedActions = await GetAllowedActions(item.Id);
                }
            }
            return response;
        }
        public async Task EmployeeIsPermitted(int id)
        {
            var currentUserId = _userAccessor.GetUserId();
            if (!_userAccessor.IsInRole(RoleNames.Administrator))
            {
                // verify the leave record belongs to the employee
                var ownerUserId = await _dbContext.Set<Leave>()
                    .Where(l => l.Id == id)
                    .Select(l => (int?)l.Employee.UserId)
                    .FirstOrDefaultAsync();

                // employee is trying to access leaveID that is not his
                if (currentUserId != ownerUserId)
                    throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));
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
                throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));

            BaseLeaveState state = _baseLeaveState.GetLeaveState(entity.State);
            var result = await state.UpdateAsync(id, request);
            result.Employee = null;
            return result;
        }

        public override Task DeleteAsync(int id)
        {
            throw new InvalidOperationException("Brisanje odsustva nije podržano. Otkazani zahtjevi ostaju u sistemu radi historije.");
        }

        public async Task<LeaveResponse> ApproveAsync(int id)
        {
            var entity = await _dbContext.Set<Leave>().FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));
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
                throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));
            BaseLeaveState state = _baseLeaveState.GetLeaveState(entity.State);
            return await state.RejectAsync(id, request.RejectionReason);
        }

        public async Task<LeaveResponse> CancelAsync(int id)
        {
            await EmployeeIsPermitted(id);

            var entity = await _dbContext.Set<Leave>().FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));
            BaseLeaveState state = _baseLeaveState.GetLeaveState(entity.State);
            var result = await state.CancelAsync(id);
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
                throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));
            BaseLeaveState currentState = _baseLeaveState.GetLeaveState(entity.State);
            return currentState.GetAllowedActions();
        }

    }
}
