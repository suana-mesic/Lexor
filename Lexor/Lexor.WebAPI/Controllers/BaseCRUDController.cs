using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{

    public class BaseCRUDController<TResponse, TSearch, TService, TInsertRequest, TUpdateRequest> : BaseReadController<TResponse, TSearch, TService>
         where TSearch : BaseSearchObject
        where TService : IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest>
    {

        public BaseCRUDController(TService service) : base(service)
        {

        }

        [HttpPost]
        [ProducesResponseType(StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<TResponse>> Create([FromBody] TInsertRequest request)
        {
            var result = await _service.InsertAsync(request);
            return result;
        }


        [HttpPut("{id}")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<TResponse>> Update(int id, [FromBody] TUpdateRequest request)
        {
            var result = await _service.UpdateAsync(id, request);
            return result;
        }


        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<TResponse>> Delete(int id)
        {
            await _service.DeleteAsync(id);
            return NoContent();
        }

    }
}
