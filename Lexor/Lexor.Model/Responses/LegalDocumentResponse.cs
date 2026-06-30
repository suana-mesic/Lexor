namespace Lexor.Model.Responses
{
    public class LegalDocumentResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string CategoryName { get; set; } = string.Empty;
        public DateTime UploadedAt { get; set; } 

    }
}
