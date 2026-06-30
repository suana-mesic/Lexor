enum ContractStatus {
  active(1, 'Aktivan'),
  expired(2, 'Istekao'),
  upcoming(3, 'Budući');

  final int code;
  final String label;

  const ContractStatus(this.code, this.label);

  static ContractStatus? fromCode(int? code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return null;
  }
}
