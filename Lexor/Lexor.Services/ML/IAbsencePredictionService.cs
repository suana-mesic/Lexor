using Lexor.Model.Responses;

namespace Lexor.Services.ML
{
    public interface IAbsencePredictionService
    {
        bool IsTrained { get; }
        AbsenceModelMetrics? Metrics { get; }
        Task TrainAsync();
        float PredictProbability(AbsenceSample sample);
        Task<AbsenceForecastResponse> ForecastAsync(DateOnly from, DateOnly to);
    }
}
