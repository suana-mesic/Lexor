enum LeaveStateType {
  pending('PendingLeaveState', 'Na čekanju'),
  approved('ApprovedLeaveState', 'Odobreno'),
  rejected('RejectedLeaveState', 'Odbijeno'),
  cancelled('CancelledLeaveState', 'Otkazano'),
  completed('CompletedLeaveState', 'Završeno');

  final String apiValue;
  final String label;
  const LeaveStateType(this.apiValue, this.label);

  static LeaveStateType? fromApi(String? value) {
    for (final s in values) {
      if (s.apiValue == value) return s;
    }
    return null;
  }
}
