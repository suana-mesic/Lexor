using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services.StateMachine.LeaveStateMachine
{
    public class CancelledLeaveState : BaseLeaveState
    {
        public CancelledLeaveState(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider) : base(dbContext, mapper, userAccessor, serviceProvider)
        {

        }

        public override List<string> GetAllowedActions()
        {
            return new List<string>();
        }
    }
}
