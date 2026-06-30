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

Map<String, dynamic> _$PayrollSettingsResponseToJson(
  PayrollSettingsResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'validFrom': instance.validFrom.toIso8601String(),
  'validTo': instance.validTo?.toIso8601String(),
  'workDaysDescription': instance.workDaysDescription,
  'workDaysMask': instance.workDaysMask,
  'overtimeMultiplier': instance.overtimeMultiplier,
  'personalDeduction': instance.personalDeduction,
  'pioMioRate': instance.pioMioRate,
  'healthInsuranceRate': instance.healthInsuranceRate,
  'unemploymentRate': instance.unemploymentRate,
  'incomeTaxRate': instance.incomeTaxRate,
};
