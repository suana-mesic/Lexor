class AbsenceForecastResponse {
  final List<AbsenceForecastDay> days;
  final List<DepartmentAbsenceForecast> departments;
  final List<EmployeeAbsenceRisk> employees;
  final AbsenceModelMetrics? metrics;

  AbsenceForecastResponse({
    required this.days,
    required this.departments,
    required this.employees,
    this.metrics,
  });

  factory AbsenceForecastResponse.fromJson(Map<String, dynamic> json) {
    return AbsenceForecastResponse(
      days: (json['days'] as List? ?? [])
          .map((e) => AbsenceForecastDay.fromJson(e))
          .toList(),
      departments: (json['departments'] as List? ?? [])
          .map((e) => DepartmentAbsenceForecast.fromJson(e))
          .toList(),
      employees: (json['employees'] as List? ?? [])
          .map((e) => EmployeeAbsenceRisk.fromJson(e))
          .toList(),
      metrics: json['metrics'] == null
          ? null
          : AbsenceModelMetrics.fromJson(json['metrics']),
    );
  }
}

class AbsenceForecastDay {
  final DateTime date;
  final double expectedAbsences;

  AbsenceForecastDay({required this.date, required this.expectedAbsences});

  factory AbsenceForecastDay.fromJson(Map<String, dynamic> json) =>
      AbsenceForecastDay(
        date: DateTime.parse(json['date'] as String),
        expectedAbsences: (json['expectedAbsences'] as num).toDouble(),
      );
}

class DepartmentAbsenceForecast {
  final String department;
  final int employeeCount;
  final double expectedAbsenceDays;

  DepartmentAbsenceForecast({
    required this.department,
    required this.employeeCount,
    required this.expectedAbsenceDays,
  });

  factory DepartmentAbsenceForecast.fromJson(Map<String, dynamic> json) =>
      DepartmentAbsenceForecast(
        department: json['department'] as String? ?? '',
        employeeCount: json['employeeCount'] as int? ?? 0,
        expectedAbsenceDays: (json['expectedAbsenceDays'] as num).toDouble(),
      );
}

class EmployeeAbsenceRisk {
  final int employeeId;
  final String fullName;
  final String department;
  final double averageProbability;
  final bool hasPlannedLeave;

  EmployeeAbsenceRisk({
    required this.employeeId,
    required this.fullName,
    required this.department,
    required this.averageProbability,
    required this.hasPlannedLeave,
  });

  factory EmployeeAbsenceRisk.fromJson(Map<String, dynamic> json) =>
      EmployeeAbsenceRisk(
        employeeId: json['employeeId'] as int? ?? 0,
        fullName: json['fullName'] as String? ?? '',
        department: json['department'] as String? ?? '',
        averageProbability: (json['averageProbability'] as num).toDouble(),
        hasPlannedLeave: json['hasPlannedLeave'] as bool? ?? false,
      );
}

class AbsenceModelMetrics {
  final double auc;
  final double f1;
  final double bestThreshold;
  final double precision;
  final double recall;
  final double accuracy;
  final int sampleCount;

  AbsenceModelMetrics({
    required this.auc,
    required this.f1,
    required this.bestThreshold,
    required this.precision,
    required this.recall,
    required this.accuracy,
    required this.sampleCount,
  });

  factory AbsenceModelMetrics.fromJson(Map<String, dynamic> json) =>
      AbsenceModelMetrics(
        auc: (json['auc'] as num).toDouble(),
        f1: (json['f1'] as num).toDouble(),
        bestThreshold: (json['bestThreshold'] as num).toDouble(),
        precision: (json['precision'] as num).toDouble(),
        recall: (json['recall'] as num).toDouble(),
        accuracy: (json['accuracy'] as num).toDouble(),
        sampleCount: json['sampleCount'] as int? ?? 0,
      );
}
