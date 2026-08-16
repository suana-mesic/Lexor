import 'package:json_annotation/json_annotation.dart';

part 'attendance_response.g.dart';

@JsonSerializable(createToJson: false)
class AttendanceResponse {
  final int id;
  final DateTime date;
  final DateTime? dateTimeEntered;
  final DateTime? dateTimeLeft;
  final double? workedHours;

  AttendanceResponse({
    required this.id,
    required this.date,
    this.dateTimeEntered,
    this.dateTimeLeft,
    this.workedHours,
  });
  factory AttendanceResponse.fromJson(Map<String, dynamic> json) =>
      _$AttendanceResponseFromJson(json);
}
