using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    // Employee service contract. Currently extends only generic CRUD,
    // but reserved for Employee-specific methods (e.g. GetByIsoCodeAsync).
    public interface IEmployeeService : IBaseCRUDService<EmployeeResponse, EmployeeSearchObject, EmployeeInsertRequest, EmployeeUpdateRequest>
    {
    }
}
