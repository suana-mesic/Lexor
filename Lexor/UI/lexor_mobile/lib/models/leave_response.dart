import 'package:json_annotation/json_annotation.dart';

part 'leave_response.g.dart';

@JsonSerializable()
class LeaveResponse {
  final int id;
  final LeaveTypeResponse leaveType;
  final DateTime dateFrom;
  final DateTime dateTo;
  final int numberOfDays;
  final String? state;
  final String reason;
  final List<dynamic> allowedActions;

  LeaveResponse({
    required this.id,
    required this.leaveType, // samo name
    required this.dateFrom,
    required this.dateTo,
    required this.numberOfDays,
    this.state,
    required this.reason,
    required this.allowedActions,
  });

  factory LeaveResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaveResponseFromJson(json);
}

@JsonSerializable()
class LeaveTypeResponse {
  final int id;
  final String name;
  final bool isPaid;

  LeaveTypeResponse({
    required this.id,
    required this.name,
    required this.isPaid,
  });

  factory LeaveTypeResponse.fromJson(Map<String, dynamic> json) =>
      _$LeaveTypeResponseFromJson(json);
}
