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
    }
}
