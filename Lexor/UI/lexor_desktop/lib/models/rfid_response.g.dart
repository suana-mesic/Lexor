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

EmployeeResponse _$EmployeeResponseFromJson(Map<String, dynamic> json) =>
    EmployeeResponse(
      id: (json['id'] as num).toInt(),
      user: UserResponse.fromJson(json['user'] as Map<String, dynamic>),
    );

UserResponse _$UserResponseFromJson(Map<String, dynamic> json) => UserResponse(
  id: (json['id'] as num).toInt(),
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  profileThumbnailBase64: json['profileThumbnailBase64'] as String?,
);
