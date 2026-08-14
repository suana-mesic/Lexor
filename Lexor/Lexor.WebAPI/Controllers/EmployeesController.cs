using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    // Reading employees is open to HR and accounting (accounting has a read-only view); all
    // writes below are restricted to HR only.
    [Authorize(Roles = $"{RoleNames.HrManager},{RoleNames.Accounting}")]
    public class EmployeesController : BaseCRUDController<EmployeeResponse, EmployeeSearchObject, IEmployeeService, EmployeeInsertRequest, EmployeeUpdateRequest>
    {
        public EmployeesController(IEmployeeService Employeeservice) : base(Employeeservice)
        {

        }

        [Authorize(Roles = RoleNames.HrManager)]
        public override Task<ActionResult<EmployeeResponse>> Create([FromBody] EmployeeInsertRequest request)
            => base.Create(request);

        [Authorize(Roles = RoleNames.HrManager)]
        public override Task<ActionResult<EmployeeResponse>> Update(int id, [FromBody] EmployeeUpdateRequest request)
            => base.Update(id, request);

        [Authorize(Roles = RoleNames.HrManager)]
        public override Task<ActionResult<EmployeeResponse>> Delete(int id)
            => base.Delete(id);

        [Authorize(Roles = RoleNames.HrManager)]
        [HttpPatch("{id}/deactivate")]
        public async Task<ActionResult<EmployeeResponse>> Deactivate(int id)
        {
            var result = await _service.DeactivateAsync(id);
            return result;
        }
    }
}
