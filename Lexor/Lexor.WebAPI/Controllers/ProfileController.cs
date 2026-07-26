using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services;
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

        public ProfileController(IEmployeeService employeeService)
        {
            _employeeService = employeeService;
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
    }
}
