namespace Lexor.Model.Responses
{
    public class NewsResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? ImageBase64 { get; set; }
        public DateTime PublishedAt { get; set; }

        // Author of the announcement (null for legacy/seeded rows). The desktop UI uses this to
        // show edit/delete only on the current user's own announcements (admins see them on all).
        public int? PublishedByUserId { get; set; }
    }
}
