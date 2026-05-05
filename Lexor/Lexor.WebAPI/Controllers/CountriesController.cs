using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;

namespace Lexor.WebAPI.Controllers
{
    public class CountriesController : BaseCRUDController<CountryResponse, CountrySearchObject, ICountryService, CountryInsertRequest, CountryUpdateRequest>
    {
        public CountriesController(ICountryService countryService) : base(countryService)
        {

        }
    }
}
