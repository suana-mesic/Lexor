using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.Extensions.FileProviders;

namespace Lexor.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class BaseReadController<TResponse, TSearch, TService> : ControllerBase
        where TSearch : BaseSearchObject
        where TService : IBaseReadService<TResponse, TSearch>
    {
        protected readonly TService _service;

        public BaseReadController(TService service)
        {
            _service = service;
        }

        [HttpGet]
        public virtual async Task<PageResult<TResponse>> GetAllAsync([FromQuery] TSearch? search = default)
        {
            var result = await _service.GetAllAsync(search);
            return result;
        }

        [HttpGet("{id}")]
        public virtual async Task<ActionResult<TResponse>> GetByIdAsync(int id)
        {
            try
            {
                var result = await _service.GetByIdAsync(id);
                return Ok(result);
            }
            catch(KeyNotFoundException)
            {
                return NotFound();
            }
        }
    }
}
