using Lexor.Model.Exceptions;
using FluentValidation;
using Lexor.Model.Enums;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using EasyNetQ;
using Lexor.Model;
using Microsoft.Extensions.Logging;
using Lexor.Model.Constants;

namespace Lexor.Services
{
    public class EmployeeService : BaseCRUDService<Employee, EmployeeResponse, EmployeeSearchObject, EmployeeInsertRequest, EmployeeUpdateRequest>, IEmployeeService
    {
        const string chars = "ABCDEFGHIJKLMNPQRSTUVWXYZ23456789"; // without similar (0/O, 1/I/L)

        private readonly IValidator<ProfileUpdateRequest> _profileValidator;
        private readonly IBus _bus;
        private readonly ILogger<EmployeeService> _logger;

        public EmployeeService(LexorDbContext dbContext, IMapper mapper, IValidator<EmployeeInsertRequest> insertValidator, IValidator<EmployeeUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor, IValidator<ProfileUpdateRequest> profileValidator, IBus bus, ILogger<EmployeeService> logger)
                 : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {
            _profileValidator = profileValidator;
            _bus = bus;
            _logger = logger;
        }

        public override async Task<PageResult<EmployeeResponse>> GetAllAsync(EmployeeSearchObject? search = null)
        {
            var result = await base.GetAllAsync(search);
            // List endpoints must not return large base64 payloads (guideline 8.2), but list
            // views must still show the entity's picture (guideline 6). So the full image is
            // dropped here and the small thumbnail travels instead; the details view loads
            // the full one.
            foreach (var e in result.Items)
                e.User.ProfileImageBase64 = null;
            return result;
        }

        protected override IQueryable<Employee> ApplyFilters(IQueryable<Employee> query, EmployeeSearchObject? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.FullName))
                {
                    var term = search.FullName.ToLower();
                    query = query.Where(e => (e.User.FirstName.ToLower() + " " + e.User.LastName.ToLower()).Contains(term));
                }
                if (search.DepartmentId.HasValue)
                {
                    query = query.Where(e => e.DepartmentId == search.DepartmentId);
                }

                query = search.ActivityStatus switch
                {
                    ActivityStatus.Active => query.Where(e => e.IsActive),
                    ActivityStatus.Inactive => query.Where(e => !e.IsActive),
                    ActivityStatus.All => query,
                    null => query,
                    _ => throw new ValidationException("Nevažeći filter statusa aktivnosti.")
                };
            }
            return query;
        }

        protected override IQueryable<Employee> IncludeRelatedEntities(EmployeeSearchObject? search, IQueryable<Employee> query)
        {
            return query
                .Include(e => e.User)
                .Include(e => e.City)
                    .ThenInclude(c => c.Country)
                .Include(e => e.Department)
                .Include(e => e.Position)
                .Include(e => e.Contracts)
                    .ThenInclude(c => c.ContractType);
        }

        public override async Task<EmployeeResponse> InsertAsync(EmployeeInsertRequest request)
        {
            var validationResult = await _insertValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
            {
                throw new ValidationException(validationResult.Errors);
            }

            await ValidatePositionMatchesDepartment(request.PositionId, request.DepartmentId);


            User user;
            Employee employee;
            await using var tx = await _dbContext.Database.BeginTransactionAsync();

            try
            {
                user = _mapper.Map<User>(request.User);
                user.Username = await GenerateUniqueUsernameAsync(user.FirstName, user.LastName);
                user.InvitationCode = GenerateInvitationCode();
                _dbContext.Users.Add(user);            
                await _dbContext.SaveChangesAsync();
                
                var employeeRoleId = await _dbContext.Roles
                    .Where(r => r.Name == RoleNames.Employee)
                    .Select(r => r.Id)
                    .FirstOrDefaultAsync();
                _dbContext.UserRoles.Add(new UserRole { UserId = user.Id, RoleId = employeeRoleId });

                employee = _mapper.Map<Employee>(request);
                employee.UserId = user.Id;
                _dbContext.Employees.Add(employee);
                ApplyCreateAuditFields(employee);
                await _dbContext.SaveChangesAsync();

                await tx.CommitAsync();
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }

            // Best-effort welcome email with the activation code — never blocks account creation.
            
            try
            {
                await _bus.PubSub.PublishAsync(new EmployeeInvited
                {
                    Email = user.Email,
                    Username = user.Username,
                    FullName = $"{user.FirstName} {user.LastName}",
                    InvitationCode = user.InvitationCode!
                });
            }   catch(Exception ex)
            {
                _logger.LogWarning(ex, "Nije uspjelo slanje pozivnice za uposlenika {Email}.", user.Email);
            }
            return await GetByIdAsync(employee.Id);
        }

        public override async Task<EmployeeResponse> UpdateAsync(int id, EmployeeUpdateRequest request)
        {
            var validationResult = await _updateValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
            {
                throw new ValidationException(validationResult.Errors);
            }

            var employee = await _dbContext.Employees
                .Include(e => e.User)
                .FirstOrDefaultAsync(e => e.Id == id);

            if (employee == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Employee), id));

            // Validate the resulting position/department pairing. Either field may be
            // omitted in the request, so fall back to the employee's current value.
            var effectiveDepartmentId = request.DepartmentId ?? employee.DepartmentId;
            var effectivePositionId = request.PositionId ?? employee.PositionId;
            await ValidatePositionMatchesDepartment(effectivePositionId, effectiveDepartmentId);

            if (request.User != null)
            {
                _mapper.Map(request.User, employee.User);
            }

            _mapper.Map(request, employee);
            ApplyUpdateAuditFields(employee);

            await _dbContext.SaveChangesAsync();

            return await GetByIdAsync(id);
        }

        // A position belongs to exactly one department. Reject combinations where the
        // selected position lives in a different department (e.g. HR + Software Developer).
        private async Task ValidatePositionMatchesDepartment(int positionId, int departmentId)
        {
            var position = await _dbContext.Positions.FirstOrDefaultAsync(p => p.Id == positionId);
            if (position == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Position), positionId));

            if (position.DepartmentId != departmentId)
                throw new ValidationException("Odabrana pozicija ne pripada odabranom odjelu.");
        }

        private static string GenerateInvitationCode(int length = 8)
        {
            var bytes = RandomNumberGenerator.GetBytes(length);
            return new string(bytes.Select(b => chars[b % chars.Length]).ToArray());
        }

        // Builds a login username from the name ("ime.prezime"), transliterating Bosnian
        // diacritics, and appends a number if that username is already taken.
        private async Task<string> GenerateUniqueUsernameAsync(string firstName, string lastName)
        {
            static string Normalize(string value) => value.Trim().ToLowerInvariant()
                .Replace("dž", "dz").Replace("č", "c").Replace("ć", "c")
                .Replace("š", "s").Replace("ž", "z").Replace("đ", "dj")
                .Replace(" ", "");

            var baseName = $"{Normalize(firstName)}.{Normalize(lastName)}";
            var username = baseName;
            var suffix = 1;
            while (await _dbContext.Users.AnyAsync(u => u.Username == username))
                username = $"{baseName}{++suffix}";

            return username;
        }

        public async Task<EmployeeResponse> GetMyProfileAsync()
        {
            var userId = _userAccessor.GetUserId();
            var employeeId = await _dbContext.Employees
                .Where(e => e.UserId == userId)
                .Select(e => (int?)e.Id)
                .FirstOrDefaultAsync()
                ?? throw new NotFoundException("Profil nije pronađen za trenutnog korisnika.");

            return await GetByIdAsync(employeeId);
        }

        public async Task<EmployeeResponse> UpdateMyProfileAsync(ProfileUpdateRequest request)
        {
            var validationResult = await _profileValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new ValidationException(validationResult.Errors);

            var userId = _userAccessor.GetUserId();
            var employee = await _dbContext.Employees
                .Include(e => e.User)
                .FirstOrDefaultAsync(e => e.UserId == userId);

            if (employee == null)
                throw new NotFoundException("Profil nije pronađen za trenutnog korisnika.");

            // Only contact details — never job/org fields (department, position, salary…).
            if (request.Username != null && request.Username != employee.User.Username)
            {
                var taken = await _dbContext.Set<User>()
                    .AnyAsync(u => u.Username == request.Username && u.Id != employee.UserId);
                if (taken)
                    throw new BusinessException("Korisničko ime je već zauzeto.");
                employee.User.Username = request.Username;
            }
            if (request.Email != null) employee.User.Email = request.Email;
            if (request.PhoneNumber != null) employee.User.PhoneNumber = request.PhoneNumber;
            if (request.Address != null) employee.Address = request.Address;
            if (request.ProfileImageBase64 != null)
            {
                employee.User.ProfileImageBase64 = request.ProfileImageBase64;
                employee.User.ProfileThumbnailBase64 =
                    ImageThumbnail.Create(request.ProfileImageBase64);
            }

            ApplyUpdateAuditFields(employee);
            await _dbContext.SaveChangesAsync();

            return await GetByIdAsync(employee.Id);
        }

        public async Task<EmployeeResponse> DeactivateAsync(int id)
        {
            var employee = await _dbContext.Set<Employee>().FirstOrDefaultAsync(e => e.Id == id);

            if (employee == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Employee), id));

            if (employee.IsActive)
                employee.IsActive = false;

            await _dbContext.SaveChangesAsync();
            return await GetByIdAsync(id);
        }
    }
}
