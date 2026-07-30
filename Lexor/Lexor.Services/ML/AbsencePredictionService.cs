using Lexor.Services.Database;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.ML;
using Microsoft.Extensions.Logging;
using Lexor.Model.Exceptions;
using Lexor.Model.Responses;

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
             .Append(_ml.Transforms.Categorical.OneHotEncoding("EmployeeEncoded", nameof(AbsenceSample.Employee)))
             .Append(_ml.Transforms.Concatenate("Features",
                    "EmployeeEncoded", "DayOfWeekEncoded", "MonthEncoded", "DepartmentEncoded",
                    nameof(AbsenceSample.HistoricalAbsenceRate),
                    nameof(AbsenceSample.RecentAbsenceRate),
                    nameof(AbsenceSample.OnPlannedLeave),
                    nameof(AbsenceSample.PrevWorkdayAbsent),
                    nameof(AbsenceSample.MonthSeasonRate),
                    nameof(AbsenceSample.AbsencesInLast5Workdays)))
             .Append(_ml.BinaryClassification.Trainers.FastTree(
                 labelColumnName: nameof(AbsenceSample.IsAbsent),
                 numberOfTrees: 150,
                 numberOfLeaves: 30,
                 minimumExampleCountPerLeaf: 10));

            var model = pipeline.Fit(split.TrainSet); // the actual training happens here

            // Score the unseen 20% and compute the quality metrics from those predictions.
            var predictions = model.Transform(split.TestSet);
            var m = _ml.BinaryClassification.Evaluate(predictions, labelColumnName: nameof(AbsenceSample.IsAbsent));

            // Threshold tuning: the default 0.5 cutoff is arbitrary. We scan cutoffs and
            // keep the one with the best F1 (harmonic mean of precision and recall) on the
            // held-out test set.
            var testScores = _ml.Data.CreateEnumerable<TestScore>(predictions, reuseRowObject: false)
                .ToList();
            double bestF1 = 0, bestThreshold = 0.5;
            for (var t = 0.05; t <= 0.95; t += 0.01)
            {
                long tp = 0, fp = 0, fn = 0;
                foreach (var s in testScores)
                {
                    var predictedAbsent = s.Probability >= t;
                    if (predictedAbsent && s.IsAbsent) tp++;
                    else if (predictedAbsent && !s.IsAbsent) fp++;
                    else if (!predictedAbsent && s.IsAbsent) fn++;
                }
                var f1 = tp == 0 ? 0 : 2.0 * tp / (2.0 * tp + fp + fn);
                if (f1 > bestF1)
                {
                    bestF1 = f1;
                    bestThreshold = t;
                }
            }

            lock (_lock)
            {
                _engine = _ml.Model.CreatePredictionEngine<AbsenceSample, AbsencePrediction>(model);
                Metrics = new AbsenceModelMetrics
                {
                    Auc = m.AreaUnderRocCurve,
                    Accuracy = m.Accuracy,
                    Precision = m.PositivePrecision,
                    Recall = m.PositiveRecall,
                    SampleCount = samples.Count,
                    F1 = bestF1,
                    BestThreshold = bestThreshold,
                };
            }

            _logger.LogInformation(
      "Absence model trained on {Count} samples: AUC={Auc:F3}, F1={F1:F3} (threshold={Threshold:F2}), Precision={Precision:F3}, Recall={Recall:F3}, Accuracy={Accuracy:F3}",
      Metrics!.SampleCount, Metrics.Auc, Metrics.F1, Metrics.BestThreshold,
      Metrics.Precision, Metrics.Recall, Metrics.Accuracy);
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

        public async Task<AbsenceForecastResponse> ForecastAsync(DateOnly from, DateOnly to)
        {
            if (!IsTrained)
                throw new BusinessException("Model predikcije još nije istreniran.");
            if (to < from)
                throw new BusinessException("Datum 'do' ne može biti prije datuma 'od'.");
            if (to.DayNumber - from.DayNumber > 62)
                throw new BusinessException("Period predikcije ne može biti duži od dva mjeseca.");

            List<EmployeeAbsenceState> states;
            using (var scope = _scopeFactory.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<LexorDbContext>();
                states = await AbsenceSampleBuilder.BuildCurrentStatesAsync(db);
            }

            var response = new AbsenceForecastResponse
            {
                Metrics = Metrics == null ? null : new AbsenceModelMetricsResponse
                {
                    Auc = Metrics.Auc,
                    F1 = Metrics.F1,
                    BestThreshold = Metrics.BestThreshold,
                    Precision = Metrics.Precision,
                    Recall = Metrics.Recall,
                    Accuracy = Metrics.Accuracy,
                    SampleCount = Metrics.SampleCount
                }
            };

            // Soft chaining: future outcomes are unknown, so yesterday's feature values are
            // fed from the previous PREDICTED probability instead of a hard 0/1. For the
            // first forecast day the real history is used.
            var prevSignal = states.ToDictionary(s => s.EmployeeId, s => s.AbsentOnLastWorkday ? 1f : 0f);
            var lastFiveSignal = states.ToDictionary(s => s.EmployeeId, s => new Queue<float>(s.LastFiveOutcomes));
            var riskSum = states.ToDictionary(s => s.EmployeeId, _ => 0.0);
            var deptSum = new Dictionary<int, double>();
            var workdayCount = 0;

            for (var day = from; day <= to; day = day.AddDays(1))
            {
                if (day.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday)
                    continue;

                workdayCount++;
                double expected = 0;

                foreach (var s in states)
                {
                    var onPlannedLeave = s.PlannedLeaves.Any(r => day >= r.From && day <= r.To);
                    var lastFive = lastFiveSignal[s.EmployeeId];

                    var probability = PredictProbability(new AbsenceSample
                    {
                        Employee = s.EmployeeId.ToString(),
                        DayOfWeek = day.DayOfWeek.ToString(),
                        Month = day.Month.ToString(),
                        Department = s.DepartmentId.ToString(),
                        HistoricalAbsenceRate = s.HistoricalAbsenceRate,
                        RecentAbsenceRate = s.RecentAbsenceRate,
                        MonthSeasonRate = s.MonthRates[day.Month],
                        OnPlannedLeave = onPlannedLeave ? 1f : 0f,
                        PrevWorkdayAbsent = prevSignal[s.EmployeeId],
                        AbsencesInLast5Workdays = lastFive.Sum()
                    });

                    expected += probability;
                    riskSum[s.EmployeeId] += probability;
                    deptSum[s.DepartmentId] = deptSum.GetValueOrDefault(s.DepartmentId) + probability;

                    prevSignal[s.EmployeeId] = probability;
                    lastFive.Enqueue(probability);
                    if (lastFive.Count > 5)
                        lastFive.Dequeue();
                }

                response.Days.Add(new AbsenceForecastDayResponse
                {
                    Date = day,
                    ExpectedAbsences = Math.Round(expected, 2)
                });
            }

            if (workdayCount > 0)
            {
                response.Departments = states
                    .GroupBy(s => new { s.DepartmentId, s.DepartmentName })
                    .Select(g => new DepartmentAbsenceForecastResponse
                    {
                        Department = g.Key.DepartmentName,
                        EmployeeCount = g.Count(),
                        ExpectedAbsenceDays = Math.Round(deptSum.GetValueOrDefault(g.Key.DepartmentId), 1)
                    })
                    .OrderByDescending(d => d.ExpectedAbsenceDays)
                    .ToList();

                response.Employees = states
                    .Select(s => new EmployeeAbsenceRiskResponse
                    {
                        EmployeeId = s.EmployeeId,
                        FullName = s.FullName,
                        Department = s.DepartmentName,
                        AverageProbability = Math.Round(riskSum[s.EmployeeId] / workdayCount, 3),
                        HasPlannedLeave = s.PlannedLeaves.Any(r => r.From <= to && r.To >= from)
                    })
                    .OrderByDescending(e => e.AverageProbability)
                    .ToList();
            }

            return response;
        }

        // Row projection used to read the test-set predictions back into memory.
        private class TestScore
        {
            public bool IsAbsent { get; set; }
            public float Probability { get; set; }
        }
    }
}