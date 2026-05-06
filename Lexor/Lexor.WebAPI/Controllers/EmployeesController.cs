using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;

namespace Lexor.WebAPI.Controllers
{
    public class EmployeesController : BaseCRUDController<EmployeeResponse, EmployeeSearchObject, IEmployeeService, EmployeeInsertRequest, EmployeeUpdateRequest>
    {
        public EmployeesController(IEmployeeService Employeeservice) : base(Employeeservice)
        {

        }
    }
}
