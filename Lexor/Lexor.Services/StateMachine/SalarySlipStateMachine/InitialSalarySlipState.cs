using Lexor.Model.Requests;
using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services.StateMachine.SalarySlipStateMachine
{
    public class InitialSalarySlipState : BaseSalarySlipState
    {
        public InitialSalarySlipState(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider)
            : base(dbContext, mapper, userAccessor, serviceProvider)
        {
        }

        public override Task<int> GenerateSalarySlipsForPeriod(SalarySlipCalculationRequest request)
            => GenerateSlipsCore(request);
        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(GenerateSalarySlipsForPeriod) };
        }
    }
}
