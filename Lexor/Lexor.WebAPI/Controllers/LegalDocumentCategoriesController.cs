using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    [Authorize]
    public class LegalDocumentCategoriesController : BaseCRUDController<LegalDocumentCategoryResponse, LegalDocumentCategorySearchObject, ILegalDocumentCategoryService, LegalDocumentCategoryInsertRequest, LegalDocumentCategoryUpdateRequest>
    {
        public LegalDocumentCategoriesController(ILegalDocumentCategoryService legalDocumentCategoryService) : base(legalDocumentCategoryService)
        {
        }

        [Authorize(Roles = RoleNames.Administrator)]
        public override Task<ActionResult<LegalDocumentCategoryResponse>> Create([FromBody] LegalDocumentCategoryInsertRequest request)
            => base.Create(request);

        [Authorize(Roles = RoleNames.Administrator)]
        public override Task<ActionResult<LegalDocumentCategoryResponse>> Update(int id, [FromBody] LegalDocumentCategoryUpdateRequest request)
            => base.Update(id, request);

        [Authorize(Roles = RoleNames.Administrator)]
        public override Task<ActionResult<LegalDocumentCategoryResponse>> Delete(int id)
            => base.Delete(id);
    }
}
