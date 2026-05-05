using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;

namespace Lexor.WebAPI.Controllers
{
    public class PositionsController : BaseCRUDController<PositionResponse, PositionSearchObject, IPositionService, PositionInsertRequest, PositionUpdateRequest>
    {
        public PositionsController(IPositionService PositionService) : base(PositionService)
        {

        }
    }
}
