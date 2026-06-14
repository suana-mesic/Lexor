using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services.StateMachine.LeaveStateMachine
{
    public class InitialLeaveState : BaseLeaveState
    {
        public InitialLeaveState(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider) : base(dbContext, mapper, userAccessor, serviceProvider)
        {

        }
        public override async Task<LeaveResponse> InsertAsync(LeaveInsertRequest request, int employeeId)
        {
            var hasOverlap = await _dbContext.Set<Leave>()
                .AnyAsync(l => l.EmployeeId == employeeId
                            && l.State != nameof(RejectedLeaveState)
                            && l.State != nameof(CancelledLeaveState)
                            && l.DateFrom <= request.DateTo
                            && l.DateTo >= request.DateFrom);

            if (hasOverlap)
                throw new InvalidOperationException("Već postoji aktivno odsustvo koje se preklapa sa navedenim periodom.");

            var entity = _mapper.Map<Leave>(request);
            entity.EmployeeId = employeeId;
            entity.NumberOfDays = request.DateTo.DayNumber - request.DateFrom.DayNumber + 1;

            _dbContext.Set<Leave>().Add(entity);
            entity.State = nameof(PendingLeaveState); //InsertAsync() -> new state = Pending
            await _dbContext.SaveChangesAsync();

            var loaded = await GetByIdAsync(entity.Id);
            return _mapper.Map<LeaveResponse>(loaded);
        }
        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(InsertAsync) };
        }
    }
}
