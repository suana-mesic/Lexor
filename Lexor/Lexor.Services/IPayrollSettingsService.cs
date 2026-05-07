using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    public interface IPayrollSettingsService : IBaseCRUDService<PayrollSettingsResponse, PayrollSettingsSearchObject, PayrollSettingsInsertRequest, PayrollSettingsUpdateRequest>
    {
        Task<PayrollSettingsResponse?> GetCurrentAsync();
    }
}
