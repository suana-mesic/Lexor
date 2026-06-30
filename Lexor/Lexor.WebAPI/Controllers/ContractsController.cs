using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    [Authorize(Roles = RoleNames.Administrator)]
    public class ContractsController : BaseCRUDController<ContractResponse, ContractSearchObject, IContractService, ContractInsertRequest, ContractUpdateRequest>
    {
        public ContractsController(IContractService contractService) : base(contractService)
        {
        }

        // Atomically closes the current active contract and inserts a new one.
        [HttpPost("employee/{employeeId}/replace")]
        public async Task<ActionResult<ContractResponse>> ReplaceActive(int employeeId, [FromBody] ContractInsertRequest request)
        {
            var result = await _service.ReplaceActiveAsync(employeeId, request);
            return result;
        }
    }
}
