using FluentValidation;
using Lexor.Model.Enums;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
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
                    _ => throw new ValidationException("Nevažeći filter statusa aktivnosti.")
                };
            }
            return query;
        }

        // Enriches each role with how many users currently hold it (for the admin "Uloge" view).
        public override async Task<PageResult<RoleResponse>> GetAllAsync(RoleSearchObject? search = null)
        {
            var result = await base.GetAllAsync(search);

            var counts = await _dbContext.Set<UserRole>()
                .GroupBy(ur => ur.RoleId)
                .Select(g => new { RoleId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.RoleId, x => x.Count);

            foreach (var role in result.Items)
                role.UserCount = counts.TryGetValue(role.Id, out var c) ? c : 0;

            return result;
        }
    }
}
