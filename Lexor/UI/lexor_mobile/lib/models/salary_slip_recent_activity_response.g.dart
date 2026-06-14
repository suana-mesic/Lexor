// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salary_slip_recent_activity_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalarySlipRecentActivityResponse _$SalarySlipRecentActivityResponseFromJson(
  Map<String, dynamic> json,
) => SalarySlipRecentActivityResponse(
  year: (json['year'] as num).toInt(),
  month: (json['month'] as num).toInt(),
  netSalary: (json['netSalary'] as num).toDouble(),
  generatedAt: DateTime.parse(json['generatedAt'] as String),
  status: (json['status'] as num).toInt(),
);

Map<String, dynamic> _$SalarySlipRecentActivityResponseToJson(
  SalarySlipRecentActivityResponse instance,
) => <String, dynamic>{
  'year': instance.year,
  'month': instance.month,
  'netSalary': instance.netSalary,
  'generatedAt': instance.generatedAt.toIso8601String(),
  'status': instance.status,
};
