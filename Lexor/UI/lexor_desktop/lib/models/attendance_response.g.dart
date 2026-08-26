// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceUserResponse _$AttendanceUserResponseFromJson(
  Map<String, dynamic> json,
) => AttendanceUserResponse(
  id: (json['id'] as num).toInt(),
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  profileThumbnailBase64: json['profileThumbnailBase64'] as String?,
);

AttendanceDepartmentResponse _$AttendanceDepartmentResponseFromJson(
  Map<String, dynamic> json,
) => AttendanceDepartmentResponse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

AttendanceEmployeeResponse _$AttendanceEmployeeResponseFromJson(
  Map<String, dynamic> json,
) => AttendanceEmployeeResponse(
  id: (json['id'] as num).toInt(),
  user: json['user'] == null
      ? null
      : AttendanceUserResponse.fromJson(json['user'] as Map<String, dynamic>),
  department: json['department'] == null
      ? null
      : AttendanceDepartmentResponse.fromJson(
          json['department'] as Map<String, dynamic>,
        ),
);

AttendanceResponse _$AttendanceResponseFromJson(Map<String, dynamic> json) =>
    AttendanceResponse(
      id: (json['id'] as num).toInt(),
      employee: json['employee'] == null
          ? null
          : AttendanceEmployeeResponse.fromJson(
              json['employee'] as Map<String, dynamic>,
            ),
      date: DateTime.parse(json['date'] as String),
      dateTimeEntered: json['dateTimeEntered'] == null
          ? null
          : DateTime.parse(json['dateTimeEntered'] as String),
      dateTimeLeft: json['dateTimeLeft'] == null
          ? null
          : DateTime.parse(json['dateTimeLeft'] as String),
      workedHours: (json['workedHours'] as num?)?.toDouble(),
      correctionReason: json['correctionReason'] as String?,
    );
