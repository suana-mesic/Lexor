import 'package:json_annotation/json_annotation.dart';

part 'attendance_response.g.dart';

@JsonSerializable(createToJson: false)
class AttendanceUserResponse {
  final int id;
  final String firstName;
  final String lastName;

  /// Small avatar sent with list responses; null when the person has no photo.
  final String? profileThumbnailBase64;

  AttendanceUserResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileThumbnailBase64,
  });

  factory AttendanceUserResponse.fromJson(Map<String, dynamic> json) =>
      _$AttendanceUserResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class AttendanceDepartmentResponse {
  final int id;
  final String name;

  AttendanceDepartmentResponse({required this.id, required this.name});

  factory AttendanceDepartmentResponse.fromJson(Map<String, dynamic> json) =>
      _$AttendanceDepartmentResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class AttendanceEmployeeResponse {
  final int id;
  final AttendanceUserResponse? user;
  final AttendanceDepartmentResponse? department;

  AttendanceEmployeeResponse({required this.id, this.user, this.department});

  factory AttendanceEmployeeResponse.fromJson(Map<String, dynamic> json) =>
      _$AttendanceEmployeeResponseFromJson(json);
}

/// An attendance record as returned by the API. For admin clients [employee]
/// is populated; for employees it stays null (they only see their own).
@JsonSerializable(createToJson: false)
class AttendanceResponse {
  final int id;
  final AttendanceEmployeeResponse? employee;
  final DateTime date;
  final DateTime? dateTimeEntered;
  final DateTime? dateTimeLeft;
  final double? workedHours;
  final String? correctionReason;

  AttendanceResponse({
    required this.id,
    this.employee,
    required this.date,
    this.dateTimeEntered,
    this.dateTimeLeft,
    this.workedHours,
    this.correctionReason,
  });

  String get employeeFullName => employee?.user == null
      ? '-'
      : '${employee!.user!.firstName} ${employee!.user!.lastName}';

  /// Avatar for list views; null when there is no photo.
  String? get employeeThumbnail => employee?.user?.profileThumbnailBase64;

  String get departmentName => employee?.department?.name ?? '-';

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) =>
      _$AttendanceResponseFromJson(json);
}
