using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    public interface INewsService : IBaseCRUDService<NewsResponse, NewsSearchObject, NewsInsertRequest, NewsUpdateRequest>
    {
    }
}
