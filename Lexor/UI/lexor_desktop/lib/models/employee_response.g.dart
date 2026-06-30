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
  isCodeActivated: json['isCodeActivated'] as bool,
);

Map<String, dynamic> _$EmployeeUserResponseToJson(
  EmployeeUserResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'username': instance.username,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'profileImageBase64': instance.profileImageBase64,
  'isCodeActivated': instance.isCodeActivated,
};

EmployeeCountryResponse _$EmployeeCountryResponseFromJson(
  Map<String, dynamic> json,
) => EmployeeCountryResponse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

Map<String, dynamic> _$EmployeeCountryResponseToJson(
  EmployeeCountryResponse instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

EmployeeCityResponse _$EmployeeCityResponseFromJson(
  Map<String, dynamic> json,
) => EmployeeCityResponse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  country: EmployeeCountryResponse.fromJson(
    json['country'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$EmployeeCityResponseToJson(
  EmployeeCityResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'country': instance.country,
};

EmployeeDepartmentResponse _$EmployeeDepartmentResponseFromJson(
  Map<String, dynamic> json,
) => EmployeeDepartmentResponse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

Map<String, dynamic> _$EmployeeDepartmentResponseToJson(
  EmployeeDepartmentResponse instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

EmployeePositionResponse _$EmployeePositionResponseFromJson(
  Map<String, dynamic> json,
) => EmployeePositionResponse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

Map<String, dynamic> _$EmployeePositionResponseToJson(
  EmployeePositionResponse instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

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

Map<String, dynamic> _$EmployeeContractResponseToJson(
  EmployeeContractResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'contractTypeId': instance.contractTypeId,
  'contractTypeName': instance.contractTypeName,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate?.toIso8601String(),
  'brutoSalary': instance.brutoSalary,
  'workHoursPerDay': instance.workHoursPerDay,
  'status': instance.statusCode,
};

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

Map<String, dynamic> _$EmployeeResponseToJson(EmployeeResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'user': instance.user,
      'dateOfBirth': instance.dateOfBirth.toIso8601String(),
      'address': instance.address,
      'city': instance.city,
      'department': instance.department,
      'position': instance.position,
      'hireDate': instance.hireDate.toIso8601String(),
      'isActive': instance.isActive,
      'contracts': instance.contracts,
    };
