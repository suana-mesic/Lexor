// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardResponse _$DashboardResponseFromJson(Map<String, dynamic> json) =>
    DashboardResponse(
      totalEmployees: (json['totalEmployees'] as num).toInt(),
      newEmployeesThisMonth: (json['newEmployeesThisMonth'] as num).toInt(),
      activeContracts: (json['activeContracts'] as num).toInt(),
      expiringContractsSoon: (json['expiringContractsSoon'] as num).toInt(),
      attendanceRate: (json['attendanceRate'] as num).toDouble(),
      attendanceRateChange: (json['attendanceRateChange'] as num).toDouble(),
      pendingLeaves: (json['pendingLeaves'] as num).toInt(),
      pendingVacationLeaves: (json['pendingVacationLeaves'] as num).toInt(),
      leavesByDay: (json['leavesByDay'] as List<dynamic>)
          .map((e) => LeavesByDayItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      leavesByType: (json['leavesByType'] as List<dynamic>)
          .map((e) => LeavesByTypeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      leavesByStatus: (json['leavesByStatus'] as List<dynamic>)
          .map((e) => LeavesByStatusItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      hrMetrics: HrMetricsItem.fromJson(
        json['hrMetrics'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$DashboardResponseToJson(DashboardResponse instance) =>
    <String, dynamic>{
      'totalEmployees': instance.totalEmployees,
      'newEmployeesThisMonth': instance.newEmployeesThisMonth,
      'activeContracts': instance.activeContracts,
      'expiringContractsSoon': instance.expiringContractsSoon,
      'attendanceRate': instance.attendanceRate,
      'attendanceRateChange': instance.attendanceRateChange,
      'pendingLeaves': instance.pendingLeaves,
      'pendingVacationLeaves': instance.pendingVacationLeaves,
      'leavesByDay': instance.leavesByDay,
      'leavesByType': instance.leavesByType,
      'leavesByStatus': instance.leavesByStatus,
      'hrMetrics': instance.hrMetrics,
    };

LeavesByDayItem _$LeavesByDayItemFromJson(Map<String, dynamic> json) =>
    LeavesByDayItem(
      date: DateTime.parse(json['date'] as String),
      dayLabel: json['dayLabel'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$LeavesByDayItemToJson(LeavesByDayItem instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'dayLabel': instance.dayLabel,
      'count': instance.count,
    };

LeavesByTypeItem _$LeavesByTypeItemFromJson(Map<String, dynamic> json) =>
    LeavesByTypeItem(
      typeName: json['typeName'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$LeavesByTypeItemToJson(LeavesByTypeItem instance) =>
    <String, dynamic>{'typeName': instance.typeName, 'count': instance.count};

LeavesByStatusItem _$LeavesByStatusItemFromJson(Map<String, dynamic> json) =>
    LeavesByStatusItem(
      status: json['status'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$LeavesByStatusItemToJson(LeavesByStatusItem instance) =>
    <String, dynamic>{'status': instance.status, 'count': instance.count};

HrMetricsItem _$HrMetricsItemFromJson(Map<String, dynamic> json) =>
    HrMetricsItem(
      attendanceRate: (json['attendanceRate'] as num).toDouble(),
      contractFillRate: (json['contractFillRate'] as num).toDouble(),
      leaveApprovalRate: (json['leaveApprovalRate'] as num).toDouble(),
      salaryPaymentRate: (json['salaryPaymentRate'] as num).toDouble(),
      activeEmployeeRate: (json['activeEmployeeRate'] as num).toDouble(),
    );

Map<String, dynamic> _$HrMetricsItemToJson(HrMetricsItem instance) =>
    <String, dynamic>{
      'attendanceRate': instance.attendanceRate,
      'contractFillRate': instance.contractFillRate,
      'leaveApprovalRate': instance.leaveApprovalRate,
      'salaryPaymentRate': instance.salaryPaymentRate,
      'activeEmployeeRate': instance.activeEmployeeRate,
    };
