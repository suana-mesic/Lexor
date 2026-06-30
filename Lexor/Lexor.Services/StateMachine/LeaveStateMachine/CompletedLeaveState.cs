using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services.StateMachine.LeaveStateMachine
{
    public class CompletedLeaveState:BaseLeaveState
    {
        public CompletedLeaveState(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider):base(dbContext, mapper, userAccessor, serviceProvider){}

        public override List<string> GetAllowedActions() => new();
    }
}
