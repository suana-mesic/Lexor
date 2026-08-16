import 'package:json_annotation/json_annotation.dart';
import 'package:lexor_shared/lexor_shared.dart';

part 'contract_response.g.dart';

@JsonSerializable(createToJson: false)
class ContractTypeResponse {
  final int id;
  final String name;

  ContractTypeResponse({required this.id, required this.name});

  factory ContractTypeResponse.fromJson(Map<String, dynamic> json) =>
      _$ContractTypeResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class ContractResponse {
  final int id;
  final int employeeId;
  final int contractTypeId;
  final ContractTypeResponse contractType;
  final DateTime startDate;
  final DateTime? endDate;
  final double brutoSalary;
  final int workHoursPerDay;

  // Derived on the server from the date range; serialized as an int code (1/2/3).
  @JsonKey(name: 'status')
  final int statusCode;

  ContractResponse({
    required this.id,
    required this.employeeId,
    required this.contractTypeId,
    required this.contractType,
    required this.startDate,
    this.endDate,
    required this.brutoSalary,
    required this.workHoursPerDay,
    required this.statusCode,
  });

  ContractStatus get status =>
      ContractStatus.fromCode(statusCode) ?? ContractStatus.active;

  factory ContractResponse.fromJson(Map<String, dynamic> json) =>
      _$ContractResponseFromJson(json);
}
