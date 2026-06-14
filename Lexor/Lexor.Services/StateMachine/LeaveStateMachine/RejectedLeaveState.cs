using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services.StateMachine.LeaveStateMachine
{
    public class RejectedLeaveState : BaseLeaveState
    {
        public RejectedLeaveState(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider) : base(dbContext, mapper, userAccessor, serviceProvider)
        {
            
        }
    }
}
