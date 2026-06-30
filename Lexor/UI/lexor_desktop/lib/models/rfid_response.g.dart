// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rfid_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RfidResponse _$RfidResponseFromJson(Map<String, dynamic> json) => RfidResponse(
  id: (json['id'] as num).toInt(),
  employee: EmployeeResponse.fromJson(json['employee'] as Map<String, dynamic>),
  uid: json['uid'] as String,
  assignedAt: DateTime.parse(json['assignedAt'] as String),
  isActive: json['isActive'] as bool,
  deactivatedAt: json['deactivatedAt'] == null
      ? null
      : DateTime.parse(json['deactivatedAt'] as String),
);

Map<String, dynamic> _$RfidResponseToJson(RfidResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employee': instance.employee,
      'uid': instance.uid,
      'assignedAt': instance.assignedAt.toIso8601String(),
      'deactivatedAt': instance.deactivatedAt?.toIso8601String(),
      'isActive': instance.isActive,
    };

EmployeeResponse _$EmployeeResponseFromJson(Map<String, dynamic> json) =>
    EmployeeResponse(
      id: (json['id'] as num).toInt(),
      user: UserResponse.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EmployeeResponseToJson(EmployeeResponse instance) =>
    <String, dynamic>{'id': instance.id, 'user': instance.user};

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) => UserResponse(
  id: (json['id'] as num).toInt(),
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
);

Map<String, dynamic> _$UserResponseToJson(UserResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
    };
