namespace Lexor.Model.Responses
{
    public class NewsResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        // Full picture. Only the details endpoint fills this in; on list endpoints it is null
        // and ThumbnailBase64 carries the (much smaller) image the list needs.
        public string? ImageBase64 { get; set; }
        public string? ThumbnailBase64 { get; set; }
        public DateTime PublishedAt { get; set; }

        // Author of the announcement (null for legacy/seeded rows). The desktop UI uses this to
        // show edit/delete only on the current user's own announcements (admins see them on all).
        public int? PublishedByUserId { get; set; }
    }
}
