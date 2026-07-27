namespace Lexor.Services
{
    public interface ILegalDocumentIndexer
    {
        Task IndexAsync(int documentId);
    }
}
