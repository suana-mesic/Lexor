using Lexor.Model.Requests;
using Lexor.Model.Responses;

namespace Lexor.Services
{
    public interface IAccountService
    {
        Task<AccountResponse> GetCurrentAsync();
        Task<AccountResponse> UpdateAsync(AccountUpdateRequest request);
    }
}
