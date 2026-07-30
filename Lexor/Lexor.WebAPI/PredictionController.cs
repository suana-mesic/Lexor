using Lexor.Model.Constants;
using Lexor.Model.Responses;
using Lexor.Services.ML;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = RoleNames.Administrator)]
    public class PredictionController : ControllerBase
    {
        private readonly IAbsencePredictionService _predictionService;

        public PredictionController(IAbsencePredictionService predictionService)
        {
            _predictionService = predictionService;
        }

        // Absence forecast for a period: expected absences per day, per department,
        // and a per-employee risk list.
        [HttpGet("absences")]
        public async Task<ActionResult<AbsenceForecastResponse>> GetAbsenceForecast(
            [FromQuery] DateOnly from, [FromQuery] DateOnly to)
        {
            return await _predictionService.ForecastAsync(from, to);
        }
    }
}