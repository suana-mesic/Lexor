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

namespace Lexor.Services
{
    public class EmployeeService : BaseCRUDService<Employee, EmployeeResponse, EmployeeSearchObject, EmployeeInsertRequest, EmployeeUpdateRequest>, IEmployeeService
    {
        const string chars = "ABCDEFGHIJKLMNPQRSTUVWXYZ23456789"; // without similar (0/O, 1/I/L)

        public EmployeeService(LexorDbContext dbContext, IMapper mapper, IValidator<EmployeeInsertRequest> insertValidator, IValidator<EmployeeUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor)
            : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {
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
                    _ => throw new ValidationException(
                        $"Nevažeća vrijednost ActivityStatus: {(int)search.ActivityStatus.Value}.")
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

            await using var tx = await _dbContext.Database.BeginTransactionAsync();
            try
            {
                var user = _mapper.Map<User>(request.User);
                user.InvitationCode = GenerateInvitationCode();
                _dbContext.Users.Add(user);
                await _dbContext.SaveChangesAsync();

                var employee = _mapper.Map<Employee>(request);
                employee.UserId = user.Id;
                _dbContext.Employees.Add(employee);
                ApplyCreateAuditFields(employee);
                await _dbContext.SaveChangesAsync();

                await tx.CommitAsync();

                return await GetByIdAsync(employee.Id);
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }
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
                throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Employee), id));

            if (request.User != null)
            {
                _mapper.Map(request.User, employee.User);
            }

            _mapper.Map(request, employee);
            ApplyUpdateAuditFields(employee);

            await _dbContext.SaveChangesAsync();

            return await GetByIdAsync(id);
        }

        private static string GenerateInvitationCode(int length = 8)
        {
            var bytes = RandomNumberGenerator.GetBytes(length);
            return new string(bytes.Select(b => chars[b % chars.Length]).ToArray());
        }

        public async Task<EmployeeResponse> DeactivateAsync(int id)
        {
            var employee = await _dbContext.Set<Employee>().FirstOrDefaultAsync(e => e.Id == id);

            if (employee == null)
                throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Employee), id));

            if (employee.IsActive)
                employee.IsActive = false;

            await _dbContext.SaveChangesAsync();
            return await GetByIdAsync(id);
        }
    }
}
