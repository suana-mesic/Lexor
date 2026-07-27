using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class ChatController : ControllerBase
    {
        private readonly IChatService _chatService;

        public ChatController(IChatService chatService)
        {
            _chatService = chatService;
        }

        [HttpPost("ask")]
        public async Task<ActionResult<ChatResponse>> Ask(ChatRequest request)
        {
            var response = await _chatService.AskAsync(request);
            return Ok(response);
        }

        [HttpGet("history")]
        public async Task<ActionResult<PageResult<ChatMessageResponse>>> History([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var history = await _chatService.GetHistoryAsync(page, pageSize);
            return Ok(history);
        }
    }
}