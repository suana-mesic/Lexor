class AdminUserResponse {
  final int id;
  final String firstName;
  final String lastName;

  /// Small avatar sent with list responses; null when the user has no photo.
  final String? profileThumbnailBase64;
  final String email;
  final String username;
  final String? phoneNumber;
  final String roleName;
  final bool isActive;
  final bool isCodeActivated;
  final DateTime? lastLoginAt;

  AdminUserResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileThumbnailBase64,
    required this.email,
    required this.username,
    this.phoneNumber,
    required this.roleName,
    required this.isActive,
    required this.isCodeActivated,
    this.lastLoginAt,
  });

  String get fullName => '$firstName $lastName';

  factory AdminUserResponse.fromJson(Map<String, dynamic> json) => AdminUserResponse(
    id: json['id'] as int,
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    profileThumbnailBase64: json['profileThumbnailBase64'] as String?,
    email: json['email'] as String? ?? '',
    username: json['username'] as String? ?? '',
    phoneNumber: json['phoneNumber'] as String?,
    roleName: json['roleName'] as String? ?? '',
    isActive: json['isActive'] as bool? ?? true,
    isCodeActivated: json['isCodeActivated'] as bool? ?? false,
    lastLoginAt: json['lastLoginAt'] == null
        ? null
        : DateTime.parse(json['lastLoginAt'] as String),
  );
}
