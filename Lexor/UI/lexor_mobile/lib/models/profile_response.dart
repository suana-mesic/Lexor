import 'package:json_annotation/json_annotation.dart';

part 'profile_response.g.dart';

@JsonSerializable(createToJson: false)
class ProfileUserResponse {
  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String email;
  final String? phoneNumber;
  final String? profileImageBase64;

  ProfileUserResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.username,
    required this.email,
    this.phoneNumber,
    this.profileImageBase64,
  });

  factory ProfileUserResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileUserResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class ProfileCountryResponse {
  final String name;

  ProfileCountryResponse({required this.name});

  factory ProfileCountryResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileCountryResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class ProfileCityResponse {
  final String name;
  final ProfileCountryResponse? country;

  ProfileCityResponse({required this.name, this.country});

  factory ProfileCityResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileCityResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class ProfileRefResponse {
  final String name;

  ProfileRefResponse({required this.name});

  factory ProfileRefResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileRefResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class ProfileResponse {
  final int id;
  final ProfileUserResponse user;
  final DateTime dateOfBirth;
  final String address;
  final ProfileCityResponse? city;
  final ProfileRefResponse? department;
  final ProfileRefResponse? position;
  final DateTime hireDate;

  ProfileResponse({
    required this.id,
    required this.user,
    required this.dateOfBirth,
    required this.address,
    this.city,
    this.department,
    this.position,
    required this.hireDate,
  });

  String get fullName => '${user.firstName} ${user.lastName}';

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);
}
