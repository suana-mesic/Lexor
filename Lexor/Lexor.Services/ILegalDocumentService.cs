using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    public interface ILegalDocumentService : IBaseCRUDService<LegalDocumentResponse, LegalDocumentSearchObject, LegalDocumentInsertRequest, LegalDocumentUpdateRequest>
    {
        public Task<(byte[] Bytes, string FileName)> GetFileForDownloadAsync(int id);

    }
}
