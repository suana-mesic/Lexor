using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    // Department service contract. Currently extends only generic CRUD,
    // but reserved for Department-specific methods (e.g. GetByIsoCodeAsync).
    public interface IDepartmentService : IBaseCRUDService<DepartmentResponse, DepartmentSearchObject, DepartmentInsertRequest, DepartmentUpdateRequest>
    {
    }
}
