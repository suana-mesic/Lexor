using Lexor.Services.Database;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.ML;
using Microsoft.ML.Data;

namespace Lexor.Services.ML
{

    public class FraudDetectionService : IFraudDetectionService
    {
        private readonly IServiceProvider _serviceProvider;

        private readonly MLContext _mlContext = new(seed: 0);  // fixed seed = reproducible runs

        private ITransformer? _model;
        public FraudMetricsResponse? Metrics { get; private set; }
        public List<FraudFlagResponse> DetectedFrauds { get; private set; } = new();
        public FraudDetectionService(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }

        public async Task TrainAsync()
        {
            // This service is a singleton; DbContext is scoped, so open a scope to get one.

            using var scope = _serviceProvider.CreateAsyncScope();
            var db = scope.ServiceProvider.GetRequiredService<LexorDbContext>();

            // Build all records (sample + date) in chronological order.
            var records = await FraudSampleBuilder.BuildAsync(db);
            if (records.Count == 0) return;

            // ----- Chronological 80/20 split: OLDER 80% trains, NEWER 20% tests -----
            // Using time (not random) prevents "future leaking into the past": we never let a
            // later record help predict an earlier one, which would be cheating.

            var splitIndex = (int)(records.Count * 0.8);
            var trainSamples = records.Take(splitIndex).Select(r => r.Sample).ToList();
            var testSamples = records.Skip(splitIndex).Select(r => r.Sample).ToList();

            // How many times more a fraud row counts than a normal row during training.
            // Higher -> catches more fraud but more false alarms (lower precision);
            // lower  -> fewer false alarms (higher precision). 
            const float fraudWeight = 4f;
            foreach (var s in trainSamples)
                s.Weight = s.IsFraud ? fraudWeight : 1f;


            // Load the lists into ML.NET's data view format.
            var trainData = _mlContext.Data.LoadFromEnumerable(trainSamples);
            var testData = _mlContext.Data.LoadFromEnumerable(testSamples);

            // ----- Pipeline: pack features -> normalize -> logistic regression -----
            var pipeline = _mlContext.Transforms
              // 1) Merge the 6 feature columns into a single "Features" vector.
              .Concatenate("Features",
                    nameof(FraudSample.ArrivalMinutes),
                    nameof(FraudSample.DepartureMinutes),
                    nameof(FraudSample.WorkedHours),
                    nameof(FraudSample.DepartureEditCount),
                    nameof(FraudSample.ArrivalDeviation),
                    nameof(FraudSample.DepartureDeviation))
                // 2) Scale every feature to [0,1] so no column dominates by unit (minutes vs count).
                // Fitted on train data only, so the test set never influences scaling.
                .Append(_mlContext.Transforms.NormalizeMinMax("Features"))
                   // 3) The model itself: logistic regression (binary classification).
                   .Append(_mlContext.BinaryClassification.Trainers.LbfgsLogisticRegression(
                    labelColumnName: nameof(FraudSample.IsFraud),
                    featureColumnName: "Features",
                    exampleWeightColumnName: nameof(FraudSample.Weight)));

            // Train the whole pipeline on the training split only.
            _model = pipeline.Fit(trainData);
            // Evaluate on BOTH splits so we can see the train->test generalization gap.
            Metrics = new FraudMetricsResponse
            {
                Train = Evaluate(trainData, trainSamples),
                Test = Evaluate(testData, testSamples)
            };

            // Run the trained model over EVERY record so the desktop can chart the detected frauds.
            DetectedFrauds = PredictFlags(records);
        }

        // Predicts over all records and returns those the model flags as fraud, with their dates.
        private List<FraudFlagResponse> PredictFlags(List<FraudRecord> records)
        {
            var data = _mlContext.Data.LoadFromEnumerable(records.Select(r => r.Sample).ToList());
            // "PredictedLabel" = the model's yes/no fraud decision for each row (same row order).
            var predicted = _model!.Transform(data).GetColumn<bool>("PredictedLabel").ToArray();

            var flags = new List<FraudFlagResponse>();
            for (var i = 0; i < records.Count; i++)
                if (predicted[i]) // model marked this record as fraud
                    flags.Add(new FraudFlagResponse
                    {
                        Date = records[i].Date,
                        EmployeeId = records[i].EmployeeId,
                        ActuallyFraud = records[i].Sample.IsFraud
                    });
            return flags;
        }
        // Runs the trained model over a split and reads out the standard metrics.
        private FraudSplitMetrics Evaluate(IDataView data, List<FraudSample> samples)
        {
            var predictions = _model!.Transform(data); // adds predicted label + probability columns
            var m = _mlContext.BinaryClassification.Evaluate(
                predictions,
                labelColumnName: nameof(FraudSample.IsFraud));

            return new FraudSplitMetrics
            {
                F1Score = m.F1Score,
                Accuracy = m.Accuracy,
                Precision = m.PositivePrecision, // precision for the fraud class
                Recall = m.PositiveRecall,       // recall for the fraud class
                AreaUnderRocCurve = m.AreaUnderRocCurve,
                SampleCount = samples.Count,
                FraudCount = samples.Count(s => s.IsFraud)
            };
        }
    }
}

