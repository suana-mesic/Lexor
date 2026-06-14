import 'package:json_annotation/json_annotation.dart';

part 'attendance_summary.g.dart';

@JsonSerializable()
class AttendanceSummary {
  final double todayWorkedHours;
  final double monthWorkedHours;
  final double monthAttendaceRate;
  final String todayStatus;

  AttendanceSummary({
    required this.todayWorkedHours,
    required this.monthWorkedHours,
    required this.monthAttendaceRate,
    required this.todayStatus,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) =>
      _$AttendanceSummaryFromJson(json);
}
