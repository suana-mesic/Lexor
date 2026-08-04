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
    public class DepartmentsController : BaseCRUDController<DepartmentResponse, DepartmentSearchObject, IDepartmentService, DepartmentInsertRequest, DepartmentUpdateRequest>
    {
        public DepartmentsController(IDepartmentService DepartmentService) : base(DepartmentService)
        {

        }

        [Authorize(Roles =RoleNames.Administrator)]
        public override Task<ActionResult<DepartmentResponse>> Create([FromBody] DepartmentInsertRequest request)
            => base.Create(request);

        [Authorize(Roles =RoleNames.Administrator)]
        public override Task<ActionResult<DepartmentResponse>> Update(int id, [FromBody] DepartmentUpdateRequest request)
            => base.Update(id, request);

        [Authorize(Roles =RoleNames.Administrator)]
        public override Task<ActionResult<DepartmentResponse>> Delete(int id)
            => base.Delete(id);
    }
}
