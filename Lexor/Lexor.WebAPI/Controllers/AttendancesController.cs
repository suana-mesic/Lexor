using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Lexor.Services.Reports;
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

        // Aggregated month view behind the HR attendance report - also served as JSON so the
        // desktop can preview the figures before downloading the PDF.
        [HttpGet("report")]
        [Authorize(Roles = RoleNames.HrManager)]
        public async Task<AttendanceReportResponse> GetMonthlyReport([FromQuery] int year, [FromQuery] int month)
            => await _service.GetMonthlyReportAsync(year, month);

        [HttpGet("report/pdf")]
        [Authorize(Roles = RoleNames.HrManager)]
        public async Task<IActionResult> GetMonthlyReportPdf([FromQuery] int year, [FromQuery] int month)
        {
            var report = await _service.GetMonthlyReportAsync(year, month);
            var bytes = AttendancePdf.MonthlyReport(report);
            return File(bytes, "application/pdf", $"izvjestaj-prisustva-{year}-{month:D2}.pdf");
        }
    }

}
