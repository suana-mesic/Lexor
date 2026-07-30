using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services;
using Lexor.Services.Access;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    // Employee self-service profile (the admin CRUD lives in EmployeesController).
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = RoleNames.Employee)]
    public class ProfileController : ControllerBase
    {
        private readonly IEmployeeService _employeeService;
        private readonly IAccessManager _accessManager;

        public ProfileController(IEmployeeService employeeService, IAccessManager accessManager)
        {
            _employeeService = employeeService;
            _accessManager = accessManager;
        }

        [HttpGet]
        public async Task<ActionResult<EmployeeResponse>> GetMyProfile()
        {
            var result = await _employeeService.GetMyProfileAsync();
            return Ok(result);
        }

        [HttpPut]
        public async Task<ActionResult<EmployeeResponse>> UpdateMyProfile([FromBody] ProfileUpdateRequest request)
        {
            var result = await _employeeService.UpdateMyProfileAsync(request);
            return Ok(result);
        }

        [HttpPut("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            await _accessManager.ChangePasswordAsync(request);
            return NoContent();
        }
    }
}
