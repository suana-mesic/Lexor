// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salary_slip_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalarySlipUser _$SalarySlipUserFromJson(Map<String, dynamic> json) =>
    SalarySlipUser(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      profileThumbnailBase64: json['profileThumbnailBase64'] as String?,
    );

SalarySlipEmployee _$SalarySlipEmployeeFromJson(Map<String, dynamic> json) =>
    SalarySlipEmployee(
      id: (json['id'] as num).toInt(),
      user: SalarySlipUser.fromJson(json['user'] as Map<String, dynamic>),
    );

SalarySlipItem _$SalarySlipItemFromJson(Map<String, dynamic> json) =>
    SalarySlipItem(
      name: json['name'] as String,
      rate: (json['rate'] as num?)?.toDouble(),
      amount: (json['amount'] as num).toDouble(),
    );

SalarySlipResponse _$SalarySlipResponseFromJson(Map<String, dynamic> json) =>
    SalarySlipResponse(
      id: (json['id'] as num).toInt(),
      employee: SalarySlipEmployee.fromJson(
        json['employee'] as Map<String, dynamic>,
      ),
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      brutoSalary: (json['brutoSalary'] as num).toDouble(),
      totalContributions: (json['totalContributions'] as num).toDouble(),
      taxBase: (json['taxBase'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      netSalary: (json['netSalary'] as num).toDouble(),
      status: (json['status'] as num).toInt(),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => SalarySlipItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
