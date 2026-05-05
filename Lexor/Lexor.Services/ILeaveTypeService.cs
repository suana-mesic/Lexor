using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    // LeaveType service contract. Currently extends only generic CRUD,
    // but reserved for LeaveType-specific methods (e.g. GetByIsoCodeAsync).
    public interface ILeaveTypeService : IBaseCRUDService<LeaveTypeResponse, LeaveTypeSearchObject, LeaveTypeInsertRequest, LeaveTypeUpdateRequest>
    {
    }
}
