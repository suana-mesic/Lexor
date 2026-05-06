using Lexor.Services.Database;

namespace Lexor.Services
{
    public interface ITokenService
    {
        string GenerateAccessToken(User user);
        string GenerateRefreshToken();
    }
}
