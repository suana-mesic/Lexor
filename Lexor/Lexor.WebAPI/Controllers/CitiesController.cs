using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;

namespace Lexor.WebAPI.Controllers
{
    public class CitiesController : BaseCRUDController<CityResponse, CitySearchObject, ICityService, CityInsertRequest, CityUpdateRequest>
    {
        public CitiesController(ICityService cityService) : base(cityService)
        {

        }
    }
}
