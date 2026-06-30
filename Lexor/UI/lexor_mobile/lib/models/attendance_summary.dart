import 'package:json_annotation/json_annotation.dart';

part 'attendance_summary.g.dart';

@JsonSerializable()
class AttendanceSummary {
  final double todayWorkedHours;
  final double monthTotalHours;
  final double monthAttendanceRate;
  final String todayStatus;

  AttendanceSummary({
    required this.todayWorkedHours,
    required this.monthTotalHours,
    required this.monthAttendanceRate,
    required this.todayStatus,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) =>
      _$AttendanceSummaryFromJson(json);
}
