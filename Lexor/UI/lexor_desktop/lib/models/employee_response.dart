import 'package:json_annotation/json_annotation.dart';
import 'package:lexor_shared/lexor_shared.dart';

part 'employee_response.g.dart';

@JsonSerializable()
class EmployeeUserResponse {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String email;
  final String? phoneNumber;
  final String? profileImageBase64;
  final bool isCodeActivated;

  EmployeeUserResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    required this.email,
    this.phoneNumber,
    this.profileImageBase64,
    required this.isCodeActivated,
  });

  String get fullName => '$firstName $lastName';

  factory EmployeeUserResponse.fromJson(Map<String, dynamic> json) =>
      _$EmployeeUserResponseFromJson(json);
}

@JsonSerializable()
class EmployeeCountryResponse {
  final int id;
  final String name;

  EmployeeCountryResponse({required this.id, required this.name});

  factory EmployeeCountryResponse.fromJson(Map<String, dynamic> json) =>
      _$EmployeeCountryResponseFromJson(json);
}

@JsonSerializable()
class EmployeeCityResponse {
  final int id;
  final String name;
  final EmployeeCountryResponse country;

  EmployeeCityResponse({
    required this.id,
    required this.name,
    required this.country,
  });

  factory EmployeeCityResponse.fromJson(Map<String, dynamic> json) =>
      _$EmployeeCityResponseFromJson(json);
}

@JsonSerializable()
class EmployeeDepartmentResponse {
  final int id;
  final String name;

  EmployeeDepartmentResponse({required this.id, required this.name});

  factory EmployeeDepartmentResponse.fromJson(Map<String, dynamic> json) =>
      _$EmployeeDepartmentResponseFromJson(json);
}

@JsonSerializable()
class EmployeePositionResponse {
  final int id;
  final String name;

  EmployeePositionResponse({required this.id, required this.name});

  factory EmployeePositionResponse.fromJson(Map<String, dynamic> json) =>
      _$EmployeePositionResponseFromJson(json);
}

/// Contract shape as embedded inside EmployeeResponse (flat — contractTypeName,
/// no employeeId, no nested contractType). Distinct from the top-level
/// ContractResponse returned by /Contracts.
@JsonSerializable()
class EmployeeContractResponse {
  final int id;
  final int contractTypeId;
  final String contractTypeName;
  final DateTime startDate;
  final DateTime? endDate;
  final double brutoSalary;
  final int workHoursPerDay;

  // Derived on the server from the date range; serialized as an int code (1/2/3).
  @JsonKey(name: 'status')
  final int statusCode;

  EmployeeContractResponse({
    required this.id,
    required this.contractTypeId,
    required this.contractTypeName,
    required this.startDate,
    this.endDate,
    required this.brutoSalary,
    required this.workHoursPerDay,
    required this.statusCode,
  });

  ContractStatus get status =>
      ContractStatus.fromCode(statusCode) ?? ContractStatus.active;

  factory EmployeeContractResponse.fromJson(Map<String, dynamic> json) =>
      _$EmployeeContractResponseFromJson(json);
}

@JsonSerializable()
class EmployeeResponse {
  final int id;
  final int userId;
  final EmployeeUserResponse user;
  final DateTime dateOfBirth;
  final String address;
  final EmployeeCityResponse? city;
  final EmployeeDepartmentResponse? department;
  final EmployeePositionResponse? position;
  final DateTime hireDate;
  final bool isActive;
  final List<EmployeeContractResponse> contracts;

  EmployeeResponse({
    required this.id,
    required this.userId,
    required this.user,
    required this.dateOfBirth,
    required this.address,
    this.city,
    this.department,
    this.position,
    required this.hireDate,
    required this.isActive,
    required this.contracts,
  });

  EmployeeContractResponse? get activeContract {
    for (final c in contracts) {
      if (c.status == ContractStatus.active) return c;
    }
    return null;
  }

  factory EmployeeResponse.fromJson(Map<String, dynamic> json) =>
      _$EmployeeResponseFromJson(json);
}
