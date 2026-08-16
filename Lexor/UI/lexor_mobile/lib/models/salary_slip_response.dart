import 'package:json_annotation/json_annotation.dart';

part 'salary_slip_response.g.dart';

@JsonSerializable(createToJson: false)
class SalarySlipUserResponse {
  final String firstName;
  final String lastName;

  SalarySlipUserResponse({required this.firstName, required this.lastName});

  factory SalarySlipUserResponse.fromJson(Map<String, dynamic> json) =>
      _$SalarySlipUserResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class SalarySlipEmployeeResponse {
  final SalarySlipUserResponse user;

  SalarySlipEmployeeResponse({required this.user});

  factory SalarySlipEmployeeResponse.fromJson(Map<String, dynamic> json) =>
      _$SalarySlipEmployeeResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class SalarySlipItemResponse {
  final int itemType;
  final String name;
  final String? description;
  final double? quantity;
  final double? rate;
  final double? multiplier;
  final double amount;

  SalarySlipItemResponse({
    required this.itemType,
    required this.name,
    this.description,
    this.quantity,
    this.rate,
    this.multiplier,
    required this.amount,
  });

  factory SalarySlipItemResponse.fromJson(Map<String, dynamic> json) =>
      _$SalarySlipItemResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class SalarySlipResponse {
  final int id;
  final int year;
  final int month;
  final double brutoSalary;
  final double adjustedBruto;
  final double totalContributions;
  final double taxBase;
  final double tax;
  final double netSalary;
  final int status;
  final DateTime generatedAt;
  final DateTime? paidAt;
  final SalarySlipEmployeeResponse employee;
  final List<SalarySlipItemResponse>? items;

  SalarySlipResponse({
    required this.id,
    required this.year,
    required this.month,
    required this.brutoSalary,
    required this.adjustedBruto,
    required this.totalContributions,
    required this.taxBase,
    required this.tax,
    required this.netSalary,
    required this.status,
    required this.generatedAt,
    this.paidAt,
    required this.employee,
    this.items,
  });
  String get employeeFullName =>
      '${employee.user.firstName} ${employee.user.lastName}';

  factory SalarySlipResponse.fromJson(Map<String, dynamic> json) =>
      _$SalarySlipResponseFromJson(json);
}
