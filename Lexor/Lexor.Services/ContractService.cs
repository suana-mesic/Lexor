using FluentValidation;
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
        public ContractService(LexorDbContext dbContext, IMapper mapper, IValidator<ContractInsertRequest> insertValidator, IValidator<ContractUpdateRequest> updateValidator)
            : base(dbContext, mapper, insertValidator, updateValidator)
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
                if (search.OnlyActive == true)
                {
                    query = query.Where(c => c.IsActive);
                }
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
                throw new KeyNotFoundException($"Employee with id {request.EmployeeId} not found.");

            var contractType = await _dbContext.Set<ContractType>()
                .FirstOrDefaultAsync(ct => ct.Id == request.ContractTypeId);

            if (contractType == null)
                throw new KeyNotFoundException($"ContractType with id {request.ContractTypeId} not found.");

            if (contractType.EndDateRequired && !request.EndDate.HasValue)
                throw new ValidationException("End date is required for this contract type.");

            if (request.IsActive)
            {
                var hasActive = await _dbContext.Contracts
                    .AnyAsync(c => c.EmployeeId == request.EmployeeId && c.IsActive);
                if (hasActive)
                    throw new ValidationException("Employee already has an active contract. Deactivate it before adding a new one.");
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
                throw new KeyNotFoundException($"Contract with id {id} not found.");

            if (!contract.IsActive)
                throw new ValidationException($"Cannot edit inactive contract {contract.Id}. History is read-only.");

            _mapper.Map(request, contract);
            await _dbContext.SaveChangesAsync();

            return await GetByIdAsync(id);
        }
    }
}
