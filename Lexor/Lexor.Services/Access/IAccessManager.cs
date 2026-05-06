using Lexor.Model.Requests;
using Lexor.Model.Responses;

namespace Lexor.Services.Access
{
    public interface IAccessManager
    {
        Task<LoginResponse?> Login(LoginRequest request);
        Task<LoginResponse?> Refresh(RefreshTokenRequest request);
        Task Logout(RefreshTokenRequest request);
    }
}
