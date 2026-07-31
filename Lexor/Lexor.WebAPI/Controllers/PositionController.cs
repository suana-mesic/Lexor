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
    public class PositionsController : BaseCRUDController<PositionResponse, PositionSearchObject, IPositionService, PositionInsertRequest, PositionUpdateRequest>
    {
        public PositionsController(IPositionService PositionService) : base(PositionService)
        {

        }

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<PositionResponse>> Create([FromBody] PositionInsertRequest request)
            => base.Create(request);

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<PositionResponse>> Update(int id, [FromBody] PositionUpdateRequest request)
            => base.Update(id, request);

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<PositionResponse>> Delete(int id)
            => base.Delete(id);
    }
}
