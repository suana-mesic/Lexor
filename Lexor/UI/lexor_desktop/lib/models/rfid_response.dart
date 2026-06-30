import 'package:json_annotation/json_annotation.dart';

part 'rfid_response.g.dart';

@JsonSerializable()
class RfidResponse {
  final int id;
  final EmployeeResponse employee;
  final String uid;
  final DateTime assignedAt;
  final DateTime? deactivatedAt;
  final bool isActive;

  RfidResponse({
    required this.id,
    required this.employee,
    required this.uid,
    required this.assignedAt,
    required this.isActive,
    this.deactivatedAt,
  });

  String get employeeFullName =>
      '${employee.user.firstName} ${employee.user.lastName}';

  factory RfidResponse.fromJson(Map<String, dynamic> json) =>
      _$RfidResponseFromJson(json);
}

@JsonSerializable()
class EmployeeResponse {
  final int id;
  final UserResponse user;

  EmployeeResponse({required this.id, required this.user});

  factory EmployeeResponse.fromJson(Map<String, dynamic> json) =>
      _$EmployeeResponseFromJson(json);
}

@JsonSerializable()
class UserResponse {
  final int id;
  final String firstName;
  final String lastName;

  UserResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);
}
