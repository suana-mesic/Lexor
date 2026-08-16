// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileUserResponse _$ProfileUserResponseFromJson(Map<String, dynamic> json) =>
    ProfileUserResponse(
      id: (json['id'] as num).toInt(),
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      username: json['username'] as String?,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      profileImageBase64: json['profileImageBase64'] as String?,
    );

ProfileCountryResponse _$ProfileCountryResponseFromJson(
  Map<String, dynamic> json,
) => ProfileCountryResponse(name: json['name'] as String);

ProfileCityResponse _$ProfileCityResponseFromJson(Map<String, dynamic> json) =>
    ProfileCityResponse(
      name: json['name'] as String,
      country: json['country'] == null
          ? null
          : ProfileCountryResponse.fromJson(
              json['country'] as Map<String, dynamic>,
            ),
    );

ProfileRefResponse _$ProfileRefResponseFromJson(Map<String, dynamic> json) =>
    ProfileRefResponse(name: json['name'] as String);

ProfileResponse _$ProfileResponseFromJson(
  Map<String, dynamic> json,
) => ProfileResponse(
  id: (json['id'] as num).toInt(),
  user: ProfileUserResponse.fromJson(json['user'] as Map<String, dynamic>),
  dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
  address: json['address'] as String,
  city: json['city'] == null
      ? null
      : ProfileCityResponse.fromJson(json['city'] as Map<String, dynamic>),
  department: json['department'] == null
      ? null
      : ProfileRefResponse.fromJson(json['department'] as Map<String, dynamic>),
  position: json['position'] == null
      ? null
      : ProfileRefResponse.fromJson(json['position'] as Map<String, dynamic>),
  hireDate: DateTime.parse(json['hireDate'] as String),
);
