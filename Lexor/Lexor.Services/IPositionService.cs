using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    // Position service contract. Currently extends only generic CRUD,
    // but reserved for Position-specific methods (e.g. GetByIsoCodeAsync).
    public interface IPositionService : IBaseCRUDService<PositionResponse, PositionSearchObject, PositionInsertRequest, PositionUpdateRequest>
    {
    }
}
