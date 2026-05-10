using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services
{
    public class LeaveTypeService : BaseCRUDService<LeaveType, LeaveTypeResponse, LeaveTypeSearchObject, LeaveTypeInsertRequest, LeaveTypeUpdateRequest>, ILeaveTypeService
    {
        public LeaveTypeService(LexorDbContext dbContext, IMapper mapper, IValidator<LeaveTypeInsertRequest> insertValidator, IValidator<LeaveTypeUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor) : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {

        }
        protected override IQueryable<LeaveType> ApplyFilters(IQueryable<LeaveType> query, LeaveTypeSearchObject? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(c => c.Name.ToLower().Contains(search.Name.ToLower()));
                }

                if (search.OnlyPaid.HasValue)
                {
                    query = query.Where(c => c.IsPaid == search.OnlyPaid.Value);
                }
            }
            return query;
        }
    }
}
