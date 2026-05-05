using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;

namespace Lexor.WebAPI.Controllers
{
    public class LegalDocumentCategoriesController : BaseCRUDController<LegalDocumentCategoryResponse, LegalDocumentCategorySearchObject, ILegalDocumentCategoryService, LegalDocumentCategoryInsertRequest, LegalDocumentCategoryUpdateRequest>
    {
        public LegalDocumentCategoriesController(ILegalDocumentCategoryService legalDocumentCategoryService) : base(legalDocumentCategoryService)
        {
        }
    }
}
