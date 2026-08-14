using Lexor.Model.Constants;
using Lexor.Model.Responses;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    [Route("[controller]")]
    [ApiController]
    // Company overview is available to back-office roles that plan around it (HR and accounting).
    [Authorize(Roles = $"{RoleNames.HrManager},{RoleNames.Accounting}")]
    public class DashboardController : ControllerBase
    {
        private readonly IDashboardService _service;

        public DashboardController(IDashboardService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<ActionResult<DashboardResponse>> Get()
        {
            var result = await _service.GetDashboardDataAsync();
            return Ok(result);
        }
    }
}