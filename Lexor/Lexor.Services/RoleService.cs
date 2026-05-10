using FluentValidation;
using Lexor.Model.Enums;
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

                query = search.ActivityStatus switch
                {
                    ActivityStatus.Active => query.Where(c => c.IsActive),
                    ActivityStatus.Inactive => query.Where(c => !c.IsActive),
                    ActivityStatus.All => query,
                    null => query,
                    _ => throw new ValidationException(
                        $"Nevažeća vrijednost ActivityStatus: {(int)search.ActivityStatus.Value}.")
                };
            }
            return query;
        }
    }
}
