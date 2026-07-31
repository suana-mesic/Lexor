using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    [Authorize]
    public class ContractTypesController : BaseCRUDController<ContractTypeResponse, ContractTypeSearchObject, IContractTypeService, ContractTypeInsertRequest, ContractTypeUpdateRequest>
    {
        public ContractTypesController(IContractTypeService contractTypeService) : base(contractTypeService)
        {
        }

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<ContractTypeResponse>> Create([FromBody] ContractTypeInsertRequest request)
            => base.Create(request);

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<ContractTypeResponse>> Update(int id, [FromBody] ContractTypeUpdateRequest request)
            => base.Update(id, request);

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<ContractTypeResponse>> Delete(int id)
            => base.Delete(id);
    }
}
