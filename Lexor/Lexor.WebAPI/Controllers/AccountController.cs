using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services;
using Lexor.Services.Access;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    // Self-service account for the current user (admin or employee).
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class AccountController : ControllerBase
    {
        private readonly IAccountService _accountService;
        private readonly IAccessManager _accessManager;

        public AccountController(IAccountService accountService, IAccessManager accessManager)
        {
            _accountService = accountService;
            _accessManager = accessManager;
        }

        [HttpGet]
        public async Task<ActionResult<AccountResponse>> GetMyAccount()
        {
            return await _accountService.GetCurrentAsync();
        }

        [HttpPut]
        public async Task<ActionResult<AccountResponse>> UpdateMyAccount([FromBody] AccountUpdateRequest request)
        {
            return await _accountService.UpdateAsync(request);
        }

        [HttpPut("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            await _accessManager.ChangePasswordAsync(request);
            return NoContent();
        }
    }
}
