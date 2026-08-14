import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    Widget tile(String label, String value, String info) => Tooltip(
      message: info,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );

    final tiles = [
      tile('AUC', m.auc.toStringAsFixed(3),
          'AUC – sposobnost modela da razlikuje one koji će biti odsutni od onih koji neće. 1.0 = savršeno, 0.5 = nasumično pogađanje.'),
      tile('F1', m.f1.toStringAsFixed(3),
          'F1 – balans (harmonijska sredina) između preciznosti i odziva. Bliže 1 je bolje.'),
      tile('Preciznost', m.precision.toStringAsFixed(3),
          'Preciznost – od svih koje je model označio kao "odsutan", koliki dio ih je stvarno bio odsutan.'),
      tile('Odziv', m.recall.toStringAsFixed(3),
          'Odziv – od svih koji su stvarno bili odsutni, koliki dio ih je model uspio prepoznati.'),
      tile('Prag', m.bestThreshold.toStringAsFixed(2),
          'Prag odluke – granica vjerovatnoće iznad koje se predikcija računa kao "odsutan". Odabran je tako da maksimizira F1.'),
      tile('Uzoraka', m.sampleCount.toString(),
          'Broj (uposlenik × dan) zapisa iz historije korištenih za treniranje i evaluaciju modela.'),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }

  Widget _buildChart(AbsenceForecastResponse data) {
    final maxVal = data.days
        .map((d) => d.expectedAbsences)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = (maxVal < 3 ? 3 : maxVal + 1).ceilToDouble();
    // Keep ~5 labels on the y-axis so they don't pile up on top of each other when maxY is large.
    final yStep = maxY / 5 <= 1 ? 1.0 : (maxY / 5).ceilToDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yStep,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: yStep,
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
    final depts = data.departments;
    final maxVal = depts.isEmpty
        ? 1.0
        : depts.map((d) => d.expectedAbsenceDays).reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    final workdays = data.days.length;
    final fmt = DateFormat('dd.MM.yyyy');
    final range = data.days.isEmpty
        ? ''
        : '${fmt.format(data.days.first.date)} - ${fmt.format(data.days.last.date)}';

    return _card(
      'Očekivani dani odsustva po odjelu',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final d in depts) _deptBar(d, safeMax, workdays, range)],
      ),
      info: _departmentsInfo(depts, workdays),
    );
  }

  String _departmentsInfo(List<DepartmentAbsenceForecast> depts, int workdays) {
    if (depts.isEmpty || workdays == 0) {
      return 'Očekivani broj dana odsustva u odabranom periodu, izračunat '
          'sabiranjem vjerovatnoća za svakog uposlenika u odjelu za svaki dan '
          'u periodu.';
    }
    // Always use the same department as the worked example (alphabetically first),
    // so the explanation is stable and not tied to the value-sorted list order.
    final ex = (depts.toList()
          ..sort((a, b) => a.department.compareTo(b.department)))
        .first;
    final product = ex.employeeCount * workdays;
    return 'Očekivani broj dana odsustva u odabranom periodu, izračunat sabiranjem '
        'vjerovatnoća za svakog uposlenika u datom odjelu u svakom danu u odabranom '
        'periodu. Npr. ako ${ex.department} odjel ima ${ex.employeeCount} '
        'uposlenika, a odabrani period ima $workdays dana, onda je to '
        '${ex.employeeCount} × $workdays = $product vjerovatnoća koje se sabiraju. '
        'Finalni rezultat je broj ${ex.expectedAbsenceDays.toStringAsFixed(1)} koji '
        'je zaokružen radi lakšeg tumačenja. Taj broj predstavlja broj odsustava u '
        'odabranom periodu — u ovom primjeru ~${ex.expectedAbsenceDays.round()} '
        'odsustava u periodu od $workdays dana, pri čemu jedna osoba može biti '
        'odsutna više puta.';
  }

  Widget _deptBar(
    DepartmentAbsenceForecast d,
    double maxVal,
    int workdays,
    String range,
  ) {
    final fraction = (d.expectedAbsenceDays / maxVal).clamp(0.0, 1.0);
    final rounded = d.expectedAbsenceDays.round();
    return Tooltip(
      message:
          '${d.department}: očekivano ~$rounded ${rounded == 1 ? 'dan' : 'dana'} '
          'odsustva ukupno u $workdays dana${range.isEmpty ? '' : ' od $range'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('${d.department} (${d.employeeCount})')),
                Text(
                  '≈$rounded',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployees(AbsenceForecastResponse data) {
    final top = data.employees.take(10).toList();
    final workdays = data.days.length;
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
          final pct = (e.averageProbability * 100).toStringAsFixed(0);
          final expDays = (e.averageProbability * workdays).round();
          return Tooltip(
            message:
                '${e.fullName}: u prosjeku $pct% šanse za odsustvo svaki dan u '
                'periodu — očekivano ~$expDays od $workdays dana odsustva.',
            child: Padding(
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
                    '$pct%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      info:
          'Prosječna dnevna vjerovatnoća da će uposlenik biti odsutan u odabranom '
          'periodu. Npr. 82% znači da se u prosjeku očekuje odsustvo ~82% radnih '
          'dana (npr. ~9 od 11). Boja: crveno = iznad praga rizika, zeleno = nizak rizik.',
    );
  }

  Widget _card(String title, Widget child, {String? info}) {
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
          Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (info != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: info,
                  child: Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
