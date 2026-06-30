using EasyNetQ;
using Lexor.Model;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace Lexor.Services.StateMachine.LeaveStateMachine
{
    public class BaseLeaveState
    {
        protected readonly LexorDbContext _dbContext;
        protected readonly IMapper _mapper;
        protected readonly IAuthenticatedUserAccessor _userAccessor;
        protected readonly IServiceProvider _serviceProvider;

        public BaseLeaveState(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _userAccessor = userAccessor;
            _serviceProvider = serviceProvider;
        }

        public virtual Task<LeaveResponse> InsertAsync(LeaveInsertRequest request, int employeeId)
        {
            throw new InvalidOperationException("Nije moguće dodati novo odsustvo u trenutnom stanju.");
        }
        public virtual Task<LeaveResponse> UpdateAsync(int id, LeaveUpdateRequest request)
        {
            throw new InvalidOperationException("Nije moguće ažurirati odsustvo u trenutnom stanju.");
        }
        public virtual Task<LeaveResponse> ApproveAsync(int id)
        {
            throw new InvalidOperationException("Nije moguće odobriti odsustvo u trenutnom stanju.");
        }
        public virtual Task<LeaveResponse> RejectAsync(int id, string reason)
        {
            throw new InvalidOperationException("Nije moguće odbiti odsustvo u trenutnom stanju.");
        }
        public virtual Task<LeaveResponse> CancelAsync(int id)
        {
            throw new InvalidOperationException("Nije moguće poništiti odsustvo u trenutnom stanju.");
        }
        public virtual Task DeleteAsync(int id)
        {
            throw new InvalidOperationException("Nije moguće izbrisati odsustvo u trenutnom stanju.");
        }

        public virtual Task<LeaveResponse> CompleteAsync(int id)
        {
            throw new InvalidOperationException("Nije moguće završiti odsustvo u trenutnom stanju.");
        }
        public IQueryable<Leave> IncludeRelatedEntities(LeaveSearchObject? search, IQueryable<Leave> query)
        {
            query = query
                .Include(l => l.LeaveType)
                .Include(l => l.Employee)
                .ThenInclude(e => e.User);
            return query;
        }
        public async Task<Leave> GetByIdAsync(int id)
        {
            IQueryable<Leave> query = _dbContext.Set<Leave>();
            query = IncludeRelatedEntities(null, query);
            var entity = await query.FirstOrDefaultAsync(e => EF.Property<int>(e, "Id") == id);

            if (entity == null)
                throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Leave), id));

            return entity;
        }
        public BaseLeaveState GetLeaveState(string stateName)
        {
            switch (stateName)
            {
                case nameof(InitialLeaveState):
                    return _serviceProvider.GetService<InitialLeaveState>()!;
                case nameof(PendingLeaveState):
                    return _serviceProvider.GetService<PendingLeaveState>()!;
                case nameof(ApprovedLeaveState):
                    return _serviceProvider.GetService<ApprovedLeaveState>()!;
                case nameof(RejectedLeaveState):
                    return _serviceProvider.GetService<RejectedLeaveState>()!;
                case nameof(CancelledLeaveState):
                    return _serviceProvider.GetService<CancelledLeaveState>()!;
                case nameof(CompletedLeaveState):
                    return _serviceProvider.GetService<CompletedLeaveState>()!;
                default:
                    throw new InvalidOperationException("Odsustvo je u nevažećem stanju.");
            }
        }

        public virtual List<string> GetAllowedActions()
        {
            var allowedActions = new List<string>();
            return allowedActions;
        }

        protected async Task PublishLeaveStatusAsync(Leave entity, string? rejectionReason)
        {
            try
            {
                var bus = _serviceProvider.GetService<EasyNetQ.IBus>();
                if (bus == null) return;
                await bus.PubSub.PublishAsync(new LeaveStatusChanged
                {
                    LeaveId = entity.Id,
                    EmployeeId = entity.EmployeeId,
                    NewState = entity.State!,
                    RejectionReason = rejectionReason
                });
            }
            catch (Exception ex)
            {
                _serviceProvider.GetService<Microsoft.Extensions.Logging.ILogger<BaseLeaveState>>()?
                    .LogError(ex, "Greška pri objavi LeaveStatusChanged poruke.");
            }
        }
    }
}
