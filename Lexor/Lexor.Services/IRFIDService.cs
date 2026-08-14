using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    public interface IRFIDService : IBaseCRUDService<RFIDResponse, RFIDSearchObject, RFIDInsertRequest, RFIDUpdateRequest>
    {
        Task<RFIDResponse> DeactivateAsync(int id);
        Task<RFIDResponse> ReactivateAsync(int id);
    }
}
