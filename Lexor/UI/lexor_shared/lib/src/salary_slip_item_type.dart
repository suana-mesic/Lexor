enum SalaryItemCategory { bruto, contribution, deduction }

enum SalarySlipItemType {
  brutoBase(1, SalaryItemCategory.bruto),
  overtime(2, SalaryItemCategory.bruto),
  unpaidLeave(3, SalaryItemCategory.bruto),
  pioMio(4, SalaryItemCategory.contribution),
  health(5, SalaryItemCategory.contribution),
  unemployment(6, SalaryItemCategory.contribution),
  personalDeduction(7, SalaryItemCategory.deduction),
  incomeTax(8, SalaryItemCategory.deduction);

  final int code;
  final SalaryItemCategory category;
  const SalarySlipItemType(this.code, this.category);

  static SalarySlipItemType? fromCode(int? code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }
}
