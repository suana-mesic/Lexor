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

Map<String, dynamic> _$SalarySlipUserResponseToJson(
  SalarySlipUserResponse instance,
) => <String, dynamic>{
  'firstName': instance.firstName,
  'lastName': instance.lastName,
};

SalarySlipEmployeeResponse _$SalarySlipEmployeeResponseFromJson(
  Map<String, dynamic> json,
) => SalarySlipEmployeeResponse(
  user: SalarySlipUserResponse.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SalarySlipEmployeeResponseToJson(
  SalarySlipEmployeeResponse instance,
) => <String, dynamic>{'user': instance.user};

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

Map<String, dynamic> _$SalarySlipItemResponseToJson(
  SalarySlipItemResponse instance,
) => <String, dynamic>{
  'itemType': instance.itemType,
  'name': instance.name,
  'description': instance.description,
  'quantity': instance.quantity,
  'rate': instance.rate,
  'multiplier': instance.multiplier,
  'amount': instance.amount,
};

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

Map<String, dynamic> _$SalarySlipResponseToJson(SalarySlipResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'year': instance.year,
      'month': instance.month,
      'brutoSalary': instance.brutoSalary,
      'adjustedBruto': instance.adjustedBruto,
      'totalContributions': instance.totalContributions,
      'taxBase': instance.taxBase,
      'tax': instance.tax,
      'netSalary': instance.netSalary,
      'status': instance.status,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'paidAt': instance.paidAt?.toIso8601String(),
      'employee': instance.employee,
      'items': instance.items,
    };
