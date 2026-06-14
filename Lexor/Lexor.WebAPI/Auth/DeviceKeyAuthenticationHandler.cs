using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using System.Security.Claims;
using System.Text.Encodings.Web;

namespace Lexor.WebAPI.Auth
{
    public class DeviceKeyAuthenticationOptions : AuthenticationSchemeOptions
    {
        public string HeaderName { get; set; } = "X-Device-Key";
        public string ExpectedKey { get; set; } = string.Empty;
    }

    public class DeviceKeyAuthenticationHandler : AuthenticationHandler<DeviceKeyAuthenticationOptions>
    {
        public DeviceKeyAuthenticationHandler(
             IOptionsMonitor<DeviceKeyAuthenticationOptions> options,
             ILoggerFactory logger,
             UrlEncoder encoder)
            : base(options, logger, encoder) { }

        protected override Task<AuthenticateResult> HandleAuthenticateAsync()
        {
            var providedKey = Request.Headers[Options.HeaderName].FirstOrDefault();

            if (string.IsNullOrEmpty(providedKey) || providedKey != Options.ExpectedKey)
                return Task.FromResult(AuthenticateResult.Fail("Nevažeći ključ uređaja."));

            var claims = new[] { new Claim(ClaimTypes.Role, "Device") };
            //Scheme.Name is registered in Program.cs as "DeviceKey"
            var identity = new ClaimsIdentity(claims, Scheme.Name);
            var principal = new ClaimsPrincipal(identity);
            var ticket = new AuthenticationTicket(principal, Scheme.Name);
            return Task.FromResult(AuthenticateResult.Success(ticket));
        }
    }
}
