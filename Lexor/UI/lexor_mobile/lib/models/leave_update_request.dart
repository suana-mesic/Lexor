import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
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
