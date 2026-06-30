import 'package:json_annotation/json_annotation.dart';

part 'dashboard_response.g.dart';

@JsonSerializable()
class DashboardResponse {
  final int totalEmployees;
  final int newEmployeesThisMonth;
  final int activeContracts;
  final int expiringContractsSoon;
  final double attendanceRate;
  final double attendanceRateChange;
  final int pendingLeaves;
  final int pendingVacationLeaves;
  final List<LeavesByDayItem> leavesByDay;
  final List<LeavesByTypeItem> leavesByType;
  final List<LeavesByStatusItem> leavesByStatus;
  final HrMetricsItem hrMetrics;

  DashboardResponse({
    required this.totalEmployees,
    required this.newEmployeesThisMonth,
    required this.activeContracts,
    required this.expiringContractsSoon,
    required this.attendanceRate,
    required this.attendanceRateChange,
    required this.pendingLeaves,
    required this.pendingVacationLeaves,
    required this.leavesByDay,
    required this.leavesByType,
    required this.leavesByStatus,
    required this.hrMetrics,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) =>
      _$DashboardResponseFromJson(json);
}

@JsonSerializable()
class LeavesByDayItem {
  final DateTime date;
  final String dayLabel;
  final int count;

  LeavesByDayItem({
    required this.date,
    required this.dayLabel,
    required this.count,
  });

  factory LeavesByDayItem.fromJson(Map<String, dynamic> json) =>
      _$LeavesByDayItemFromJson(json);
}

@JsonSerializable()
class LeavesByTypeItem {
  final String typeName;
  final int count;

  LeavesByTypeItem({required this.typeName, required this.count});

  factory LeavesByTypeItem.fromJson(Map<String, dynamic> json) =>
      _$LeavesByTypeItemFromJson(json);
}

@JsonSerializable()
class LeavesByStatusItem {
  final String status;
  final int count;

  LeavesByStatusItem({required this.status, required this.count});

  factory LeavesByStatusItem.fromJson(Map<String, dynamic> json) =>
      _$LeavesByStatusItemFromJson(json);
}

@JsonSerializable()
class HrMetricsItem {
  final double attendanceRate;
  final double contractFillRate;
  final double leaveApprovalRate;
  final double salaryPaymentRate;
  final double activeEmployeeRate;

  HrMetricsItem({
    required this.attendanceRate,
    required this.contractFillRate,
    required this.leaveApprovalRate,
    required this.salaryPaymentRate,
    required this.activeEmployeeRate,
  });

  factory HrMetricsItem.fromJson(Map<String, dynamic> json) =>
      _$HrMetricsItemFromJson(json);
}
