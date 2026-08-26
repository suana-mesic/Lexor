import 'package:json_annotation/json_annotation.dart';

part 'rfid_response.g.dart';

@JsonSerializable(createToJson: false)
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

  /// Avatar for list views; null when there is no photo.
  String? get employeeThumbnail => employee.user.profileThumbnailBase64;

  factory RfidResponse.fromJson(Map<String, dynamic> json) =>
      _$RfidResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class EmployeeResponse {
  final int id;
  final UserResponse user;

  EmployeeResponse({required this.id, required this.user});

  factory EmployeeResponse.fromJson(Map<String, dynamic> json) =>
      _$EmployeeResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class UserResponse {
  final int id;
  final String firstName;
  final String lastName;

  /// Small avatar sent with list responses; null when the person has no photo.
  final String? profileThumbnailBase64;

  UserResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileThumbnailBase64,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);
}
