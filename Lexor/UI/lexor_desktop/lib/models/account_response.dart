class AccountResponse {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? profileImageBase64;

  AccountResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.profileImageBase64,
  });

  String get fullName => '$firstName $lastName';

  factory AccountResponse.fromJson(Map<String, dynamic> json) => AccountResponse(
    id: json['id'] as int,
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    username: json['username'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phoneNumber: json['phoneNumber'] as String?,
    profileImageBase64: json['profileImageBase64'] as String?,
  );
}
