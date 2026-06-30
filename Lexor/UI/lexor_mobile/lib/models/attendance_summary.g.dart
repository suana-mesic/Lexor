// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceSummary _$AttendanceSummaryFromJson(Map<String, dynamic> json) =>
    AttendanceSummary(
      todayWorkedHours: (json['todayWorkedHours'] as num).toDouble(),
      monthTotalHours: (json['monthTotalHours'] as num).toDouble(),
      monthAttendanceRate: (json['monthAttendanceRate'] as num).toDouble(),
      todayStatus: json['todayStatus'] as String,
    );

Map<String, dynamic> _$AttendanceSummaryToJson(AttendanceSummary instance) =>
    <String, dynamic>{
      'todayWorkedHours': instance.todayWorkedHours,
      'monthTotalHours': instance.monthTotalHours,
      'monthAttendanceRate': instance.monthAttendanceRate,
      'todayStatus': instance.todayStatus,
    };
