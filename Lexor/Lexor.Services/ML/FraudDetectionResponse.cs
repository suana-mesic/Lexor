namespace Lexor.Services.ML
{
    // Everything the fraud-detection screen needs: the metrics plus the flagged records.
    public class FraudDetectionResponse
    {
        public FraudMetricsResponse Metrics { get; set; } = new();
        public List<FraudFlagResponse> DetectedFrauds { get; set; } = new();
    }

    // One attendance record the model flagged as fraud.
    public class FraudFlagResponse
    {
        public DateOnly Date { get; set; }       // charts group by this (month, day of week)
        public int EmployeeId { get; set; }
        public bool ActuallyFraud { get; set; }  // ground-truth label, for context
    }
}
