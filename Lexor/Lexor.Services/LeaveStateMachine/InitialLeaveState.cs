using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services.LeaveStateMachine
{
    public class InitialLeaveState : BaseLeaveState
    {
        public InitialLeaveState(LexorDbContext dbContext, IValidator<LeaveInsertRequest> insertValidator, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider, IValidator<LeaveUpdateRequest> updateValidator) : base(dbContext, insertValidator, mapper, userAccessor, serviceProvider, updateValidator)
        {

        }
        public override async Task<LeaveResponse> InsertAsync(LeaveInsertRequest request, int employeeId)
        {
            var entity = _mapper.Map<Leave>(request);
            entity.EmployeeId = employeeId;
            entity.NumberOfDays = (request.DateTo.DayNumber - request.DateFrom.DayNumber) + 1;

            _dbContext.Set<Leave>().Add(entity);
            entity.State = nameof(PendingLeaveState); //InsertAsync() -> new state = Pending
            await _dbContext.SaveChangesAsync();

            var loaded = await GetByIdAsync(entity.Id);
            return _mapper.Map<LeaveResponse>(loaded);
        }
        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(InsertAsync) };
        }
    }
}
