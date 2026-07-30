import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lexor_desktop/models/absence_forecast_response.dart';
import 'package:lexor_desktop/providers/absence_prediction_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:provider/provider.dart';

class AbsencePredictionScreen extends StatefulWidget {
  const AbsencePredictionScreen({super.key});

  @override
  State<AbsencePredictionScreen> createState() =>
      _AbsencePredictionScreenState();
}

class _AbsencePredictionScreenState extends State<AbsencePredictionScreen> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day);
    _to = _from.add(const Duration(days: 14));
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  void _run() {
    Provider.of<AbsencePredictionProvider>(
      context,
      listen: false,
    ).fetchForecast(_from, _to);
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AbsencePredictionProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildControls(),
          const SizedBox(height: 20),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        _dateField('Od', _from, () => _pickDate(isFrom: true)),
        const SizedBox(width: 16),
        _dateField('Do', _to, () => _pickDate(isFrom: false)),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _run,
          icon: const Icon(Icons.insights_outlined),
          label: const Text('Prognoziraj'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ', style: const TextStyle(color: Colors.grey)),
            Text(
              '${value.day}.${value.month}.${value.year}.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today_outlined, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AbsencePredictionProvider provider) {
    if (provider.isLoading && provider.forecast == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Text(provider.error!, style: const TextStyle(color: Colors.red)),
      );
    }
    final data = provider.forecast;
    if (data == null || data.days.isEmpty) {
      return const Center(child: Text('Nema podataka za odabrani period.'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.metrics != null) _buildMetrics(data.metrics!),
          const SizedBox(height: 20),
          _card(
            'Očekivani broj odsutnih po danu',
            SizedBox(height: 240, child: _buildChart(data)),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDepartments(data)),
              const SizedBox(width: 20),
              Expanded(child: _buildEmployees(data)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(AbsenceModelMetrics m) {
    Widget tile(String label, String value) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        tile('AUC', m.auc.toStringAsFixed(3)),
        tile('F1', m.f1.toStringAsFixed(3)),
        tile('Preciznost', m.precision.toStringAsFixed(3)),
        tile('Odziv', m.recall.toStringAsFixed(3)),
        tile('Prag', m.bestThreshold.toStringAsFixed(2)),
        tile('Uzoraka', m.sampleCount.toString()),
      ],
    );
  }

  Widget _buildChart(AbsenceForecastResponse data) {
    final maxVal = data.days
        .map((d) => d.expectedAbsences)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = (maxVal < 3 ? 3 : maxVal + 1).ceilToDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 30,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.days.length) {
                  return const SizedBox.shrink();
                }
                final d = data.days[i].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${d.day}.${d.month}.',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (int i = 0; i < data.days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data.days[i].expectedAbsences,
                  color: AppColors.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDepartments(AbsenceForecastResponse data) {
    return _card(
      'Očekivana odsustva po odjelu (osobo-dani)',
      Column(
        children: data.departments
            .map(
              (d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${d.department} (${d.employeeCount})'),
                    ),
                    Text(
                      d.expectedAbsenceDays.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEmployees(AbsenceForecastResponse data) {
    final top = data.employees.take(10).toList();
    return _card(
      'Najrizičniji uposlenici',
      Column(
        children: top.map((e) {
          final threshold = data.metrics?.bestThreshold ?? 0.5;
          final color = e.averageProbability >= threshold
              ? Colors.red
              : (e.averageProbability >= threshold / 2
                    ? Colors.orange
                    : Colors.green);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.fullName + (e.hasPlannedLeave ? '  (godišnji)' : ''),
                  ),
                ),
                Text(
                  '${(e.averageProbability * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
