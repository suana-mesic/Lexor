import 'package:lexor_desktop/models/reference_models.dart';
import 'package:lexor_desktop/providers/base_provider.dart';

class CityProvider extends BaseProvider<City> {
  CityProvider() : super('Cities');
  @override
  City fromJson(dynamic data) => City.fromJson(data);
}

class CountryProvider extends BaseProvider<Country> {
  CountryProvider() : super('Countries');
  @override
  Country fromJson(dynamic data) => Country.fromJson(data);
}

class DepartmentProvider extends BaseProvider<Department> {
  DepartmentProvider() : super('Departments');
  @override
  Department fromJson(dynamic data) => Department.fromJson(data);
}

class PositionProvider extends BaseProvider<Position> {
  PositionProvider() : super('Positions');
  @override
  Position fromJson(dynamic data) => Position.fromJson(data);
}

class ContractTypeProvider extends BaseProvider<ContractType> {
  ContractTypeProvider() : super('ContractTypes');
  @override
  ContractType fromJson(dynamic data) => ContractType.fromJson(data);
}

class LeaveTypeProvider extends BaseProvider<LeaveType> {
  LeaveTypeProvider() : super('LeaveTypes');
  @override
  LeaveType fromJson(dynamic data) => LeaveType.fromJson(data);
}

class LegalDocumentCategoryProvider
    extends BaseProvider<LegalDocumentCategory> {
  LegalDocumentCategoryProvider() : super('LegalDocumentCategories');
  @override
  LegalDocumentCategory fromJson(dynamic data) =>
      LegalDocumentCategory.fromJson(data);
}
