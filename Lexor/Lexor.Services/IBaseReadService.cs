using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    public interface IBaseReadService<TResponse, TSearch>
          where TSearch : BaseSearchObject
    {
        Task<TResponse> GetByIdAsync(int id);
        Task<PageResult<TResponse>> GetAllAsync(TSearch? search=null);
    }
}
