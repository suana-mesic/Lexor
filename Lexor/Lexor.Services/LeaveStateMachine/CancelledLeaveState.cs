using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services.LeaveStateMachine
{
    public class CancelledLeaveState : BaseLeaveState
    {
        public CancelledLeaveState(LexorDbContext dbContext, IValidator<LeaveInsertRequest> insertValidator, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider, IValidator<LeaveUpdateRequest> updateValidator) : base(dbContext, insertValidator, mapper, userAccessor, serviceProvider, updateValidator)
        {

        }
        public async override Task DeleteAsync(int id)
        {
            var entity = await GetByIdAsync(id);
            _dbContext.Leaves.Remove(entity);
            await _dbContext.SaveChangesAsync();
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(DeleteAsync) };
        }
    }
}
