using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;

namespace Lexor.WebAPI.Controllers
{
    [Authorize(Roles = RoleNames.Administrator)]
    public class EmployeesController : BaseCRUDController<EmployeeResponse, EmployeeSearchObject, IEmployeeService, EmployeeInsertRequest, EmployeeUpdateRequest>
    {
        public EmployeesController(IEmployeeService Employeeservice) : base(Employeeservice)
        {

        }
    }
}
