class PayrollDashboardResponse {
  final bool hasData;
  final int year;
  final int month;
  final double totalGross;
  final double totalNet;
  final double totalContributions;
  final double totalTax;
  final double totalOvertime;
  final double totalOvertimeHours;
  final int employeesWithOvertime;
  final double burdenRate;
  final double averageNet;
  final int slipCount;
  final List<OvertimeLeader> topOvertime;

  PayrollDashboardResponse({
    required this.hasData,
    required this.year,
    required this.month,
    required this.totalGross,
    required this.totalNet,
    required this.totalContributions,
    required this.totalTax,
    required this.totalOvertime,
    required this.totalOvertimeHours,
    required this.employeesWithOvertime,
    required this.burdenRate,
    required this.averageNet,
    required this.slipCount,
    required this.topOvertime,
  });

  factory PayrollDashboardResponse.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => (v as num?)?.toDouble() ?? 0;
    return PayrollDashboardResponse(
      hasData: json['hasData'] as bool? ?? false,
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      totalGross: d(json['totalGross']),
      totalNet: d(json['totalNet']),
      totalContributions: d(json['totalContributions']),
      totalTax: d(json['totalTax']),
      totalOvertime: d(json['totalOvertime']),
      totalOvertimeHours: d(json['totalOvertimeHours']),
      employeesWithOvertime: json['employeesWithOvertime'] as int? ?? 0,
      burdenRate: d(json['burdenRate']),
      averageNet: d(json['averageNet']),
      slipCount: json['slipCount'] as int? ?? 0,
      topOvertime: (json['topOvertime'] as List? ?? [])
          .map((e) => OvertimeLeader.fromJson(e))
          .toList(),
    );
  }
}

class OvertimeLeader {
  final String fullName;
  final double hours;
  final double amount;

  OvertimeLeader({
    required this.fullName,
    required this.hours,
    required this.amount,
  });

  factory OvertimeLeader.fromJson(Map<String, dynamic> json) => OvertimeLeader(
        fullName: json['fullName'] as String? ?? '',
        hours: (json['hours'] as num?)?.toDouble() ?? 0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}
