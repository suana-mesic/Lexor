using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    [Authorize]
    public class SalarySlipsController : BaseReadController<SalarySlipResponse, SalarySlipCalculationSearchObject, ISalarySlipService>
    {
        public SalarySlipsController(ISalarySlipService salarySlipService) : base(salarySlipService)
        {
        }

        [Authorize(Roles = RoleNames.Administrator)]
        [HttpPost("recalculate-all")]
        public async Task<ActionResult<int>> RecalculateAllSalaries(SalarySlipAllRecalculationRequest request)
        {
            var count = await _service.RecalculateAllSalaries(request);
            return Ok(count);
        }

        [Authorize(Roles = RoleNames.Administrator)]
        [HttpPost("recalculate-single")]
        public async Task<ActionResult<SalarySlipResponse>> RecalculateSingleSalary(SalarySlipSingleRecalculationRequest request)
        {
            var response = await _service.RecalculateSingleSalary(request);
            return response;
        }

        [Authorize(Roles = RoleNames.Administrator)]
        [HttpPost("calculate")]
        public async Task<ActionResult<int>> InsertOrRecalculateSalaries(SalarySlipCalculationRequest request)
        {
            var count = await _service.InsertOrRecalculateSalaries(request);
            return Ok(count);
        }

        [Authorize(Roles = RoleNames.Administrator)]
        [HttpPost("mark-all-paid")]
        public async Task<ActionResult<int>> MarkAllAsPaid(SalarySlipPayAllRequest request)
        {
            var count = await _service.MarkAllSalariesAsPaid(request);
            return Ok(count);
        }

        [Authorize(Roles = RoleNames.Administrator)]
        [HttpPost("mark-single-paid")]
        public async Task<ActionResult<SalarySlipResponse>> MarkSingleAsPaid(SalarySlipPaySingleRequest request)
        {
            var response = await _service.MarkSingleSalaryAsPaid(request);
            return response;
        }

        [Authorize(Roles = RoleNames.Administrator)]
        [HttpPost("mark-all-approved")]
        public async Task<ActionResult<int>> MarkAllAsApproved(SalarySlipApproveAllRequest request)
        {
            var count = await _service.MarkAllSalariesAsApproved(request);
            return Ok(count);
        }

        [Authorize(Roles = RoleNames.Administrator)]
        [HttpPost("mark-single-approved")]
        public async Task<ActionResult<SalarySlipResponse>> MarkSingleAsApproved(SalarySlipApproveSingleRequest request)
        {
            var response = await _service.MarkSingleSalaryAsApproved(request);
            return response;
        }
    }
}
