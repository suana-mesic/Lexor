import 'package:json_annotation/json_annotation.dart';

part 'salary_slip_response.g.dart';

@JsonSerializable()
class SalarySlipUser {
  final String firstName;
  final String lastName;
  SalarySlipUser({required this.firstName, required this.lastName});
  factory SalarySlipUser.fromJson(Map<String, dynamic> json) =>
      _$SalarySlipUserFromJson(json);
}

@JsonSerializable()
class SalarySlipEmployee {
  final int id;
  final SalarySlipUser user;
  SalarySlipEmployee({required this.id, required this.user});
  factory SalarySlipEmployee.fromJson(Map<String, dynamic> json) =>
      _$SalarySlipEmployeeFromJson(json);
}

@JsonSerializable()
class SalarySlipItem {
  final String name;
  final double? rate;
  final double amount;
  SalarySlipItem({required this.name, this.rate, required this.amount});
  factory SalarySlipItem.fromJson(Map<String, dynamic> json) =>
      _$SalarySlipItemFromJson(json);
}

@JsonSerializable()
class SalarySlipResponse {
  final int id;
  final SalarySlipEmployee employee;
  final int year;
  final int month;
  final double brutoSalary;
  final double totalContributions;
  final double taxBase;
  final double tax;
  final double netSalary;
  final int status;
  final List<SalarySlipItem>? items;

  SalarySlipResponse({
    required this.id,
    required this.employee,
    required this.year,
    required this.month,
    required this.brutoSalary,
    required this.totalContributions,
    required this.taxBase,
    required this.tax,
    required this.netSalary,
    required this.status,
    this.items,
  });

  String get employeeFullName =>
      '${employee.user.firstName} ${employee.user.lastName}';

  factory SalarySlipResponse.fromJson(Map<String, dynamic> json) =>
      _$SalarySlipResponseFromJson(json);
}
