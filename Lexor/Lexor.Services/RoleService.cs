using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;
namespace Lexor.Services
{
    public class RoleService : BaseCRUDService<Role, RoleResponse, RoleSearchObject, RoleInsertRequest, RoleUpdateRequest>, IRoleService
    {
        public RoleService(LexorDbContext dbContext, IMapper mapper, IValidator<RoleInsertRequest> insertValidator, IValidator<RoleUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor) : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {

        }
        protected override IQueryable<Role> ApplyFilters(IQueryable<Role> query, RoleSearchObject? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(c => c.Name.ToLower().Contains(search.Name.ToLower()));
                }
                if (search.OnlyActive.HasValue && search.OnlyActive == true)
                {
                    query = query.Where(c => c.IsActive);
                }
            }
            return query;
        }

        //protected override IQueryable<Role> IncludeRelatedEntities(RoleSearchObject search, IQueryable<Role> query)
        //{

        //}
    }
}
