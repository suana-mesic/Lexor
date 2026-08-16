namespace Lexor.Services.ML
{
    public class FraudSplitMetrics
    {
        public double F1Score { get; set; }            // balance of precision and recall
        public double Accuracy { get; set; }           // share of all rows classified correctly
        public double Precision { get; set; }          // of the rows flagged as fraud, how many really are
        public double Recall { get; set; }             // of the real frauds, how many we caught
        public double AreaUnderRocCurve { get; set; }  // separability across all thresholds (AUC)
        public int SampleCount { get; set; }           // rows in this split
        public int FraudCount { get; set; }            // fraud rows in this split
    }

    // Full result: how the model does on the data it learned from vs unseen future data.
    public class FraudMetricsResponse
    {
        public FraudSplitMetrics Train { get; set; } = new();
        public FraudSplitMetrics Test { get; set; } = new();
    }
}
