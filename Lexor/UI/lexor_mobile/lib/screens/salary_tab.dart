import 'package:flutter/material.dart';
import 'package:lexor_mobile/widgets/header_actions.dart';
import 'package:intl/intl.dart';
import 'package:lexor_mobile/models/salary_slip_response.dart';
import 'package:lexor_mobile/providers/salary_slip_provider.dart';
import 'package:lexor_mobile/screens/salary_details_screen.dart';
import 'package:lexor_mobile/widgets/error_view.dart';
import 'package:provider/provider.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:lexor_mobile/theme/app_colors.dart';

class SalaryTab extends StatefulWidget {
  const SalaryTab({super.key});

  @override
  State<SalaryTab> createState() => _SalaryTabState();
}

class _SalaryTabState extends State<SalaryTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalarySlipProvider>(
        context,
        listen: false,
      ).fetchSalarySlips(reset: true);
    });

    _scrollController.addListener(() {
      final provider = Provider.of<SalarySlipProvider>(context, listen: false);
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        provider.fetchSalarySlips();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalarySlipProvider>(context, listen: true);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (provider.error != null && provider.salarySlips.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: ErrorView(
                  message: provider.error!,
                  onRetry: () => provider.fetchSalarySlips(reset: true),
                ),
              )
            else if (!provider.isLoading && provider.salarySlips.isEmpty)
              _buildEmpty()
            else
              ...provider.salarySlips.map(
                (slip) => _buildSalarySlipCard(context, slip),
              ),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Moje platne liste',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          HeaderActions(),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nema platnih listi',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ovdje će se prikazati vaše platne liste\nkada budu obračunate.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySlipCard(BuildContext context, SalarySlipResponse slip) {
    final isPaid = slip.status == SalarySlipStatus.paid.code;
    final monthName = bosnianMonthName(slip.month);

    final formatted = NumberFormat('#,##0.00', 'de_DE').format(slip.netSalary);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SalaryDetailsScreen(slip: slip)),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$monthName ${slip.year}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? AppColors.successBg
                              : AppColors.warningBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPaid ? 'Plaćen' : 'Na čekanju',
                          style: TextStyle(
                            color: isPaid
                                ? AppColors.success
                                : AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$formatted KM',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Neto plata',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
