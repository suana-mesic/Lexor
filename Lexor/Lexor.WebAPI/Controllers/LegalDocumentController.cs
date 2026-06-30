using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    // Cijeli kontroler je admin-only: dokumentima preko HTTP-a pristupa samo admin panel.
    // Uposlenici NE čitaju dokumente direktno — chatbot odgovara na njihova pitanja
    // čitajući LegalDocumentChunk server-side, a ne kroz ove endpointe.
    [Authorize(Roles = RoleNames.Administrator)]
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
