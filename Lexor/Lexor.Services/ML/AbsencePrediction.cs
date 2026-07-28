using Microsoft.ML.Data;

namespace Lexor.Services.ML
{
    /// <summary>
    /// Model output for one sample.
    /// </summary>
    public class AbsencePrediction
    {
        // Raw yes/no decision (probability >= 0.5).
        [ColumnName("PredictedLabel")]
        public bool WillBeAbsent { get; set; }

        // Probability of absence (0..1) - this is what we actually use in the UI.
        public float Probability { get; set; }
    }
}
