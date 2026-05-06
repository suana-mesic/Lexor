using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;

namespace Lexor.WebAPI.Controllers
{
    public class ContractsController : BaseCRUDController<ContractResponse, ContractSearchObject, IContractService, ContractInsertRequest, ContractUpdateRequest>
    {
        public ContractsController(IContractService contractService) : base(contractService)
        {
        }
    }
}
