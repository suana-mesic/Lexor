using Lexor.Model.Exceptions;
using Lexor.Model.Responses;
using Lexor.Services.Database;
using MapsterMapper;
using Lexor.Model.Constants;

namespace Lexor.Services.StateMachine.LeaveStateMachine
{
    public class ApprovedLeaveState : BaseLeaveState
    {
        public ApprovedLeaveState(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider) : base(dbContext, mapper, userAccessor, serviceProvider)
        {

        }

        public async override Task<LeaveResponse> CancelAsync(int id, string? reason)
        {
            var entity = await GetByIdAsync(id);
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var isAdmin = _userAccessor.IsInRole(RoleNames.Administrator);

            if(isAdmin && entity.Employee.UserId == _userAccessor.GetUserId())
                throw new BusinessException("Administrator ne može sam sebi poništiti odsustvo.");
            // Once the leave has started, only an administrator can cancel it (override).
            if (entity.DateFrom <= today && !isAdmin)
                throw new BusinessException(
                    "Rok za otkazivanje je prošao jer je odsustvo počelo. Obratite se administratoru.");

            entity.CancellationReason = reason;
            entity.CancelledAt = DateTime.UtcNow;
            entity.CancelledByUserId = _userAccessor.GetUserId();
            entity.State = nameof(CancelledLeaveState);
            await _dbContext.SaveChangesAsync();
            if (entity.Employee.User.Id != _userAccessor.GetUserId())
                await PublishLeaveStatusAsync(entity, reason);
            return _mapper.Map<LeaveResponse>(await GetByIdAsync(entity.Id));
        }

        public async override Task<LeaveResponse> CompleteAsync(int id)
        {
            var entity = await GetByIdAsync(id);
            entity.State = nameof(CompletedLeaveState);
            entity.CompletedAt = DateTime.UtcNow;
            await _dbContext.SaveChangesAsync();
            return _mapper.Map<LeaveResponse>(await GetByIdAsync(entity.Id));
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(CancelAsync) };
        }
    }
}
