using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    // RFID service contract. Currently extends only generic CRUD,
    // but reserved for RFID-specific methods (e.g. GetByIsoCodeAsync).
    public interface IRFIDService : IBaseCRUDService<RFIDResponse, RFIDSearchObject, RFIDInsertRequest, RFIDUpdateRequest>
    {

    }
}
