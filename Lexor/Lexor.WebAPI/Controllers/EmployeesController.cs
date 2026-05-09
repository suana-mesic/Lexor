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
    public class EmployeesController : BaseCRUDController<EmployeeResponse, EmployeeSearchObject, IEmployeeService, EmployeeInsertRequest, EmployeeUpdateRequest>
    {
        public EmployeesController(IEmployeeService Employeeservice) : base(Employeeservice)
        {

        }

        [HttpPatch("{id}/deactivate")]
        public async Task<ActionResult<EmployeeResponse>> Deactivate(int id)
        {
            var result = await _service.DeactivateAsync(id);
            return result;
        }
    }
}
