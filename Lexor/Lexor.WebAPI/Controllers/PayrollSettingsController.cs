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
    public class PayrollSettingsController : BaseCRUDController<PayrollSettingsResponse, PayrollSettingsSearchObject, IPayrollSettingsService, PayrollSettingsInsertRequest, PayrollSettingsUpdateRequest>
    {
        public PayrollSettingsController(IPayrollSettingsService service) : base(service)
        {
        }

        [HttpGet("current")]
        [Authorize]
        public async Task<ActionResult<PayrollSettingsResponse>> GetCurrent()
        {
            var result = await _service.GetCurrentAsync();
            if (result == null)
                return NotFound("Trenutno važeće stope nisu pronađene.");
            return Ok(result);
        }
    }
}
