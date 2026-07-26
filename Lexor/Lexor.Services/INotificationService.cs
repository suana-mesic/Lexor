using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    public interface INotificationService:IBaseReadService<NotificationResponse, NotificationSearchObject>   
    {
        Task<int> GetUnreadCountAsync();
        Task<NotificationResponse> MarkAsReadAsync(int id);
        Task MarkAllAsReadAsync();
    }
}
