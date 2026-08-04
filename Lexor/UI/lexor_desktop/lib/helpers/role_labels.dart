/// Maps the technical role value (stored in the JWT / DB) to a Bosnian display label.
String roleLabel(String roleName) {
  switch (roleName) {
    case 'HRManager':
      return 'HR menadžer';
    case 'Accounting':
      return 'Računovodstvo';
    case 'Administrator':
      return 'Administrator';
    case 'Employee':
      return 'Uposlenik';
    default:
      return roleName;
  }
}
