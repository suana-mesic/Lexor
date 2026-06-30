// Modeli za referentne (šifarničke) tabele. Svi dijele `id` preko `ReferenceItem`
// kako bi generički `BaseProvider` mogao raditi nad bilo kojim od njih.

abstract class ReferenceItem {
  int get id;
}

class Country implements ReferenceItem {
  @override
  final int id;
  final String name;

  Country({required this.id, required this.name});

  factory Country.fromJson(Map<String, dynamic> json) =>
      Country(id: json['id'] as int, name: json['name'] as String? ?? '');
}

class City implements ReferenceItem {
  @override
  final int id;
  final String name;
  final int countryId;
  final String countryName;

  City({
    required this.id,
    required this.name,
    required this.countryId,
    required this.countryName,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        countryId: json['countryId'] as int? ?? 0,
        countryName: json['countryName'] as String? ?? '',
      );
}

class Department implements ReferenceItem {
  @override
  final int id;
  final String name;

  Department({required this.id, required this.name});

  factory Department.fromJson(Map<String, dynamic> json) =>
      Department(id: json['id'] as int, name: json['name'] as String? ?? '');
}

class Position implements ReferenceItem {
  @override
  final int id;
  final String name;
  final int departmentId;
  final String departmentName;

  Position({
    required this.id,
    required this.name,
    required this.departmentId,
    required this.departmentName,
  });

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        departmentId: json['departmentId'] as int? ?? 0,
        departmentName: json['departmentName'] as String? ?? '',
      );
}

class ContractType implements ReferenceItem {
  @override
  final int id;
  final String name;
  final bool endDateRequired;

  ContractType({
    required this.id,
    required this.name,
    required this.endDateRequired,
  });

  factory ContractType.fromJson(Map<String, dynamic> json) => ContractType(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        endDateRequired: json['endDateRequired'] as bool? ?? false,
      );
}

class LeaveType implements ReferenceItem {
  @override
  final int id;
  final String name;
  final bool isPaid;

  LeaveType({required this.id, required this.name, required this.isPaid});

  factory LeaveType.fromJson(Map<String, dynamic> json) => LeaveType(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        isPaid: json['isPaid'] as bool? ?? false,
      );
}

class LegalDocumentCategory implements ReferenceItem {
  @override
  final int id;
  final String name;

  LegalDocumentCategory({required this.id, required this.name});

  factory LegalDocumentCategory.fromJson(Map<String, dynamic> json) =>
      LegalDocumentCategory(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
      );
}
