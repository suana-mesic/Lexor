using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    // Role service contract. Currently extends only generic CRUD,
    // but reserved for Role-specific methods (e.g. GetByIsoCodeAsync).
    public interface IRoleService : IBaseCRUDService<RoleResponse, RoleSearchObject, RoleInsertRequest, RoleUpdateRequest>
    {
    }
}
