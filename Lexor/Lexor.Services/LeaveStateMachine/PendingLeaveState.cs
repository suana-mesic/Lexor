using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services.LeaveStateMachine
{
    public class PendingLeaveState : BaseLeaveState
    {
        public PendingLeaveState(LexorDbContext dbContext, IValidator<LeaveInsertRequest> insertValidator, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider, IValidator<LeaveUpdateRequest> updateValidator) : base(dbContext, insertValidator, mapper, userAccessor, serviceProvider, updateValidator)
        {

        }
        public async override Task<LeaveResponse> UpdateAsync(int id, LeaveUpdateRequest request)
        {
            var entity = await GetByIdAsync(id);

            _mapper.Map(request, entity);

            // keep NumberOfDays consistent if dates changed
            entity.NumberOfDays = (entity.DateTo.DayNumber - entity.DateFrom.DayNumber) + 1;

            await _dbContext.SaveChangesAsync();
            return _mapper.Map<LeaveResponse>(await GetByIdAsync(entity.Id));
        }
        public async override Task<LeaveResponse> ApproveAsync(int id)
        {
            var entity = await GetByIdAsync(id);
            entity.ApprovedAt = DateTime.UtcNow;
            entity.ApprovedByAdminId = _userAccessor.GetUserId();
            entity.State = nameof(ApprovedLeaveState);
            await _dbContext.SaveChangesAsync();
            return _mapper.Map<LeaveResponse>(await GetByIdAsync(entity.Id));
        }

        public async override Task<LeaveResponse> RejectAsync(int id, string reason)
        {
            var entity = await GetByIdAsync(id);
            entity.RejectionReason = reason;
            entity.RejectedAt = DateTime.UtcNow;
            entity.RejectedByAdminId = _userAccessor.GetUserId();
            entity.State = nameof(RejectedLeaveState);
            await _dbContext.SaveChangesAsync();
            return _mapper.Map<LeaveResponse>(await GetByIdAsync(entity.Id));
        }

        public async override Task<LeaveResponse> CancelAsync(int id)
        {
            var entity = await GetByIdAsync(id);
            entity.State = nameof(CancelledLeaveState);
            await _dbContext.SaveChangesAsync();
            return _mapper.Map<LeaveResponse>(await GetByIdAsync(entity.Id));
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(ApproveAsync), nameof(RejectAsync), nameof(CancelAsync), nameof(UpdateAsync) };
        }
    }
}
