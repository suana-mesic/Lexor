using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;

namespace Lexor.WebAPI.Controllers
{
    [Authorize(Roles = RoleNames.Administrator)]
    public class ContractsController : BaseCRUDController<ContractResponse, ContractSearchObject, IContractService, ContractInsertRequest, ContractUpdateRequest>
    {
        public ContractsController(IContractService contractService) : base(contractService)
        {
        }
    }
}
