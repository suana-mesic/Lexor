namespace Lexor.Services.ML
{
    public interface IAbsencePredictionService
    {
        bool IsTrained { get; }
        AbsenceModelMetrics? Metrics { get; }
        Task TrainAsync();
        float PredictProbability(AbsenceSample sample);
    }
}
