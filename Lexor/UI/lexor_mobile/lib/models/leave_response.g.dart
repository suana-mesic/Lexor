// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leave_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveResponse _$LeaveResponseFromJson(Map<String, dynamic> json) =>
    LeaveResponse(
      id: (json['id'] as num).toInt(),
      leaveType: LeaveTypeResponse.fromJson(
        json['leaveType'] as Map<String, dynamic>,
      ),
      dateFrom: DateTime.parse(json['dateFrom'] as String),
      dateTo: DateTime.parse(json['dateTo'] as String),
      numberOfDays: (json['numberOfDays'] as num).toInt(),
      state: json['state'] as String?,
      reason: json['reason'] as String,
      allowedActions: json['allowedActions'] as List<dynamic>,
    );

Map<String, dynamic> _$LeaveResponseToJson(LeaveResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'leaveType': instance.leaveType,
      'dateFrom': instance.dateFrom.toIso8601String(),
      'dateTo': instance.dateTo.toIso8601String(),
      'numberOfDays': instance.numberOfDays,
      'state': instance.state,
      'reason': instance.reason,
      'allowedActions': instance.allowedActions,
    };

LeaveTypeResponse _$LeaveTypeResponseFromJson(Map<String, dynamic> json) =>
    LeaveTypeResponse(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isPaid: json['isPaid'] as bool,
    );

Map<String, dynamic> _$LeaveTypeResponseToJson(LeaveTypeResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isPaid': instance.isPaid,
    };
