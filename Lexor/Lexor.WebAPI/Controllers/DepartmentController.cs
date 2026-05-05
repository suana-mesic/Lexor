using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;

namespace Lexor.WebAPI.Controllers
{
    public class DepartmentsController : BaseCRUDController<DepartmentResponse, DepartmentSearchObject, IDepartmentService, DepartmentInsertRequest, DepartmentUpdateRequest>
    {
        public DepartmentsController(IDepartmentService DepartmentService) : base(DepartmentService)
        {

        }
    }
}
