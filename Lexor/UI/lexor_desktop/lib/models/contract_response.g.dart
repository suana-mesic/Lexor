// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContractTypeResponse _$ContractTypeResponseFromJson(
  Map<String, dynamic> json,
) => ContractTypeResponse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

ContractResponse _$ContractResponseFromJson(Map<String, dynamic> json) =>
    ContractResponse(
      id: (json['id'] as num).toInt(),
      employeeId: (json['employeeId'] as num).toInt(),
      contractTypeId: (json['contractTypeId'] as num).toInt(),
      contractType: ContractTypeResponse.fromJson(
        json['contractType'] as Map<String, dynamic>,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      brutoSalary: (json['brutoSalary'] as num).toDouble(),
      workHoursPerDay: (json['workHoursPerDay'] as num).toInt(),
      statusCode: (json['status'] as num).toInt(),
    );
