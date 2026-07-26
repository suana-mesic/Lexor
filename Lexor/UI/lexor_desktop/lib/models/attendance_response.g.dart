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
);

Map<String, dynamic> _$AttendanceUserResponseToJson(
  AttendanceUserResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
};

AttendanceDepartmentResponse _$AttendanceDepartmentResponseFromJson(
  Map<String, dynamic> json,
) => AttendanceDepartmentResponse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

Map<String, dynamic> _$AttendanceDepartmentResponseToJson(
  AttendanceDepartmentResponse instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

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

Map<String, dynamic> _$AttendanceEmployeeResponseToJson(
  AttendanceEmployeeResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'user': instance.user,
  'department': instance.department,
};

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

Map<String, dynamic> _$AttendanceResponseToJson(AttendanceResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employee': instance.employee,
      'date': instance.date.toIso8601String(),
      'dateTimeEntered': instance.dateTimeEntered?.toIso8601String(),
      'dateTimeLeft': instance.dateTimeLeft?.toIso8601String(),
      'workedHours': instance.workedHours,
      'correctionReason': instance.correctionReason,
    };
