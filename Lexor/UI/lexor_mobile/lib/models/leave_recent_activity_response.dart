import 'package:json_annotation/json_annotation.dart';

part 'leave_recent_activity_response.g.dart';

@JsonSerializable(createToJson: false)
class LeaveRecentActivityResponse {
  final LeaveTypeResponse leaveType;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String? state;
  final DateTime createdAt;

  LeaveRecentActivityResponse({
    required this.leaveType,
    required this.dateFrom,
    required this.dateTo,
    required this.createdAt,
    this.state,
  });

  factory LeaveRecentActivityResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaveRecentActivityResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class LeaveTypeResponse {
  final String name;

  LeaveTypeResponse({required this.name});

  factory LeaveTypeResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaveTypeResponseFromJson(json);
}
