import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lexor_desktop/models/fraud_detection_response.dart';
import 'package:lexor_desktop/providers/fraud_detection_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:provider/provider.dart';

/// Attendance fraud detection (HR manager + administrator): shows the model's
/// train/test metrics and charts of the flagged records by month and weekday.
class FraudDetectionScreen extends StatefulWidget {
  const FraudDetectionScreen({super.key});

  @override
  State<FraudDetectionScreen> createState() => _FraudDetectionScreenState();
}

class _FraudDetectionScreenState extends State<FraudDetectionScreen> {
  // Attendance exists only on working days, so weekends never appear.
  static const _weekdays = ['Pon', 'Uto', 'Sri', 'Čet', 'Pet'];
  static const _monthsShort = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Maj', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dec',
  ];

  // Independent slicers for the weekday chart: null = no filter (all years / all months).
  int? _selectedYear;
  int? _selectedMonth;

  // Year slicer for the monthly chart: null = whole timeline.
  int? _monthlyYear;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FraudDetectionProvider>().fetch(),
    );
  }

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FraudDetectionProvider>();

    if (provider.isLoading && provider.data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.data == null) {
      return Center(child: Text(provider.error!));
    }
    final d = provider.data;
    if (d == null || d.metrics.train.sampleCount == 0) {
      return const Center(
        child: Text('Model još nije treniran — nema podataka za prikaz.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detekcija prevara u evidenciji rada',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Logistička regresija (ML.NET) nad ${d.metrics.train.sampleCount + d.metrics.test.sampleCount} zapisa — hronološki 80:20 trening/test.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          _kpiCards(d),
          const SizedBox(height: 24),
          _card('Metrike modela (trening vs. test)', _metricsTable(d.metrics)),
          const SizedBox(height: 20),
          _card('Broj detektovanih prevara po mjesecima', _monthlyChart(d.detectedFrauds)),
          const SizedBox(height: 20),
          _card('Detektovane prevare po danima u sedmici', _weekdaySection(d.detectedFrauds)),
        ],
      ),
    );
  }

  // ----- KPI cards -----

  Widget _kpiCards(FraudDetectionResponse d) {
    final flagged = d.detectedFrauds.length;
    final truePositives = d.detectedFrauds.where((f) => f.actuallyFraud).length;
    final falseAlarms = flagged - truePositives;
    final cards = [
      ('Označeno kao prevara', '$flagged', AppColors.error),
      ('Stvarne prevare među označenim', '$truePositives', AppColors.success),
      ('Lažne uzbune', '$falseAlarms', AppColors.warning),
      ('F1 (test)', d.metrics.test.f1Score.toStringAsFixed(3), AppColors.primary),
    ];
    // Stretch the cards across the full row width (4 -> 2 -> 1 per row depending on
    // available space) so long labels stay readable on any window size.
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 16.0;
      final w = constraints.maxWidth;
      final perRow = w >= 900 ? 4 : (w >= 460 ? 2 : 1);
      final width = (w - gap * (perRow - 1)) / perRow;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final c in cards) _kpi(c.$1, c.$2, c.$3, width)],
      );
    });
  }

  Widget _kpi(String label, String value, Color accent, double width) {
    return Container(
      width: width,
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
          // Fixed two-line slot so every card keeps the same height in the row.
          SizedBox(
            height: 36,
            child: Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
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

  // ----- Metrics table: one row per split, so train/test compare at a glance -----

  Widget _metricsTable(FraudMetrics m) {
    DataRow row(String name, FraudSplitMetrics s) => DataRow(cells: [
          DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
          DataCell(Text(s.f1Score.toStringAsFixed(3))),
          DataCell(Text(s.accuracy.toStringAsFixed(3))),
          DataCell(Text(s.precision.toStringAsFixed(3))),
          DataCell(Text(s.recall.toStringAsFixed(3))),
          DataCell(Text(s.areaUnderRocCurve.toStringAsFixed(3))),
          DataCell(Text('${s.sampleCount}')),
          DataCell(Text('${s.fraudCount}')),
        ]);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        columns: [
          DataColumn(label: _header('Skup',
              'Trening = najstarijih 80% zapisa (model uči); test = najnovijih 20% (provjera na neviđenim podacima).')),
          DataColumn(label: _header('F1',
              'Harmonijska sredina preciznosti i odziva (0–1, veće je bolje) — glavna mjera na neuravnoteženim podacima.')),
          DataColumn(label: _header('Tačnost',
              'Udio svih zapisa koji su ispravno klasifikovani (varljiva kad su prevare rijetke).')),
          DataColumn(label: _header('Preciznost',
              'Od zapisa označenih kao prevara, koliko ih stvarno jeste prevara (mjeri lažne uzbune).')),
          DataColumn(label: _header('Odziv',
              'Od svih stvarnih prevara, koliko ih je model uhvatio (mjeri propuštene prevare).')),
          DataColumn(label: _header('AUC',
              'Koliko dobro model rangira prevare iznad normalnih zapisa (0.5 = nasumično, 1 = savršeno).')),
          DataColumn(label: _header('Zapisa', 'Ukupan broj zapisa u skupu.')),
          DataColumn(label: _header('Prevara', 'Broj stvarnih prevara u skupu.')),
        ],
        rows: [
          row('Trening (80%)', m.train),
          row('Test (20%)', m.test),
        ],
      ),
    );
  }

  // Table header with a short hover explanation of the metric.
  Widget _header(String text, String tooltip) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Text(text),
    );
  }

  // ----- Chart: detected frauds per calendar month -----

  Widget _monthlyChart(List<FraudFlag> flags) {
    if (flags.isEmpty) {
      return const Text('Model nije označio nijedan zapis.',
          style: TextStyle(color: Colors.grey));
    }

    // Year slicer: show the whole timeline or a single year's Jan-Dec.
    final years = flags.map((f) => f.date.year).toSet().toList()..sort();
    final filtered = _monthlyYear == null
        ? flags
        : flags.where((f) => f.date.year == _monthlyYear).toList();

    // Count flags per month, then walk the full range so empty months show as 0.
    final counts = <String, int>{};
    for (final f in filtered) {
      counts.update(_monthKey(f.date), (v) => v + 1, ifAbsent: () => 1);
    }
    final dates = filtered.map((f) => f.date).toList();
    final first = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final last = dates.reduce((a, b) => a.isAfter(b) ? a : b);

    final keys = <String>[];
    var cursor = DateTime(first.year, first.month);
    while (!cursor.isAfter(DateTime(last.year, last.month))) {
      keys.add(_monthKey(cursor));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    final values = [for (final k in keys) (counts[k] ?? 0).toDouble()];
    // Whole timeline: compact "M/yy" labels; single year: month names.
    final labels = [
      for (final k in keys)
        _monthlyYear == null
            ? '${int.parse(k.split('-')[1])}/${k.substring(2, 4)}'
            : _monthsShort[int.parse(k.split('-')[1])]
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slicer<int>(
          label: 'Godina',
          allLabel: 'Sve',
          options: years,
          optionLabel: (y) => '$y',
          selected: _monthlyYear,
          onChanged: (v) => setState(() => _monthlyYear = v),
        ),
        const SizedBox(height: 16),
        _barChart(values, labels, AppColors.primary),
      ],
    );
  }

  // ----- Chart: detected frauds per weekday, with year + month slicers -----

  Widget _weekdaySection(List<FraudFlag> flags) {
    // Distinct years/months present in the flags feed the two independent slicers.
    final years = flags.map((f) => f.date.year).toSet().toList()..sort();
    final months = flags.map((f) => f.date.month).toSet().toList()..sort();

    // Both filters apply independently: year only, month only (across years), or both.
    final filtered = flags
        .where((f) =>
            (_selectedYear == null || f.date.year == _selectedYear) &&
            (_selectedMonth == null || f.date.month == _selectedMonth))
        .toList();

    // Bucket by weekday (DateTime.weekday: 1 = Monday ... 5 = Friday).
    final values = List<double>.filled(5, 0);
    for (final f in filtered) {
      final w = f.date.weekday;
      if (w >= 1 && w <= 5) values[w - 1]++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slicer<int>(
          label: 'Godina',
          allLabel: 'Sve',
          options: years,
          optionLabel: (y) => '$y',
          selected: _selectedYear,
          onChanged: (v) => setState(() => _selectedYear = v),
        ),
        const SizedBox(height: 10),
        _slicer<int>(
          label: 'Mjesec',
          allLabel: 'Svi',
          options: months,
          optionLabel: (m) => _monthsShort[m],
          selected: _selectedMonth,
          onChanged: (v) => setState(() => _selectedMonth = v),
        ),
        const SizedBox(height: 16),
        filtered.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nema detektovanih prevara za odabrani filter.',
                    style: TextStyle(color: Colors.grey)),
              )
            : _barChart(values, _weekdays, AppColors.info),
      ],
    );
  }

  // One slicer row: an "all" chip plus one selectable chip per option (Power BI-style).
  Widget _slicer<T>({
    required String label,
    required String allLabel,
    required List<T> options,
    required String Function(T) optionLabel,
    required T? selected,
    required ValueChanged<T?> onChanged,
  }) {
    Widget chip(String text, bool isSelected, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Text(text,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              )),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('$label:', style: TextStyle(color: Colors.grey[700])),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(allLabel, selected == null, () => onChanged(null)),
              for (final o in options)
                chip(optionLabel(o), selected == o, () => onChanged(o)),
            ],
          ),
        ),
      ],
    );
  }

  // ----- Shared bar chart builder -----

  Widget _barChart(List<double> values, List<String> labels, Color color) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    // Round the grid step up so the y-axis labels never crowd together.
    final yStep = maxY / 5 <= 1 ? 1.0 : (maxY / 5).ceilToDouble();

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: yStep,
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${labels[group.x]}: ${rod.toY.round()}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: yStep,
                reservedSize: 34,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[i],
                        style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: color,
                  width: values.length > 12 ? 14 : 26,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
