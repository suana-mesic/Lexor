using Microsoft.AspNetCore.Http;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace Lexor.Services
{
    public class AuthenticatedUserAccessor : IAuthenticatedUserAccessor
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public AuthenticatedUserAccessor(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        // sub claim = Id claim
        // reads the sub claim (Id claim) that TokenService already puts when it generates the JWT (new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString())).
        public int? GetUserId()
        {
            var sub =
                _httpContextAccessor.HttpContext?.User?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value ??
                _httpContextAccessor.HttpContext?.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return int.TryParse(sub, out var id) ? id : null;
        }

        public bool IsInRole(string role)
        {
            return _httpContextAccessor.HttpContext?.User?.IsInRole(role) ?? false;
        }
    }
}
