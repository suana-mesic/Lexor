using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    public interface ILeaveService : IBaseCRUDService<LeaveResponse, LeaveSearchObject, LeaveInsertRequest, LeaveUpdateRequest>
    {
        public Task<LeaveResponse> ApproveAsync(int id);
        public Task<LeaveResponse> RejectAsync(int id, LeaveRejectRequest request);
        public Task<LeaveResponse> CancelAsync(int id, string? reason);
        public Task<List<string>> GetAllowedActions(int id);
    }
}
