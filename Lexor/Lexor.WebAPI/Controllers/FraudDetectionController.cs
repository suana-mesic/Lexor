using Lexor.Model.Constants;
using Lexor.Services.ML;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Lexor.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    // Attendance fraud oversight: HR investigates, the administrator supervises.
    [Authorize(Roles = $"{RoleNames.HrManager},{RoleNames.Administrator}")]
    public class FraudDetectionController : ControllerBase
    {
        private readonly IFraudDetectionService _fraudDetection;

        public FraudDetectionController(IFraudDetectionService fraudDetection)
        {
            _fraudDetection = fraudDetection;
        }

        // Returns the model's train/test metrics plus every record it flagged as fraud.
        [HttpGet]
        public ActionResult<FraudDetectionResponse> Get()
        {
            return Ok(new FraudDetectionResponse
            {
                Metrics = _fraudDetection.Metrics ?? new FraudMetricsResponse(),
                DetectedFrauds = _fraudDetection.DetectedFrauds
            });
        }
    }
}
