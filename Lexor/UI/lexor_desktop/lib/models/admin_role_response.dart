class AdminRoleResponse {
  final int id;
  final String name;
  final String description;
  final bool isActive;
  final int userCount;

  AdminRoleResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.userCount,
  });

  factory AdminRoleResponse.fromJson(Map<String, dynamic> json) => AdminRoleResponse(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    isActive: json['isActive'] as bool? ?? true,
    userCount: json['userCount'] as int? ?? 0,
  );
}
