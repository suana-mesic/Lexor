using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    [Authorize(Roles = RoleNames.Administrator)]
    public class UsersController : BaseReadController<UserResponse, UserSearchObject, IUserService>
    {
        public UsersController(IUserService service) : base(service)
        {
        }

        [HttpPut("{id}/role")]
        public Task<UserResponse> ChangeRole(int id, [FromBody] ChangeUserRoleRequest request)
            => _service.ChangeRoleAsync(id, request);

        [HttpPatch("{id}/activate")]
        public Task<UserResponse> Activate(int id) => _service.SetActiveAsync(id, true);

        [HttpPatch("{id}/deactivate")]
        public Task<UserResponse> Deactivate(int id) => _service.SetActiveAsync(id, false);

        [HttpGet("stats")]
        public Task<AdminStatsResponse> Stats() => _service.GetStatsAsync();
    }
}
