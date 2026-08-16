// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_recent_activity_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveRecentActivityResponse _$LeaveRecentActivityResponseFromJson(
  Map<String, dynamic> json,
) => LeaveRecentActivityResponse(
  leaveType: LeaveTypeResponse.fromJson(
    json['leaveType'] as Map<String, dynamic>,
  ),
  dateFrom: DateTime.parse(json['dateFrom'] as String),
  dateTo: DateTime.parse(json['dateTo'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  state: json['state'] as String?,
);

LeaveTypeResponse _$LeaveTypeResponseFromJson(Map<String, dynamic> json) =>
    LeaveTypeResponse(name: json['name'] as String);
