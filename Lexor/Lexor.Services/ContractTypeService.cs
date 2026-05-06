using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services
{
    public class ContractTypeService : BaseCRUDService<ContractType, ContractTypeResponse, ContractTypeSearchObject, ContractTypeInsertRequest, ContractTypeUpdateRequest>, IContractTypeService
    {
        public ContractTypeService(LexorDbContext dbContext, IMapper mapper, IValidator<ContractTypeInsertRequest> insertValidator, IValidator<ContractTypeUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor) : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {
        }

        protected override IQueryable<ContractType> ApplyFilters(IQueryable<ContractType> query, ContractTypeSearchObject? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(c => c.Name.ToLower().Contains(search.Name.ToLower()));
                }
            }
            return query;
        }
    }
}
