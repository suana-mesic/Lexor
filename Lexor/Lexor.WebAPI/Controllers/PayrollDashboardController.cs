using Lexor.Model.Constants;
using Lexor.Model.Responses;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    // Finance/payroll overview for the accounting role's dashboard.
    [Route("[controller]")]
    [ApiController]
    [Authorize(Roles = RoleNames.Accounting)]
    public class PayrollDashboardController : ControllerBase
    {
        private readonly ISalarySlipService _service;

        public PayrollDashboardController(ISalarySlipService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<ActionResult<PayrollDashboardResponse>> Get()
            => Ok(await _service.GetPayrollDashboardAsync());
    }
}
