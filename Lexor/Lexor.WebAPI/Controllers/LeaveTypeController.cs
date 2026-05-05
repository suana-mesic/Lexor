using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;

namespace Lexor.WebAPI.Controllers
{
    public class LeaveTypesController : BaseCRUDController<LeaveTypeResponse, LeaveTypeSearchObject, ILeaveTypeService, LeaveTypeInsertRequest, LeaveTypeUpdateRequest>
    {
        public LeaveTypesController(ILeaveTypeService LeaveTypeservice) : base(LeaveTypeservice)
        {

        }
    }
}
