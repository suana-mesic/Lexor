using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    // Read is open to any authenticated user (employees see announcements on mobile). Any
    // back-office role may publish; editing and deleting are limited per-author in NewsService
    // (own announcements only, administrators any).
    [Authorize]
    public class NewsController : BaseCRUDController<NewsResponse, NewsSearchObject, INewsService, NewsInsertRequest, NewsUpdateRequest>
    {
        private const string BackOfficeRoles =
            $"{RoleNames.HrManager},{RoleNames.Accounting},{RoleNames.Administrator}";

        public NewsController(INewsService service) : base(service)
        {
        }

        [Authorize(Roles = BackOfficeRoles)]
        public override Task<ActionResult<NewsResponse>> Create([FromBody] NewsInsertRequest request)
            => base.Create(request);

        [Authorize(Roles = BackOfficeRoles)]
        public override Task<ActionResult<NewsResponse>> Update(int id, [FromBody] NewsUpdateRequest request)
            => base.Update(id, request);

        [Authorize(Roles = BackOfficeRoles)]
        public override Task<ActionResult<NewsResponse>> Delete(int id)
            => base.Delete(id);
    }
}
