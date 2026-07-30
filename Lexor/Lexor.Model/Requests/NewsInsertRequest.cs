namespace Lexor.Model.Requests
{
    public class NewsInsertRequest
    {
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? ImageBase64 { get; set; }
    }
}
