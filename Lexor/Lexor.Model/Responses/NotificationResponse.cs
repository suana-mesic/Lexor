using Lexor.Model.Enums;

namespace Lexor.Model.Responses
{
    public class NotificationResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public NotificationType NotificationType { get; set; }
        public bool IsRead { get; set; }
        public DateTime CreatedAt { get; set; }
        public RelatedEntityType? RelatedEntityType { get; set; }
        public int? RelatedEntityId { get; set; }

    }
}
