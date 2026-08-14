import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/models/payroll_dashboard_response.dart';
import 'package:lexor_desktop/providers/payroll_dashboard_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:provider/provider.dart';

class PayrollDashboardScreen extends StatefulWidget {
  const PayrollDashboardScreen({super.key});

  @override
  State<PayrollDashboardScreen> createState() => _PayrollDashboardScreenState();
}

class _PayrollDashboardScreenState extends State<PayrollDashboardScreen> {
  static const _months = [
    '', 'Januar', 'Februar', 'Mart', 'April', 'Maj', 'Juni',
    'Juli', 'August', 'Septembar', 'Oktobar', 'Novembar', 'Decembar',
  ];
  final _money = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<PayrollDashboardProvider>().fetch(),
    );
  }

  String _km(double v) => '${_money.format(v)} KM';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PayrollDashboardProvider>();

    if (provider.isLoading && provider.data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.data == null) {
      return Center(child: Text(provider.error!));
    }
    final d = provider.data;
    if (d == null || !d.hasData) {
      return const Center(
        child: Text('Još nema isplaćenih plata za prikaz.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nadzorna ploča — plate',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Zadnji isplaćeni period: ${_months[d.month]} ${d.year}',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 20),
          _kpiCards(d),
          const SizedBox(height: 24),
          _card(
            'Struktura bruto plate',
            _grossBreakdown(d),
          ),
          const SizedBox(height: 20),
          _card(
            'Top 5 uposlenika po prekovremenim satima',
            _topOvertime(d.topOvertime),
          ),
        ],
      ),
    );
  }

  Widget _kpiCards(PayrollDashboardResponse d) {
    final cards = [
      _kpi('Ukupna neto isplata', _km(d.totalNet), AppColors.success),
      _kpi('Ukupno bruto', _km(d.totalGross), AppColors.primary),
      _kpi('Ukupni doprinosi', _km(d.totalContributions), AppColors.info),
      _kpi('Ukupni porez', _km(d.totalTax), AppColors.warning),
      _kpi('Prosječna neto plata', _km(d.averageNet), AppColors.primary),
      _kpi('Trošak prekovremenih', _km(d.totalOvertime), AppColors.error),
      _kpi('Ukupno prekovremenih sati',
          '${_money.format(d.totalOvertimeHours)} h', AppColors.error),
      _kpi('Uposlenika s prekovremenim', '${d.employeesWithOvertime}', AppColors.info),
      _kpi('Efektivna stopa opterećenja',
          '${d.burdenRate.toStringAsFixed(1)}%', AppColors.warning),
      _kpi('Broj platnih lista', '${d.slipCount}', Colors.grey.shade700),
    ];
    return Wrap(spacing: 16, runSpacing: 16, children: cards);
  }

  Widget _kpi(String label, String value, Color accent) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 34, height: 4, decoration: BoxDecoration(
              color: accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // Horizontal stacked bar: gross = net + contributions + tax.
  Widget _grossBreakdown(PayrollDashboardResponse d) {
    final segments = [
      ('Neto', d.totalNet, AppColors.success),
      ('Doprinosi', d.totalContributions, AppColors.info),
      ('Porez', d.totalTax, AppColors.warning),
    ];
    final total = d.totalNet + d.totalContributions + d.totalTax;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              for (final s in segments)
                Expanded(
                  flex: total <= 0 ? 1 : (s.$2 / total * 1000).round().clamp(1, 1000),
                  child: Container(height: 26, color: s.$3),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            for (final s in segments)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(
                      color: s.$3, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text('${s.$1}: ${_km(s.$2)}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _topOvertime(List<OvertimeLeader> items) {
    if (items.isEmpty) {
      return const Text('Nema prekovremenih sati u ovom periodu.',
          style: TextStyle(color: Colors.grey));
    }
    final maxAmount = items.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final e in items) ...[
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(e.fullName, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxAmount <= 0 ? 0 : e.amount / maxAmount,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: Text(
                  '${e.hours.toStringAsFixed(2)} h · ${_km(e.amount)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
