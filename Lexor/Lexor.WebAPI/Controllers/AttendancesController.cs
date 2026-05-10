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

        protected readonly IConfiguration _configuration;
        public AttendancesController(IAttendanceService attendanceService, IConfiguration configuration) : base(attendanceService)
        {
            _configuration = configuration;
        }

        [AllowAnonymous]   // ESP32 doesn't have JWT
        [HttpPost("scan")]
        public async Task<ActionResult<ScanResponse>> Scan([FromBody] ScanRequest request)
        {
            var providedKey = Request.Headers["X-Device-Key"].FirstOrDefault();
            var expectedKey = _configuration["RfidDeviceApiKey"];

            if (string.IsNullOrEmpty(providedKey) || providedKey != expectedKey)
                return Unauthorized("Nevažeći ključ uređaja.");

            var result = await _service.ScanAsync(request);
            return Ok(result);
        }
        [Authorize]
        public override Task<PageResult<AttendanceResponse>> GetAllAsync([FromQuery] AttendanceSearchObject? search = null)
            => base.GetAllAsync(search);

        [Authorize]
        public override Task<ActionResult<AttendanceResponse>> GetByIdAsync(int id)
            => base.GetByIdAsync(id);

        [Authorize(Roles = RoleNames.Administrator)]
        public override Task<ActionResult<AttendanceResponse>> Update(int id, [FromBody] AttendanceUpdateRequest request)
            => base.Update(id, request);

        [Authorize(Roles = RoleNames.Administrator)]
        public override Task<ActionResult<AttendanceResponse>> Create([FromBody] AttendanceInsertRequest request)
            => base.Create(request);

        [Authorize(Roles = RoleNames.Administrator)]
        public override Task<ActionResult<AttendanceResponse>> Delete(int id)
            => base.Delete(id);

    }

}
