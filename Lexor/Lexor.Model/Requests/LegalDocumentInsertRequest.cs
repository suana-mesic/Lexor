namespace Lexor.Model.Requests
{
    public class LegalDocumentInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public int CategoryId { get; set; }
        public string FileBase64 { get; set; } = string.Empty;
        public long FileSize { get; set; }
    }
}
