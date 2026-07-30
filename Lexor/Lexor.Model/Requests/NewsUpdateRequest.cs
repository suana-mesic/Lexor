namespace Lexor.Model.Requests
{
    public class NewsUpdateRequest
    {
        public string? Title { get; set; }
        public string? Content { get; set; }
        public string? ImageBase64 { get; set; }
    }
}
