using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services.Access;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AccessController : ControllerBase
    {
        private readonly IAccessManager _accessManager;
        public AccessController(IAccessManager accessManager)
        {
            _accessManager = accessManager;
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
        {
            var result = await _accessManager.Login(request);
            if (result == null)
                return Unauthorized("Pogrešni kredencijali.");
            return Ok(result);
        }

        [AllowAnonymous]
        [HttpPost("refresh")]
        public async Task<ActionResult<LoginResponse>> Refresh([FromBody] RefreshTokenRequest request)
        {
            var result = await _accessManager.Refresh(request);
            if (result == null)
                return Unauthorized("Nevažeći ili istekao refresh token.");
            return Ok(result);
        }

        [Authorize]
        [HttpPost("logout")]

        public async Task<IActionResult> Logout([FromBody] RefreshTokenRequest request)
        {
            await _accessManager.Logout(request);
            return NoContent();
        }
    }
}
