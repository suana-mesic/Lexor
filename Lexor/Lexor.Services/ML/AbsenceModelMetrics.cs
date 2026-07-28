namespace Lexor.Services.ML
{
    /// <summary>
    /// Quality metrics of the trained model, measured on the held-out 20% test set.
    /// </summary>
    public class AbsenceModelMetrics
    {
        public double Auc { get; set; }
        public double Accuracy { get; set; }
        public double Precision { get; set; }
        public double Recall { get; set; }
        public int SampleCount { get; set; }
    }
}
