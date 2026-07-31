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
    public class AttendancesController : BaseCRUDController<AttendanceResponse, AttendanceSearchObject, IAttendanceService, AttendanceInsertRequest, AttendanceUpdateRequest>
    {
        public AttendancesController(IAttendanceService attendanceService) : base(attendanceService)
        {
        }

        [HttpPost("scan")]
        [Authorize(AuthenticationSchemes = "DeviceKey")]
        public async Task<ActionResult<ScanResponse>> Scan([FromBody] ScanRequest request)
        {
            var result = await _service.ScanAsync(request);
            return Ok(result);
        }
        [Authorize]
        public override Task<PageResult<AttendanceResponse>> GetAllAsync([FromQuery] AttendanceSearchObject? search = null)
            => base.GetAllAsync(search);

        [Authorize]
        public override Task<ActionResult<AttendanceResponse>> GetByIdAsync(int id)
            => base.GetByIdAsync(id);

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<AttendanceResponse>> Update(int id, [FromBody] AttendanceUpdateRequest request)
            => base.Update(id, request);

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<AttendanceResponse>> Create([FromBody] AttendanceInsertRequest request)
            => base.Create(request);

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<AttendanceResponse>> Delete(int id)
            => base.Delete(id);

        [HttpGet("summary")]
        public async Task<AttendanceSummaryResponse> GetAttendanceSummary()
            => await _service.GetAttendanceSummaryAsync();
    }

}
