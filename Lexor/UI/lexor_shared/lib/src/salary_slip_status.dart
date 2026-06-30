enum SalarySlipStatus {
  pending(1, 'Plata na čekanju'),
  paid(2, 'Plata isplaćena');

  final int code;
  final String label;

  const SalarySlipStatus(this.code, this.label);

  static SalarySlipStatus? fromCode(int? code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return null;
  }
}
