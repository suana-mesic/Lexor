namespace Lexor.Services.ML
{
    public interface IFraudDetectionService
    {
        Task TrainAsync();                     // (re)trains the model and stores the metrics
        FraudMetricsResponse? Metrics { get; } // last computed train/test metrics
        List<FraudFlagResponse> DetectedFrauds { get; } // records the model flagged as fraud
    }
}
