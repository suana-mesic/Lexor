using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    public interface IAttendanceService : IBaseCRUDService<AttendanceResponse, AttendanceSearchObject, AttendanceInsertRequest, AttendanceUpdateRequest>
    {
        Task<ScanResponse> ScanAsync(ScanRequest request);
    }
}
