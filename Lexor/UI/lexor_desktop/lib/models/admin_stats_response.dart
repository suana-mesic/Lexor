class RoleUserCount {
  final String roleName;
  final int count;

  RoleUserCount({required this.roleName, required this.count});

  factory RoleUserCount.fromJson(Map<String, dynamic> json) => RoleUserCount(
    roleName: json['roleName'] as String? ?? '',
    count: json['count'] as int? ?? 0,
  );
}

class AdminStatsResponse {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final List<RoleUserCount> usersPerRole;

  AdminStatsResponse({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.usersPerRole,
  });

  factory AdminStatsResponse.fromJson(Map<String, dynamic> json) => AdminStatsResponse(
    totalUsers: json['totalUsers'] as int? ?? 0,
    activeUsers: json['activeUsers'] as int? ?? 0,
    inactiveUsers: json['inactiveUsers'] as int? ?? 0,
    usersPerRole: ((json['usersPerRole'] as List?) ?? [])
        .map((e) => RoleUserCount.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
