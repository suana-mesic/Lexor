using Lexor.Services.Database;
using MapsterMapper;


namespace Lexor.Services.StateMachine.SalarySlipStateMachine
{
    public class PaidSalarySlipState : BaseSalarySlipState
    {
        public PaidSalarySlipState(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider) : base(dbContext, mapper, userAccessor, serviceProvider)
        {

        }
    }
}
