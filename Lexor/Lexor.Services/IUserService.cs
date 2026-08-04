using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    /// <summary>
    /// Administrator-only user management: listing/searching all accounts, changing a
    /// user's role, activating/deactivating an account and triggering a password reset.
    /// </summary>
    public interface IUserService : IBaseReadService<UserResponse, UserSearchObject>
    {
        Task<UserResponse> ChangeRoleAsync(int userId, ChangeUserRoleRequest request);
        Task<UserResponse> SetActiveAsync(int userId, bool isActive);
        Task<AdminStatsResponse> GetStatsAsync();
    }
}
