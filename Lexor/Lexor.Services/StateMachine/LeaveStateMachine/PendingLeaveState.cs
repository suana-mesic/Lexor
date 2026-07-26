using Lexor.Model.Exceptions;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services.StateMachine.LeaveStateMachine
{
    public class PendingLeaveState : BaseLeaveState
    {
        public PendingLeaveState(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider) : base(dbContext, mapper, userAccessor, serviceProvider)
        {

        }
        public async override Task<LeaveResponse> UpdateAsync(int id, LeaveUpdateRequest request)
        {
            var entity = await GetByIdAsync(id);

            var hasOverlap = await _dbContext.Set<Leave>()
                .AnyAsync(l => l.Id != id
                            && l.EmployeeId == entity.EmployeeId
                            && l.State != nameof(RejectedLeaveState)
                            && l.State != nameof(CancelledLeaveState)
                            && l.DateFrom <= request.DateTo
                            && l.DateTo >= request.DateFrom);

            if (hasOverlap)
                throw new BusinessException("Već postoji aktivno odsustvo koje se preklapa sa navedenim periodom.");

            _mapper.Map(request, entity);

            // keep NumberOfDays consistent if dates changed
            entity.NumberOfDays = entity.DateTo.DayNumber - entity.DateFrom.DayNumber + 1;

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
            await PublishLeaveStatusAsync(entity, null);
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
            await PublishLeaveStatusAsync(entity, reason);
            return _mapper.Map<LeaveResponse>(await GetByIdAsync(entity.Id));
        }
        public async override Task<LeaveResponse> CancelAsync(int id, string? reason)
        {
            var entity = await GetByIdAsync(id);
            var today = DateOnly.FromDateTime(DateTime.UtcNow);

            if (entity.DateFrom <= today)
                throw new BusinessException("Nije moguće otkazati zahtjev koji je već počeo.");

            entity.CancellationReason = reason;
            entity.CancelledAt = DateTime.UtcNow;
            entity.CancelledByUserId = _userAccessor.GetUserId();
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
