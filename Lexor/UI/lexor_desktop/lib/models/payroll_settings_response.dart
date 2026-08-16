import 'package:json_annotation/json_annotation.dart';

part 'payroll_settings_response.g.dart';

@JsonSerializable(createToJson: false)
class PayrollSettingsResponse {
  int id;
  DateTime validFrom;
  DateTime? validTo;
  String workDaysDescription;
  int workDaysMask;
  double overtimeMultiplier;
  double personalDeduction;
  double pioMioRate;
  double healthInsuranceRate;
  double unemploymentRate;
  double incomeTaxRate;

  PayrollSettingsResponse({
    required this.id,
    required this.validFrom,
    this.validTo,
    required this.workDaysDescription,
    required this.workDaysMask,
    required this.overtimeMultiplier,
    required this.personalDeduction,
    required this.pioMioRate,
    required this.healthInsuranceRate,
    required this.unemploymentRate,
    required this.incomeTaxRate,
  });

  factory PayrollSettingsResponse.fromJson(Map<String, dynamic> json) =>
      _$PayrollSettingsResponseFromJson(json);
}
