using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    // employees and administrators can call GetAll/GetById, but they see different results
    [Authorize]
    public class LeavesController : BaseCRUDController<LeaveResponse, LeaveSearchObject, ILeaveService, LeaveInsertRequest, LeaveUpdateRequest>
    {
        public LeavesController(ILeaveService leaveService) : base(leaveService)
        {
        }

        // only employees can submit a leave request (admins approve/reject, never create)
        [Authorize(Roles = RoleNames.Employee)]
        public override Task<ActionResult<LeaveResponse>> Create([FromBody] LeaveInsertRequest request)
            => base.Create(request);

        // only employees can edit their own pending leave requests
        [Authorize(Roles = RoleNames.Employee)]
        public override Task<ActionResult<LeaveResponse>> Update(int id, [FromBody] LeaveUpdateRequest request)
            => base.Update(id, request);

        [HttpPut("cancel/{id}")]
        [Authorize(Roles = RoleNames.Employee)]
        public async Task<ActionResult<LeaveResponse>> Cancel(int id)
        {
            var result = await _service.CancelAsync(id);
            return result;
        }
        [Authorize(Roles = RoleNames.Administrator)]
        public override Task<ActionResult<LeaveResponse>> Delete(int id)
            => base.Delete(id);

        [HttpPut("approve/{id}")]
        [Authorize(Roles = RoleNames.Administrator)]
        public async Task<ActionResult<LeaveResponse>> Approve(int id)
        {
            var result = await _service.ApproveAsync(id);
            return result;
        }
        [HttpPut("reject/{id}")]
        [Authorize(Roles = RoleNames.Administrator)]
        public async Task<ActionResult<LeaveResponse>> Reject(int id, [FromBody] LeaveRejectRequest request)
        {
            var result = await _service.RejectAsync(id, request);
            return result;
        }

        [HttpGet("allowed-actions/{id}")]
        public async Task<ActionResult<List<string>>> GetAllowedActions(int id)
        {
            var result = await _service.GetAllowedActions(id);
            return Ok(result);
        }
    }
}
