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
  final int notActivatedUsers;
  final List<RoleUserCount> usersPerRole;
  final int departments;
  final int positions;
  final int cities;
  final int contractTypes;
  final int leaveTypes;
  final int legalDocuments;
  final int activeRfidCards;
  final int activeContracts;
  final int expiredContracts;
  final int expiringSoonContracts;

  AdminStatsResponse({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.notActivatedUsers,
    required this.usersPerRole,
    required this.departments,
    required this.positions,
    required this.cities,
    required this.contractTypes,
    required this.leaveTypes,
    required this.legalDocuments,
    required this.activeRfidCards,
    required this.activeContracts,
    required this.expiredContracts,
    required this.expiringSoonContracts,
  });

  factory AdminStatsResponse.fromJson(Map<String, dynamic> json) {
    int i(String k) => json[k] as int? ?? 0;
    return AdminStatsResponse(
      totalUsers: i('totalUsers'),
      activeUsers: i('activeUsers'),
      inactiveUsers: i('inactiveUsers'),
      notActivatedUsers: i('notActivatedUsers'),
      usersPerRole: ((json['usersPerRole'] as List?) ?? [])
          .map((e) => RoleUserCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      departments: i('departments'),
      positions: i('positions'),
      cities: i('cities'),
      contractTypes: i('contractTypes'),
      leaveTypes: i('leaveTypes'),
      legalDocuments: i('legalDocuments'),
      activeRfidCards: i('activeRfidCards'),
      activeContracts: i('activeContracts'),
      expiredContracts: i('expiredContracts'),
      expiringSoonContracts: i('expiringSoonContracts'),
    );
  }
}
