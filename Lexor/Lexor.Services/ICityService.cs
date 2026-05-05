using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    // City service contract. Currently extends only generic CRUD,
    // but reserved for City-specific methods (e.g. GetByIsoCodeAsync).
    public interface ICityService : IBaseCRUDService<CityResponse, CitySearchObject, CityInsertRequest, CityUpdateRequest>
    {
    }
}
