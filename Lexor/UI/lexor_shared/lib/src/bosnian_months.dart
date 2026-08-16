/// Bosnian month names — index 0 = January ("Januar").
/// For a backend month (1–12) use `bosnianMonths[month - 1]`.
const List<String> bosnianMonths = [
  'Januar',
  'Februar',
  'Mart',
  'April',
  'Maj',
  'Juni',
  'Juli',
  'August',
  'Septembar',
  'Oktobar',
  'Novembar',
  'Decembar',
];

/// Safe month name for a 1–12 value coming from the backend.
/// Returns '-' for out-of-range input instead of throwing a RangeError.
String bosnianMonthName(int month) =>
    (month >= 1 && month <= 12) ? bosnianMonths[month - 1] : '-';
