using Azure;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    // Country service contract. Currently extends only generic CRUD,
    // but reserved for Country-specific methods (e.g. GetByIsoCodeAsync).
    public interface ICountryService : IBaseCRUDService<CountryResponse, CountrySearchObject, CountryInsertRequest, CountryUpdateRequest>
    {
    }
}
