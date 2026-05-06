using Lexor.Services.Database;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace Lexor.Services
{
    public class TokenService : ITokenService
    {
        private const int RefreshTokenSizeBytes = 64;
        private readonly IConfiguration _configuration;

        public TokenService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public string GenerateAccessToken(User user)
        {
            string secretKeyString = _configuration["JwtToken:SecretKey"] ?? string.Empty;
            var issuer = _configuration["JwtToken:Issuer"];
            var audience = _configuration["JwtToken:Audience"];
            var durationInMinutes = _configuration["JwtToken:DurationInMinutes"] ?? "1";

            var secretKey = Encoding.UTF8.GetBytes(secretKeyString); //byte []

            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.GivenName, user.FirstName),
                new Claim(JwtRegisteredClaimNames.FamilyName, user.LastName),
                new Claim(JwtRegisteredClaimNames.Email, user.Email),
            };

            //User can have more than one role, we add claim for each role 
            if (user.UserRoles != null)
            {
                foreach (var userRole in user.UserRoles)
                {
                    if (userRole.Role != null && userRole.Role.IsActive)
                    {
                        claims.Add(new Claim(ClaimTypes.Role, userRole.Role.Name));
                    }
                }
            }

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                SigningCredentials = new SigningCredentials(
                    new SymmetricSecurityKey(secretKey),
                    SecurityAlgorithms.HmacSha256Signature),
                Issuer = issuer,
                Audience = audience,
                Expires = DateTime.UtcNow.AddMinutes(int.Parse(durationInMinutes))
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }

        public string GenerateRefreshToken()
        {
            byte[] randomBytes = RandomNumberGenerator.GetBytes(RefreshTokenSizeBytes);
            return Convert.ToBase64String(randomBytes);
        }
    }
}
