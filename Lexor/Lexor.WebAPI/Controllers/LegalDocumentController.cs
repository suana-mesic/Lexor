using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    // The whole controller is admin-only: documents are reached over HTTP only from the admin panel.
    // Employees do NOT read documents directly — the chatbot answers their questions by reading
    // LegalDocumentChunk server-side, not through these endpoints.
    [Authorize(Roles =RoleNames.Administrator)]
    public class LegalDocumentController : BaseCRUDController<LegalDocumentResponse,
    LegalDocumentSearchObject, ILegalDocumentService, LegalDocumentInsertRequest, LegalDocumentUpdateRequest>
    {
        public LegalDocumentController(ILegalDocumentService service) : base(service) { }
   
        [HttpGet("{id}/download")]
        public async Task<IActionResult> Download(int id)
        {
            var (bytes, fileName) = await _service.GetFileForDownloadAsync(id);
            return File(bytes, "application/pdf", fileName);
        }
    }
}
