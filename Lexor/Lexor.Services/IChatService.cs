using Lexor.Model.Requests;
using Lexor.Model.Responses;

namespace Lexor.Services
{
    public interface IChatService
    {
        Task<ChatResponse> AskAsync(ChatRequest request);
        Task<PageResult<ChatMessageResponse>> GetHistoryAsync(int page, int pageSize);
    }
}
