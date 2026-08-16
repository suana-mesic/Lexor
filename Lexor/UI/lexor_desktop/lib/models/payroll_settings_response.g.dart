// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_settings_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PayrollSettingsResponse _$PayrollSettingsResponseFromJson(
  Map<String, dynamic> json,
) => PayrollSettingsResponse(
  id: (json['id'] as num).toInt(),
  validFrom: DateTime.parse(json['validFrom'] as String),
  validTo: json['validTo'] == null
      ? null
      : DateTime.parse(json['validTo'] as String),
  workDaysDescription: json['workDaysDescription'] as String,
  workDaysMask: (json['workDaysMask'] as num).toInt(),
  overtimeMultiplier: (json['overtimeMultiplier'] as num).toDouble(),
  personalDeduction: (json['personalDeduction'] as num).toDouble(),
  pioMioRate: (json['pioMioRate'] as num).toDouble(),
  healthInsuranceRate: (json['healthInsuranceRate'] as num).toDouble(),
  unemploymentRate: (json['unemploymentRate'] as num).toDouble(),
  incomeTaxRate: (json['incomeTaxRate'] as num).toDouble(),
);
