import 'package:json_annotation/json_annotation.dart';

part 'salary_slip_recent_activity_response.g.dart';

@JsonSerializable()
class SalarySlipRecentActivityResponse {
  final int year;
  final int month;
  final double netSalary;
  final DateTime generatedAt;
  final int status;

  SalarySlipRecentActivityResponse({
    required this.year,
    required this.month,
    required this.netSalary,
    required this.generatedAt,
    required this.status,
  });

  factory SalarySlipRecentActivityResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$SalarySlipRecentActivityResponseFromJson(json);
}
