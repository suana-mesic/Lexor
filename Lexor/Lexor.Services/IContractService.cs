using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    public interface IContractService : IBaseCRUDService<ContractResponse, ContractSearchObject, ContractInsertRequest, ContractUpdateRequest>
    {
    }
}
