import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lexor_desktop/config/api_config.dart';
import 'package:lexor_desktop/helpers/pdf_download.dart';
import 'package:lexor_desktop/models/salary_slip_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_shared/lexor_shared.dart';

class SalarySlipProvider extends BaseProvider<SalarySlipResponse> {
  SalarySlipProvider() : super('SalarySlips');

  @override
  SalarySlipResponse fromJson(data) => SalarySlipResponse.fromJson(data);

  /// Report 1: a single employee's payslip PDF.
  Future<String?> downloadSlipPdf(int id, String defaultName) =>
      downloadPdf('/SalarySlips/$id/pdf', defaultName);

  /// Report 2: the summary PDF for paid salaries in a period, optionally scoped to a
  /// single employee (matches whatever the reports table is currently showing).
  Future<String?> downloadMonthlyReport(int year, int month, {int? employeeId}) {
    final employeeParam = employeeId == null ? '' : '&employeeId=$employeeId';
    return downloadPdf(
      '/SalarySlips/report/pdf?year=$year&month=$month$employeeParam',
      'izvjestaj-plata-$year-${month.toString().padLeft(2, '0')}.pdf',
    );
  }

  /// Runs payroll for the whole period (all active employees) -> Pending.
  /// Returns the number of payslips actually generated (0 = no eligible contracts).
  Future<int> calculate(int year, int month) =>
      _postForCount('calculate', {'year': year, 'month': month});

  /// Pending -> Approved.
  Future<void> approveAll(int year, int month) =>
      _post('mark-all-approved', {'year': year, 'month': month});
  Future<void> approveSingle(int year, int month, int employeeId) => _post(
      'mark-single-approved',
      {'year': year, 'month': month, 'employeeId': employeeId});

  /// Approved -> Paid.
  Future<void> payAll(int year, int month) =>
      _post('mark-all-paid', {'year': year, 'month': month});
  Future<void> paySingle(int year, int month, int employeeId) => _post(
      'mark-single-paid',
      {'year': year, 'month': month, 'employeeId': employeeId});

  Future<void> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/SalarySlips/$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.accessToken}',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(ApiError.fromResponse(res));
    }
  }

  /// Same as [_post] but returns the integer body (a generated/affected count).
  Future<int> _postForCount(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/SalarySlips/$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.accessToken}',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(ApiError.fromResponse(res));
    }
    return int.tryParse(res.body.trim()) ?? 0;
  }
}
