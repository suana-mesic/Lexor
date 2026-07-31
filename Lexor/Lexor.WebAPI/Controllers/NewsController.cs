using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    // Read is open to any authenticated user (employees see announcements on mobile),
    // while create/update/delete are admin-only.
    [Authorize]
    public class NewsController : BaseCRUDController<NewsResponse, NewsSearchObject, INewsService, NewsInsertRequest, NewsUpdateRequest>
    {
        public NewsController(INewsService service) : base(service)
        {
        }

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<NewsResponse>> Create([FromBody] NewsInsertRequest request)
            => base.Create(request);

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<NewsResponse>> Update(int id, [FromBody] NewsUpdateRequest request)
            => base.Update(id, request);

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<NewsResponse>> Delete(int id)
            => base.Delete(id);
    }
}
