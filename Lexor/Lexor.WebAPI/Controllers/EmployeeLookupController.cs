using Lexor.Model.Constants;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    /// <summary>
    /// Lightweight id + name list of employees for autocomplete/dropdown pickers. Available to
    /// every back-office role because they all have screens that pick an employee (accounting →
    /// reports, admin → RFID cards), unlike the full Employees CRUD which is HR-only. Exposes
    /// only the display name, no other personal data.
    /// </summary>
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = $"{RoleNames.HrManager},{RoleNames.Accounting},{RoleNames.Administrator}")]
    public class EmployeeLookupController : ControllerBase
    {
        private readonly IEmployeeService _service;

        public EmployeeLookupController(IEmployeeService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<List<EmployeeOptionResponse>> Get()
        {
            var page = await _service.GetAllAsync(new EmployeeSearchObject
            {
                Page = 1,
                PageSize = 10000,
                IncludeTotalCount = false,
            });

            return page.Items
                .Select(e => new EmployeeOptionResponse
                {
                    Id = e.Id,
                    FullName = $"{e.User.FirstName} {e.User.LastName}".Trim(),
                })
                .ToList();
        }
    }
}
