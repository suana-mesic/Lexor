using Lexor.Model.Responses;

namespace Lexor.Services
{
    public interface IDashboardService
    {
        Task<DashboardResponse> GetDashboardDataAsync();
    }
}
