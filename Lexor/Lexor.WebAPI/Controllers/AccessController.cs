using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services.Access;
using Lexor.Services.Helpers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class AccessController : ControllerBase
    {
        private readonly IAccessManager _accessManager;
        private readonly ICryptoService _cryptoService;

        public AccessController(IAccessManager accessManager, ICryptoService cryptoService)
        {
            _accessManager = accessManager;
            _cryptoService = cryptoService;
        }

        [AllowAnonymous]
        [HttpGet("generatePassword")]
        public async Task<ActionResult> GeneratePassword([FromQuery] string password)
        {
            var passwordSalt = _cryptoService.GenerateSalt();
            var passwordHash = _cryptoService.GenerateHash(password, passwordSalt);
            return Ok(new
            {
                passwordSalt,
                passwordHash
            });
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
