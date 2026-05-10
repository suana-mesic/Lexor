using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services.LeaveStateMachine
{
    public class ApprovedLeaveState : BaseLeaveState
    {
        public ApprovedLeaveState(LexorDbContext dbContext, IValidator<LeaveInsertRequest> insertValidator, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider, IValidator<LeaveUpdateRequest> updateValidator) : base(dbContext, insertValidator, mapper, userAccessor, serviceProvider, updateValidator)
        {
            
        }
    }
}
