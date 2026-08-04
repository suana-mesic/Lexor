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
    public class CitiesController : BaseCRUDController<CityResponse, CitySearchObject, ICityService, CityInsertRequest, CityUpdateRequest>
    {
        public CitiesController(ICityService cityService) : base(cityService)
        {

        }

        [Authorize(Roles =RoleNames.Administrator)]
        public override Task<ActionResult<CityResponse>> Create([FromBody] CityInsertRequest request)
            => base.Create(request);

        [Authorize(Roles =RoleNames.Administrator)]
        public override Task<ActionResult<CityResponse>> Update(int id, [FromBody] CityUpdateRequest request)
            => base.Update(id, request);

        [Authorize(Roles =RoleNames.Administrator)]
        public override Task<ActionResult<CityResponse>> Delete(int id)
            => base.Delete(id);
    }
}
