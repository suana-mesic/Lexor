import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_mobile/api_client.dart';
import 'package:lexor_mobile/models/salary_slip_response.dart';
import 'package:lexor_mobile/widgets/error_view.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:lexor_mobile/theme/app_colors.dart';

class SalaryDetailsScreen extends StatefulWidget {
  final SalarySlipResponse slip;

  const SalaryDetailsScreen({super.key, required this.slip});

  @override
  State<SalaryDetailsScreen> createState() => _SalaryDetailsScreenState();
}

class _SalaryDetailsScreenState extends State<SalaryDetailsScreen> {
  SalarySlipResponse? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.get('/SalarySlips/${widget.slip.id}');
      _detail = SalarySlipResponse.fromJson(data);
    } catch (e) {
      _error = messageFor(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmt(double amount) =>
      NumberFormat('#,##0.00', 'de_DE').format(amount);

  @override
  Widget build(BuildContext context) {
    final slip = _detail ?? widget.slip;
    final isPaid = slip.status == SalarySlipStatus.paid.code;
    final monthName = bosnianMonthName(slip.month);

    SalaryItemCategory? cat(int t) => SalarySlipItemType.fromCode(t)?.category;

    final items = _detail?.items ?? [];
    final brutoItems = items
        .where((i) => cat(i.itemType) == SalaryItemCategory.bruto)
        .toList();
    // Everything after bruto is shown in its natural (calculation) order:
    // contributions, personal deduction, tax base, income tax.
    final otherItems = items
        .where((i) => cat(i.itemType) != SalaryItemCategory.bruto)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, monthName),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? ErrorView(message: _error!, onRetry: _fetchDetail)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCard(slip, isPaid),
                          const SizedBox(height: 20),
                          const Text(
                            'Detaljna razrada',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildBreakdownCard(slip, brutoItems, otherItems),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String monthName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      color: AppColors.primary,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Detalji obračuna',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 26,
          ),
          const SizedBox(width: 16),
          const Icon(Icons.person_outline, color: Colors.white, size: 26),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(SalarySlipResponse slip, bool isPaid) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  slip.employeeFullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.successBg : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPaid ? 'Plaćen' : 'Na čekanju',
                  style: TextStyle(
                    color: isPaid ? AppColors.success : AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildSummaryItem('Korigovana bruto', slip.adjustedBruto),
                    _buildSummaryItem('Doprinosi', slip.totalContributions),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildSummaryItem('Porez', slip.tax),
                    _buildSummaryItem('Neto', slip.netSalary, highlight: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double value, {
    bool highlight = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            '${_fmt(value)} KM',
            style: TextStyle(
              fontSize: highlight ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: highlight ? AppColors.primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(
    SalarySlipResponse slip,
    List<SalarySlipItemResponse> brutoItems,
    List<SalarySlipItemResponse> otherItems,
  ) {
    final rows = <Widget>[];

    for (final item in brutoItems) {
      rows.add(_buildItemRow(item));
    }

    if (brutoItems.isNotEmpty) {
      rows.add(_buildSeparatorRow('Korigovana bruto', slip.adjustedBruto));
    }

    for (final item in otherItems) {
      rows.add(_buildItemRow(item));
    }

    rows.add(_buildSeparatorRow('Neto plata', slip.netSalary, isNet: true));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final isLast = entry.key == rows.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(height: 1, thickness: 1, color: Colors.grey[100]),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemRow(SalarySlipItemResponse item) {
    final type = SalarySlipItemType.fromCode(item.itemType);
    final isNeutral = type == SalarySlipItemType.brutoBase ||
        type == SalarySlipItemType.taxBase ||
        type == SalarySlipItemType.personalDeduction;
    final isPositive = item.amount > 0 && !isNeutral;

    final Color amountColor;
    final String amountPrefix;

    if (isNeutral) {
      amountColor = Colors.black87;
      amountPrefix = '';
    } else if (isPositive) {
      amountColor = AppColors.successDark;
      amountPrefix = '+';
    } else {
      amountColor = AppColors.error;
      amountPrefix = '-';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 14)),
                if (item.description != null && item.description!.isNotEmpty)
                  Text(
                    item.description!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$amountPrefix${_fmt(item.amount.abs())} KM',
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparatorRow(String label, double value, {bool isNet = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            '${_fmt(value)} KM',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isNet ? 16 : 14,
              color: isNet ? AppColors.primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
