using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    public interface IEmployeeService : IBaseCRUDService<EmployeeResponse, EmployeeSearchObject, EmployeeInsertRequest, EmployeeUpdateRequest>
    {
        public Task<EmployeeResponse> DeactivateAsync(int id);
    }
}
