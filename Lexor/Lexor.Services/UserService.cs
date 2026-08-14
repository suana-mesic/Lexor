using FluentValidation;
using Lexor.Model.Constants;
using Lexor.Model.Enums;
using Lexor.Model.Exceptions;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services
{
    public class UserService : BaseReadService<User, UserResponse, UserSearchObject>, IUserService
    {
        private readonly IAuthenticatedUserAccessor _userAccessor;

        public UserService(LexorDbContext dbContext, IMapper mapper,
                           IAuthenticatedUserAccessor userAccessor)
            : base(dbContext, mapper)
        {
            _userAccessor = userAccessor;
        }

        protected override IQueryable<User> IncludeRelatedEntities(UserSearchObject? search, IQueryable<User> query)
            => query.Include(u => u.UserRoles).ThenInclude(ur => ur.Role);

        protected override IQueryable<User> ApplyFilters(IQueryable<User> query, UserSearchObject? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    var term = search.Name.ToLower();
                    query = query.Where(u =>
                        (u.FirstName + " " + u.LastName).ToLower().Contains(term)
                        || u.Email.ToLower().Contains(term)
                        || u.Username.ToLower().Contains(term));
                }

                if (!string.IsNullOrWhiteSpace(search.RoleName))
                    query = query.Where(u => u.UserRoles.Any(ur => ur.Role.Name == search.RoleName));

                query = search.ActivityStatus switch
                {
                    ActivityStatus.Active => query.Where(u => u.IsActive),
                    ActivityStatus.Inactive => query.Where(u => !u.IsActive),
                    ActivityStatus.All => query,
                    null => query,
                    _ => throw new ValidationException("Nevažeći filter statusa aktivnosti.")
                };
            }
            return query;
        }

        // Replaces the user's single role. Guards against an admin changing their own role
        // (which could lock them out of the admin panel mid-session).
        public async Task<UserResponse> ChangeRoleAsync(int userId, ChangeUserRoleRequest request)
        {
            GuardNotSelf(userId, "Ne možete mijenjati ulogu vlastitom nalogu.");

            var user = await _dbContext.Set<User>()
                .Include(u => u.UserRoles)
                .FirstOrDefaultAsync(u => u.Id == userId)
                ?? throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(User), userId));

            var roleExists = await _dbContext.Set<Role>().AnyAsync(r => r.Id == request.RoleId);
            if (!roleExists)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Role), request.RoleId));

            _dbContext.Set<UserRole>().RemoveRange(user.UserRoles);
            user.UserRoles.Add(new UserRole
            {
                UserId = user.Id,
                RoleId = request.RoleId,
                DateAssigned = DateTime.UtcNow
            });

            await _dbContext.SaveChangesAsync();
            return await GetByIdAsync(userId);
        }

        public async Task<UserResponse> SetActiveAsync(int userId, bool isActive)
        {
            if (!isActive)
                GuardNotSelf(userId, "Ne možete deaktivirati vlastiti nalog.");

            var user = await _dbContext.Set<User>().FirstOrDefaultAsync(u => u.Id == userId)
                ?? throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(User), userId));

            user.IsActive = isActive;
            await _dbContext.SaveChangesAsync();
            return await GetByIdAsync(userId);
        }

        public async Task<AdminStatsResponse> GetStatsAsync()
        {
            var total = await _dbContext.Set<User>().CountAsync();
            var active = await _dbContext.Set<User>().CountAsync(u => u.IsActive);
            var notActivated = await _dbContext.Set<User>().CountAsync(u => !u.IsCodeActivated);

            // Count per role via a subquery so roles with zero users are still listed.
            var perRole = await _dbContext.Set<Role>()
                .OrderBy(r => r.Id)
                .Select(r => new RoleUserCount
                {
                    RoleName = r.Name,
                    Count = _dbContext.Set<UserRole>().Count(ur => ur.RoleId == r.Id)
                })
                .ToListAsync();

            var today = DateTime.UtcNow.Date;
            var soon = today.AddDays(30);

            return new AdminStatsResponse
            {
                TotalUsers = total,
                ActiveUsers = active,
                InactiveUsers = total - active,
                NotActivatedUsers = notActivated,
                UsersPerRole = perRole,

                Departments = await _dbContext.Set<Department>().CountAsync(),
                Positions = await _dbContext.Set<Position>().CountAsync(),
                Cities = await _dbContext.Set<City>().CountAsync(),
                ContractTypes = await _dbContext.Set<ContractType>().CountAsync(),
                LeaveTypes = await _dbContext.Set<LeaveType>().CountAsync(),

                LegalDocuments = await _dbContext.Set<LegalDocument>().CountAsync(),
                ActiveRfidCards = await _dbContext.Set<RfidCard>().CountAsync(c => c.IsActive),

                ActiveContracts = await _dbContext.Set<Contract>()
                    .CountAsync(c => c.StartDate <= today && (c.EndDate == null || c.EndDate >= today)),
                ExpiredContracts = await _dbContext.Set<Contract>()
                    .CountAsync(c => c.EndDate != null && c.EndDate < today),
                ExpiringSoonContracts = await _dbContext.Set<Contract>()
                    .CountAsync(c => c.EndDate != null && c.EndDate >= today && c.EndDate <= soon),
            };
        }

        private void GuardNotSelf(int userId, string message)
        {
            if (_userAccessor.GetUserId() == userId)
                throw new BusinessException(message);
        }
    }
}
