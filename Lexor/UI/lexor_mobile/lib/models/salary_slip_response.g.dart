// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salary_slip_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalarySlipUserResponse _$SalarySlipUserResponseFromJson(
  Map<String, dynamic> json,
) => SalarySlipUserResponse(
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
);

SalarySlipEmployeeResponse _$SalarySlipEmployeeResponseFromJson(
  Map<String, dynamic> json,
) => SalarySlipEmployeeResponse(
  user: SalarySlipUserResponse.fromJson(json['user'] as Map<String, dynamic>),
);

SalarySlipItemResponse _$SalarySlipItemResponseFromJson(
  Map<String, dynamic> json,
) => SalarySlipItemResponse(
  itemType: (json['itemType'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  quantity: (json['quantity'] as num?)?.toDouble(),
  rate: (json['rate'] as num?)?.toDouble(),
  multiplier: (json['multiplier'] as num?)?.toDouble(),
  amount: (json['amount'] as num).toDouble(),
);

SalarySlipResponse _$SalarySlipResponseFromJson(Map<String, dynamic> json) =>
    SalarySlipResponse(
      id: (json['id'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      brutoSalary: (json['brutoSalary'] as num).toDouble(),
      adjustedBruto: (json['adjustedBruto'] as num).toDouble(),
      totalContributions: (json['totalContributions'] as num).toDouble(),
      taxBase: (json['taxBase'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      netSalary: (json['netSalary'] as num).toDouble(),
      status: (json['status'] as num).toInt(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
      employee: SalarySlipEmployeeResponse.fromJson(
        json['employee'] as Map<String, dynamic>,
      ),
      items: (json['items'] as List<dynamic>?)
          ?.map(
            (e) => SalarySlipItemResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
