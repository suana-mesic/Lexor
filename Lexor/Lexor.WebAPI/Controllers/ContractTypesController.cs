using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;

namespace Lexor.WebAPI.Controllers
{
    public class ContractTypesController : BaseCRUDController<ContractTypeResponse, ContractTypeSearchObject, IContractTypeService, ContractTypeInsertRequest, ContractTypeUpdateRequest>
    {
        public ContractTypesController(IContractTypeService contractTypeService) : base(contractTypeService)
        {
        }
    }
}
