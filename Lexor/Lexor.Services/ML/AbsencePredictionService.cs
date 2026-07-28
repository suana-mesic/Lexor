using Lexor.Services.Database;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.ML;
using Microsoft.Extensions.Logging;

namespace Lexor.Services.ML
{
    /// <summary>
    /// Trains and serves the absence-prediction model (FastTree binary classification).
    /// Registered as a singleton so the trained model stays in memory and is shared by
    /// all requests; the scoped DbContext is resolved through a scope during training.
    /// </summary>
    public class AbsencePredictionService : IAbsencePredictionService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<AbsencePredictionService> _logger;
        private readonly MLContext _ml = new(seed: 1); // fixed seed -> reproducible results

        private readonly object _lock = new();

        private PredictionEngine<AbsenceSample, AbsencePrediction>? _engine;

        public AbsencePredictionService(IServiceScopeFactory scopeFactory, ILogger<AbsencePredictionService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        public bool IsTrained => _engine != null;

        public AbsenceModelMetrics? Metrics { get; private set; }

        public async Task TrainAsync()
        {
            List<AbsenceSample> samples;
            using (var scope = _scopeFactory.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<LexorDbContext>();
                samples = await AbsenceSampleBuilder.BuildAsync(db);
            }

            if (samples.Count < 100)
                return; // not enough history to learn anything useful

            var data = _ml.Data.LoadFromEnumerable(samples);

            // Hold out 20% of the samples. The model never sees them during training, so
            // evaluating on them shows how it performs on data it has not memorized.
            var split = _ml.Data.TrainTestSplit(data, testFraction: 0.2, seed: 1);

            var pipeline = _ml.Transforms.Categorical
                 .OneHotEncoding("DayOfWeekEncoded", nameof(AbsenceSample.DayOfWeek))
             .Append(_ml.Transforms.Categorical.OneHotEncoding("MonthEncoded", nameof(AbsenceSample.Month)))
             .Append(_ml.Transforms.Categorical.OneHotEncoding("DepartmentEncoded", nameof(AbsenceSample.Department)))
             .Append(_ml.Transforms.Concatenate("Features",
                 "DayOfWeekEncoded", "MonthEncoded", "DepartmentEncoded",
                 nameof(AbsenceSample.HistoricalAbsenceRate),
                 nameof(AbsenceSample.RecentAbsenceRate),
                 nameof(AbsenceSample.OnApprovedLeave),
                 nameof(AbsenceSample.PrevWorkdayAbsent)))
             .Append(_ml.BinaryClassification.Trainers.FastTree(
                 labelColumnName: nameof(AbsenceSample.IsAbsent),
                 numberOfTrees: 100,
                 numberOfLeaves: 20,
                 minimumExampleCountPerLeaf: 10));

            var model = pipeline.Fit(split.TrainSet); // the actual training happens here

            // Score the unseen 20% and compute the quality metrics from those predictions.
            var predictions = model.Transform(split.TestSet);
            var m = _ml.BinaryClassification.Evaluate(predictions, labelColumnName: nameof(AbsenceSample.IsAbsent));

            lock (_lock)
            {
                _engine = _ml.Model.CreatePredictionEngine<AbsenceSample, AbsencePrediction>(model);
                Metrics = new AbsenceModelMetrics
                {
                    Auc = m.AreaUnderRocCurve,
                    Accuracy = m.Accuracy,
                    Precision = m.PositivePrecision,
                    Recall = m.PositiveRecall,
                    SampleCount = samples.Count
                };
            }

            _logger.LogInformation(
            "Absence model trained on {Count} samples: AUC={Auc:F3}, Accuracy={Accuracy:F3}, Precision={Precision:F3}, Recall={Recall:F3}",
            Metrics!.SampleCount, Metrics.Auc, Metrics.Accuracy, Metrics.Precision, Metrics.Recall);
        }
        public float PredictProbability(AbsenceSample sample)
        {
            lock (_lock) // PredictionEngine is not thread-safe
            {
                if (_engine == null)
                    throw new InvalidOperationException("The absence model has not been trained yet.");

                return _engine.Predict(sample).Probability;
            }
        }
    }
}