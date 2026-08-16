import 'package:intl/intl.dart';

/// Sent on leave update; only the fields the user actually changed are included,
/// so the hand-written toJson omits nulls instead of using code generation.
class LeaveUpdateRequest {
  final int? leaveTypeId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? reason;

  LeaveUpdateRequest({
    this.leaveTypeId,
    this.dateFrom,
    this.dateTo,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    if (leaveTypeId != null) 'leaveTypeId': leaveTypeId,
    if (dateFrom != null)
      'dateFrom': DateFormat('yyyy-MM-dd').format(dateFrom!),
    if (dateTo != null) 'dateTo': DateFormat('yyyy-MM-dd').format(dateTo!),
    if (reason != null) 'reason': reason,
  };
}
