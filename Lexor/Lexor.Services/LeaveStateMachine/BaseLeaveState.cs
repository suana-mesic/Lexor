using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Lexor.Services.LeaveStateMachine
{
    public class BaseLeaveState
    {
        protected readonly LexorDbContext _dbContext;
        protected readonly IValidator<LeaveInsertRequest> _insertValidator;
        protected readonly IValidator<LeaveUpdateRequest> _updateValidator;
        protected readonly IMapper _mapper;
        protected readonly IAuthenticatedUserAccessor _userAccessor;
        protected readonly IServiceProvider _serviceProvider;


        public BaseLeaveState(LexorDbContext dbContext, IValidator<LeaveInsertRequest> insertValidator, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider, IValidator<LeaveUpdateRequest> updateValidator)
        {
            _dbContext = dbContext;
            _insertValidator = insertValidator;
            _mapper = mapper;
            _userAccessor = userAccessor;
            _serviceProvider = serviceProvider;
            _updateValidator = updateValidator;
        }

        public virtual Task<LeaveResponse> InsertAsync(LeaveInsertRequest request, int employeeId)
        {
            throw new InvalidOperationException("Nije moguće dodati novo odsustvo u trenutnom stanju");
        }
        public virtual Task<LeaveResponse> UpdateAsync(int id, LeaveUpdateRequest request)
        {
            throw new InvalidOperationException("Nije moguće ažurirati odsustvo u trenutnom stanju");
        }
        public virtual Task<LeaveResponse> ApproveAsync(int id)
        {
            throw new InvalidOperationException("Nije moguće odobriti odsustvo u trenutnom stanju");
        }
        public virtual Task<LeaveResponse> RejectAsync(int id, string reason)
        {
            throw new InvalidOperationException("Nije moguće odbiti odsustvo u trenutnom stanju");
        }
        public virtual Task<LeaveResponse> CancelAsync(int id)
        {
            throw new InvalidOperationException("Nije moguće poništiti odsustvo u trenutnom stanju");
        }
        public virtual Task DeleteAsync(int id)
        {
            throw new InvalidOperationException("Nije moguće izbrisati odsustvo u trenutnom stanju");
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
                default:
                    throw new InvalidOperationException($"Stanje odsustva {stateName} je nepoznato.");
            }
        }

        public virtual List<string> GetAllowedActions()
        {
            var allowedActions = new List<string>();
            return allowedActions;
        }
    }
}
