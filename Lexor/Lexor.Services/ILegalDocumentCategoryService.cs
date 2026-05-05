using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    // LegalDocumentCategory service contract. Currently extends only generic CRUD,
    // but reserved for LegalDocumentCategory-specific methods.
    public interface ILegalDocumentCategoryService : IBaseCRUDService<LegalDocumentCategoryResponse, LegalDocumentCategorySearchObject, LegalDocumentCategoryInsertRequest, LegalDocumentCategoryUpdateRequest>
    {
    }
}
