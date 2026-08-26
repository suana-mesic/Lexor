using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    public interface IAttendanceService : IBaseCRUDService<AttendanceResponse, AttendanceSearchObject, AttendanceInsertRequest, AttendanceUpdateRequest>
    {
        Task<ScanResponse> ScanAsync(ScanRequest request);
        Task<AttendanceSummaryResponse> GetAttendanceSummaryAsync();

        // Per-employee attendance totals for one month, for the HR report.
        Task<AttendanceReportResponse> GetMonthlyReportAsync(int year, int month);
    }
}
