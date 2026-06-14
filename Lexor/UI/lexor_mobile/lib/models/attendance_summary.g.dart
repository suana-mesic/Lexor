// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceSummary _$AttendanceSummaryFromJson(Map<String, dynamic> json) =>
    AttendanceSummary(
      todayWorkedHours: (json['todayWorkedHours'] as num).toDouble(),
      monthWorkedHours: (json['monthWorkedHours'] as num).toDouble(),
      monthAttendaceRate: (json['monthAttendaceRate'] as num).toDouble(),
      todayStatus: json['todayStatus'] as String,
    );

Map<String, dynamic> _$AttendanceSummaryToJson(AttendanceSummary instance) =>
    <String, dynamic>{
      'todayWorkedHours': instance.todayWorkedHours,
      'monthWorkedHours': instance.monthWorkedHours,
      'monthAttendaceRate': instance.monthAttendaceRate,
      'todayStatus': instance.todayStatus,
    };
