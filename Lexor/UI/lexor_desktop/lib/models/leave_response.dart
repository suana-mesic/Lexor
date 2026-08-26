import 'package:lexor_shared/lexor_shared.dart';

/// A leave/absence request as returned by the API. For admin clients the
/// [employee] is populated; for employees it stays null (they only see their own).
class LeaveResponse {
  final int id;
  final LeaveEmployee? employee;
  final LeaveType leaveType;
  final DateTime dateFrom;
  final DateTime dateTo;
  final int numberOfDays;
  final String reason;
  final String? state;
  final String? rejectionReason;
  final DateTime createdAt;
  final List<String> allowedActions;

  const LeaveResponse({
    required this.id,
    required this.employee,
    required this.leaveType,
    required this.dateFrom,
    required this.dateTo,
    required this.numberOfDays,
    required this.reason,
    required this.state,
    required this.rejectionReason,
    required this.createdAt,
    required this.allowedActions,
  });

  /// Resolved state-machine state, or null when the API value is unknown.
  LeaveStateType? get status => LeaveStateType.fromApi(state);

  String get employeeFullName => employee == null
      ? '-'
      : '${employee!.user.firstName} ${employee!.user.lastName}';

  /// Avatar for list views; null when there is no photo.
  String? get employeeThumbnail => employee?.user.profileThumbnailBase64;

  factory LeaveResponse.fromJson(Map<String, dynamic> json) => LeaveResponse(
        id: json['id'] as int,
        employee: json['employee'] == null
            ? null
            : LeaveEmployee.fromJson(json['employee'] as Map<String, dynamic>),
        leaveType:
            LeaveType.fromJson(json['leaveType'] as Map<String, dynamic>),
        dateFrom: DateTime.parse(json['dateFrom'] as String),
        dateTo: DateTime.parse(json['dateTo'] as String),
        numberOfDays: json['numberOfDays'] as int? ?? 0,
        reason: json['reason'] as String? ?? '',
        state: json['state'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        allowedActions: (json['allowedActions'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
}

class LeaveEmployee {
  final int id;
  final LeaveUser user;

  const LeaveEmployee({required this.id, required this.user});

  factory LeaveEmployee.fromJson(Map<String, dynamic> json) => LeaveEmployee(
        id: json['id'] as int,
        user: LeaveUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class LeaveUser {
  final int id;
  final String firstName;
  final String lastName;

  /// Small avatar sent with list responses; null when the person has no photo.
  final String? profileThumbnailBase64;

  const LeaveUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileThumbnailBase64,
  });

  factory LeaveUser.fromJson(Map<String, dynamic> json) => LeaveUser(
        id: json['id'] as int? ?? 0,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        profileThumbnailBase64: json['profileThumbnailBase64'] as String?,
      );
}

class LeaveType {
  final int id;
  final String name;
  final bool isPaid;

  const LeaveType({
    required this.id,
    required this.name,
    required this.isPaid,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) => LeaveType(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        isPaid: json['isPaid'] as bool? ?? false,
      );
}
