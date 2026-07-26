using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationService _service;
        public NotificationsController(INotificationService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<ActionResult<PageResult<NotificationResponse>>> GetMy([FromQuery] NotificationSearchObject search) => Ok(await _service.GetAllAsync(search));

        [HttpGet("unread-count")]
        public async Task<ActionResult<int>> UnreadCount()
            => Ok(await _service.GetUnreadCountAsync());

        [HttpPut("{id}/read")]
        public async Task<ActionResult<NotificationResponse>> MarkRead(int id)
           => Ok(await _service.MarkAsReadAsync(id));

        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllRead()
        {
            await _service.MarkAllAsReadAsync();
            return NoContent();
        }
    }
}
