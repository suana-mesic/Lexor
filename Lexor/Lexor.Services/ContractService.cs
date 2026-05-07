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
    public class ContractService : BaseCRUDService<Contract, ContractResponse, ContractSearchObject, ContractInsertRequest, ContractUpdateRequest>, IContractService
    {
        public ContractService(LexorDbContext dbContext, IMapper mapper, IValidator<ContractInsertRequest> insertValidator, IValidator<ContractUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor)
            : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {
        }

        protected override IQueryable<Contract> ApplyFilters(IQueryable<Contract> query, ContractSearchObject? search)
        {
            if (search != null)
            {
                if (search.EmployeeId.HasValue)
                {
                    query = query.Where(c => c.EmployeeId == search.EmployeeId);
                }
                if (search.ContractTypeId.HasValue)
                {
                    query = query.Where(c => c.ContractTypeId == search.ContractTypeId);
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

        protected override IQueryable<Contract> IncludeRelatedEntities(ContractSearchObject? search, IQueryable<Contract> query)
        {
            return query.Include(c => c.ContractType);
        }

        public override async Task<ContractResponse> InsertAsync(ContractInsertRequest request)
        {
            var validationResult = await _insertValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new ValidationException(validationResult.Errors);

            var employeeExists = await _dbContext.Employees.AnyAsync(e => e.Id == request.EmployeeId);
            if (!employeeExists)
                throw new KeyNotFoundException($"Zaposlenik sa Id-em {request.EmployeeId} nije pronađen.");

            var contractType = await _dbContext.Set<ContractType>()
                .FirstOrDefaultAsync(ct => ct.Id == request.ContractTypeId);

            if (contractType == null)
                throw new KeyNotFoundException($"Tip ugovora sa Id-em {request.ContractTypeId} nije pronađen.");

            if (contractType.EndDateRequired && !request.EndDate.HasValue)
                throw new ValidationException("Datum završetka je obavezan za ovaj tip ugovora.");

            if (request.IsActive)
            {
                var hasActive = await _dbContext.Contracts
                    .AnyAsync(c => c.EmployeeId == request.EmployeeId && c.IsActive);
                if (hasActive)
                    throw new ValidationException("Zaposlenik već ima aktivan ugovor. Deaktivirajte postojeći prije nego što dodate novi.");
            }

            var entity = _mapper.Map<Contract>(request);
            _dbContext.Contracts.Add(entity);
            await _dbContext.SaveChangesAsync();

            return await GetByIdAsync(entity.Id);
        }

        public override async Task<ContractResponse> UpdateAsync(int id, ContractUpdateRequest request)
        {
            var validationResult = await _updateValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new ValidationException(validationResult.Errors);

            var contract = await _dbContext.Contracts.FirstOrDefaultAsync(c => c.Id == id);
            if (contract == null)
                throw new KeyNotFoundException($"Ugovor sa Id-em {id} nije pronađen.");

            if (!contract.IsActive)
                throw new ValidationException($"Nije moguće uređivati neaktivan ugovor {contract.Id}. Istorija je samo za čitanje.");

            _mapper.Map(request, contract);
            await _dbContext.SaveChangesAsync();

            return await GetByIdAsync(id);
        }
    }
}
