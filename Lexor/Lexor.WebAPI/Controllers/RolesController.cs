using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;

namespace Lexor.WebAPI.Controllers
{
    public class RolesController : BaseCRUDController<RoleResponse, RoleSearchObject, IRoleService, RoleInsertRequest, RoleUpdateRequest>
    {
        public RolesController(IRoleService RoleService) : base(RoleService)
        {

        }
    }
}
