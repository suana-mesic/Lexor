using Lexor.Model.Responses;
using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services.StateMachine.LeaveStateMachine
{
    public class ApprovedLeaveState : BaseLeaveState
    {
        public ApprovedLeaveState(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider) : base(dbContext, mapper, userAccessor, serviceProvider)
        {

        }

        public async override Task<LeaveResponse> CancelAsync(int id)
        {
            var entity = await GetByIdAsync(id);
            entity.CancelledAt = DateTime.UtcNow;
            entity.CancelledByUserId = _userAccessor.GetUserId();
            entity.State = nameof(CancelledLeaveState);
            await _dbContext.SaveChangesAsync();
            return _mapper.Map<LeaveResponse>(await GetByIdAsync(entity.Id));
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(CancelAsync) };
        }
    }
}
