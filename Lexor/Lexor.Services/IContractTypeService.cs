using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    // ContractType service contract. Currently extends only generic CRUD,
    // but reserved for ContractType-specific methods.
    public interface IContractTypeService : IBaseCRUDService<ContractTypeResponse, ContractTypeSearchObject, ContractTypeInsertRequest, ContractTypeUpdateRequest>
    {
    }
}
