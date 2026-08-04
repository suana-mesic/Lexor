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
    public class LeaveTypesController : BaseCRUDController<LeaveTypeResponse, LeaveTypeSearchObject, ILeaveTypeService, LeaveTypeInsertRequest, LeaveTypeUpdateRequest>
    {
        public LeaveTypesController(ILeaveTypeService LeaveTypeservice) : base(LeaveTypeservice)
        {

        }

        [Authorize(Roles =RoleNames.Administrator)]
        public override Task<ActionResult<LeaveTypeResponse>> Create([FromBody] LeaveTypeInsertRequest request)
            => base.Create(request);

        [Authorize(Roles =RoleNames.Administrator)]
        public override Task<ActionResult<LeaveTypeResponse>> Update(int id, [FromBody] LeaveTypeUpdateRequest request)
            => base.Update(id, request);

        [Authorize(Roles =RoleNames.Administrator)]
        public override Task<ActionResult<LeaveTypeResponse>> Delete(int id)
            => base.Delete(id);
    }
}
