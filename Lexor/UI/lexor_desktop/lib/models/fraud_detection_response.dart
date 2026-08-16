/// Result of the attendance fraud-detection model as returned by the API:
/// train/test evaluation metrics plus every record the model flagged as fraud.
class FraudDetectionResponse {
  final FraudMetrics metrics;
  final List<FraudFlag> detectedFrauds;

  FraudDetectionResponse({required this.metrics, required this.detectedFrauds});

  factory FraudDetectionResponse.fromJson(Map<String, dynamic> json) =>
      FraudDetectionResponse(
        metrics: FraudMetrics.fromJson(json['metrics'] as Map<String, dynamic>? ?? {}),
        detectedFrauds: (json['detectedFrauds'] as List? ?? [])
            .map((e) => FraudFlag.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Metrics for both splits: how the model does on the data it learned from
/// (train) versus unseen future data (test).
class FraudMetrics {
  final FraudSplitMetrics train;
  final FraudSplitMetrics test;

  FraudMetrics({required this.train, required this.test});

  factory FraudMetrics.fromJson(Map<String, dynamic> json) => FraudMetrics(
        train: FraudSplitMetrics.fromJson(json['train'] as Map<String, dynamic>? ?? {}),
        test: FraudSplitMetrics.fromJson(json['test'] as Map<String, dynamic>? ?? {}),
      );
}

/// Evaluation metrics of one split. The "positive" class is fraud.
class FraudSplitMetrics {
  final double f1Score;
  final double accuracy;
  final double precision;
  final double recall;
  final double areaUnderRocCurve;
  final int sampleCount;
  final int fraudCount;

  FraudSplitMetrics({
    required this.f1Score,
    required this.accuracy,
    required this.precision,
    required this.recall,
    required this.areaUnderRocCurve,
    required this.sampleCount,
    required this.fraudCount,
  });

  factory FraudSplitMetrics.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => (v as num?)?.toDouble() ?? 0;
    return FraudSplitMetrics(
      f1Score: d(json['f1Score']),
      accuracy: d(json['accuracy']),
      precision: d(json['precision']),
      recall: d(json['recall']),
      areaUnderRocCurve: d(json['areaUnderRocCurve']),
      sampleCount: json['sampleCount'] as int? ?? 0,
      fraudCount: json['fraudCount'] as int? ?? 0,
    );
  }
}

/// One attendance record the model flagged as fraud.
class FraudFlag {
  final DateTime date; // charts group by this (month, day of week)
  final int employeeId;
  final bool actuallyFraud; // ground-truth label, for context

  FraudFlag({
    required this.date,
    required this.employeeId,
    required this.actuallyFraud,
  });

  factory FraudFlag.fromJson(Map<String, dynamic> json) => FraudFlag(
        // DateOnly serializes as "yyyy-MM-dd".
        date: DateTime.parse(json['date'] as String),
        employeeId: json['employeeId'] as int? ?? 0,
        actuallyFraud: json['actuallyFraud'] as bool? ?? false,
      );
}
