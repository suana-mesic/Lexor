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
    public class CountriesController : BaseCRUDController<CountryResponse, CountrySearchObject, ICountryService, CountryInsertRequest, CountryUpdateRequest>
    {
        public CountriesController(ICountryService countryService) : base(countryService)
        {

        }

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<CountryResponse>> Create([FromBody] CountryInsertRequest request)
            => base.Create(request);

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<CountryResponse>> Update(int id, [FromBody] CountryUpdateRequest request)
            => base.Update(id, request);

        [Authorize(Roles =RoleNames.HrManager)]
        public override Task<ActionResult<CountryResponse>> Delete(int id)
            => base.Delete(id);
    }
}
