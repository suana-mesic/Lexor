// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmployeeUserResponse _$EmployeeUserResponseFromJson(
  Map<String, dynamic> json,
) => EmployeeUserResponse(
  id: (json['id'] as num).toInt(),
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  username: json['username'] as String?,
  email: json['email'] as String,
  phoneNumber: json['phoneNumber'] as String?,
  profileImageBase64: json['profileImageBase64'] as String?,
  profileThumbnailBase64: json['profileThumbnailBase64'] as String?,
  isCodeActivated: json['isCodeActivated'] as bool,
);

EmployeeCountryResponse _$EmployeeCountryResponseFromJson(
  Map<String, dynamic> json,
) => EmployeeCountryResponse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

EmployeeCityResponse _$EmployeeCityResponseFromJson(
  Map<String, dynamic> json,
) => EmployeeCityResponse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  country: EmployeeCountryResponse.fromJson(
    json['country'] as Map<String, dynamic>,
  ),
);

EmployeeDepartmentResponse _$EmployeeDepartmentResponseFromJson(
  Map<String, dynamic> json,
) => EmployeeDepartmentResponse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

EmployeePositionResponse _$EmployeePositionResponseFromJson(
  Map<String, dynamic> json,
) => EmployeePositionResponse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

EmployeeContractResponse _$EmployeeContractResponseFromJson(
  Map<String, dynamic> json,
) => EmployeeContractResponse(
  id: (json['id'] as num).toInt(),
  contractTypeId: (json['contractTypeId'] as num).toInt(),
  contractTypeName: json['contractTypeName'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: json['endDate'] == null
      ? null
      : DateTime.parse(json['endDate'] as String),
  brutoSalary: (json['brutoSalary'] as num).toDouble(),
  workHoursPerDay: (json['workHoursPerDay'] as num).toInt(),
  statusCode: (json['status'] as num).toInt(),
);

EmployeeResponse _$EmployeeResponseFromJson(Map<String, dynamic> json) =>
    EmployeeResponse(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      user: EmployeeUserResponse.fromJson(json['user'] as Map<String, dynamic>),
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      address: json['address'] as String,
      city: json['city'] == null
          ? null
          : EmployeeCityResponse.fromJson(json['city'] as Map<String, dynamic>),
      department: json['department'] == null
          ? null
          : EmployeeDepartmentResponse.fromJson(
              json['department'] as Map<String, dynamic>,
            ),
      position: json['position'] == null
          ? null
          : EmployeePositionResponse.fromJson(
              json['position'] as Map<String, dynamic>,
            ),
      hireDate: DateTime.parse(json['hireDate'] as String),
      isActive: json['isActive'] as bool,
      contracts: (json['contracts'] as List<dynamic>)
          .map(
            (e) => EmployeeContractResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
