// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceResponse _$AttendanceResponseFromJson(Map<String, dynamic> json) =>
    AttendanceResponse(
      id: (json['id'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      dateTimeEntered: json['dateTimeEntered'] == null
          ? null
          : DateTime.parse(json['dateTimeEntered'] as String),
      dateTimeLeft: json['dateTimeLeft'] == null
          ? null
          : DateTime.parse(json['dateTimeLeft'] as String),
      workedHours: (json['workedHours'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AttendanceResponseToJson(AttendanceResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'dateTimeEntered': instance.dateTimeEntered?.toIso8601String(),
      'dateTimeLeft': instance.dateTimeLeft?.toIso8601String(),
      'workedHours': instance.workedHours,
    };
