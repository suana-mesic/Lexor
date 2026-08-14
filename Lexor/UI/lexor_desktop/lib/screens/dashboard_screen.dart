import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lexor_desktop/models/dashboard_response.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/providers/dashboard_provider.dart';
import 'package:lexor_desktop/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:lexor_desktop/theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context, listen: true);

    if (provider.isLoading && provider.dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return _buildError(provider);
    }

    final data = provider.dashboard;
    if (data == null) {
      return const Center(child: Text('Nema podataka'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // How many rows the stat cards will wrap into (matches _buildStatCards).
        final statRows = constraints.maxWidth >= 1100
            ? 1
            : (constraints.maxWidth >= 700 ? 2 : 4);
        // Estimated height of the stat-cards block.
        final statBlock = statRows * 116.0 + (statRows - 1) * 16.0;
        // Minimum comfortable height for the 2-row chart grid.
        const minGrid = 520.0;
        // Available height inside the 24px padding.
        final available = constraints.maxHeight - 48;
        final fitsOnScreen = available >= statBlock + 24 + minGrid;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCards(data),
            const SizedBox(height: 24),
            fitsOnScreen
                ? Expanded(child: _buildChartsGrid(data, flexible: true))
                : _buildChartsGrid(data),
          ],
        );

        return fitsOnScreen
            ? Padding(padding: const EdgeInsets.all(24), child: content)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: content,
              );
      },
    );
  }

  Widget _buildError(DashboardProvider provider) {
    final isSession = provider.sessionExpired;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSession ? Icons.lock_clock_outlined : Icons.error_outline,
              size: 56,
              color: isSession
                  ? AppColors.warning
                  : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error ?? 'Došlo je do greške.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              icon: Icon(isSession ? Icons.login : Icons.refresh),
              label: Text(isSession ? 'Prijavi se ponovo' : 'Pokušaj ponovo'),
              onPressed: () {
                if (isSession) {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                } else {
                  provider.fetchDashboard();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(DashboardResponse data) {
    final cards = <Widget>[
      _buildStatCard(
        label: 'Ukupno uposlenika',
        value: '${data.totalEmployees}',
        subtitle: '↑ ${data.newEmployeesThisMonth} novih ovog mjeseca',
        subtitleColor: AppColors.success,
        iconBg: AppColors.indigoBg,
        icon: Icons.people_outline,
        iconColor: AppColors.indigo,
      ),
      _buildStatCard(
        label: 'Aktivni ugovori',
        value: '${data.activeContracts}',
        subtitle: '${data.expiringContractsSoon} ugovora ističe uskoro',
        subtitleColor: Colors.grey,
        iconBg: AppColors.successBg,
        icon: Icons.description_outlined,
        iconColor: AppColors.successBright,
      ),
      _buildStatCard(
        label: 'Stopa prisustva',
        value: '${data.attendanceRate}%',
        subtitle:
            '${data.attendanceRateChange >= 0 ? '↑' : '↓'} ${data.attendanceRateChange.abs()}% od prošle sedmice',
        subtitleColor: data.attendanceRateChange >= 0
            ? AppColors.success
            : AppColors.error,
        iconBg: AppColors.warningBg,
        icon: Icons.calendar_today_outlined,
        iconColor: AppColors.warning,
      ),
      _buildStatCard(
        label: 'Zahtjevi na čekanju',
        value: '${data.pendingLeaves}',
        subtitle: '${data.pendingVacationLeaves} zahtjeva za odmor',
        subtitleColor: Colors.grey,
        iconBg: AppColors.errorBg,
        icon: Icons.inbox_outlined,
        iconColor: AppColors.errorBright,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;
        if (constraints.maxWidth >= 1100) {
          columns = 4;
        } else if (constraints.maxWidth >= 700) {
          columns = 2;
        } else {
          columns = 1;
        }
        return _buildCardGrid(cards, columns);
      },
    );
  }

  Widget _buildCardGrid(List<Widget> cards, int columns) {
    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += columns) {
      final rowCards = cards.skip(i).take(columns).toList();
      final children = <Widget>[];
      for (int j = 0; j < rowCards.length; j++) {
        children.add(rowCards[j]);
        if (j < rowCards.length - 1) {
          children.add(const SizedBox(width: 16));
        }
      }
      while (children.length < columns * 2 - 1) {
        children.add(const SizedBox(width: 16));
        children.add(const Expanded(child: SizedBox()));
      }
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
      if (i + columns < cards.length) {
        rows.add(const SizedBox(height: 16));
      }
    }
    return Column(children: rows);
  }

  Widget _buildChartCard({
    required String title,
    required Widget chart,
    double height = 280,
    bool flexible = false,
  }) {
    final chartArea = flexible
        ? Expanded(child: chart)
        : SizedBox(height: height, child: chart);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          chartArea,
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(DashboardResponse data, {bool flexible = false}) {
    final maxCount = data.leavesByDay
        .map((d) => d.count)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxCount < 5 ? 5 : maxCount + 2).toDouble();

    final spots = <FlSpot>[];
    for (int i = 0; i < data.leavesByDay.length; i++) {
      spots.add(FlSpot(i.toDouble(), data.leavesByDay[i].count.toDouble()));
    }

    return _buildChartCard(
      title: 'Broj zahtjeva u zadnjih 7 dana',
      flexible: flexible,
      chart: LineChart(
        LineChartData(
          minX: 0,
          maxX: (data.leavesByDay.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _yInterval(maxY),
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey[200]!, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _yInterval(maxY),
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.leavesByDay.length) {
                    return const SizedBox.shrink();
                  }
                  Widget label = Text(
                    data.leavesByDay[i].dayLabel,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  );
                  if (i == data.leavesByDay.length - 1) {
                    label = Transform.translate(
                      offset: const Offset(-30, 0),
                      child: label,
                    );
                  } else if (i == 0) {
                    label = Transform.translate(
                      offset: const Offset(30, 0),
                      child: label,
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: label,
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
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A "nice" Y-axis step that keeps ~5-6 labels regardless of the data range,
  // so labels don't overlap into an unreadable smear on large counts.
  double _yInterval(double maxY) {
    final raw = maxY / 5;
    return raw <= 1 ? 1 : raw.ceilToDouble();
  }

  Widget _buildBarChart(DashboardResponse data, {bool flexible = false}) {
    final maxCount = data.leavesByType
        .map((t) => t.count)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxCount < 5 ? 5 : maxCount + 2).toDouble();

    final barColors = [
      AppColors.primary,
      AppColors.indigo,
      AppColors.successBright,
      AppColors.warning,
      AppColors.error,
      AppColors.purple,
    ];

    return _buildChartCard(
      title: 'Zahtjevi po tipu',
      flexible: flexible,
      chart: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _yInterval(maxY),
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey[200]!, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _yInterval(maxY),
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.leavesByType.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data.leavesByType[i].typeName,
                      textAlign: TextAlign.center,
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
            for (int i = 0; i < data.leavesByType.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data.leavesByType[i].count.toDouble(),
                    color: barColors[i % barColors.length],
                    width: 28,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart(DashboardResponse data, {bool flexible = false}) {
    if (data.leavesByStatus.isEmpty) {
      return _buildChartCard(
        title: 'Raspodjela zahtjeva po statusu',
        flexible: flexible,
        chart: const Center(child: Text('Nema podataka')),
      );
    }

    final colorMap = {
      LeaveStateType.pending: AppColors.warning,
      LeaveStateType.approved: AppColors.successBright,
      LeaveStateType.rejected: AppColors.error,
      LeaveStateType.cancelled: AppColors.grey,
      LeaveStateType.completed: AppColors.info,
    };

    final total = data.leavesByStatus
        .map((s) => s.count)
        .fold<int>(0, (a, b) => a + b);

    return _buildChartCard(
      title: 'Raspodjela zahtjeva po statusu',
      flexible: flexible,
      chart: Row(
        children: [
          Expanded(
            flex: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The radius is derived from the available space so the donut never overflows its box.
                final outer = constraints.biggest.shortestSide / 2;
                final centerRadius = outer * 0.42;
                final sectionRadius = outer * 0.50;
                return PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: centerRadius,
                    sections: [
                      for (final item in data.leavesByStatus)
                        PieChartSectionData(
                          value: item.count.toDouble(),
                          color:
                              colorMap[LeaveStateType.fromApi(item.status)] ??
                              Colors.grey,
                          title: total > 0
                              ? '${((item.count / total) * 100).toStringAsFixed(0)}%'
                              : '',
                          radius: sectionRadius,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in data.leavesByStatus)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color:
                                colorMap[LeaveStateType.fromApi(item.status)] ??
                                Colors.grey,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${LeaveStateType.fromApi(item.status)?.label ?? item.status}: ${item.count}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart(DashboardResponse data, {bool flexible = false}) {
    final metrics = data.hrMetrics;
    final values = [
      metrics.attendanceRate,
      metrics.contractFillRate,
      metrics.leaveApprovalRate,
      metrics.salaryPaymentRate,
      metrics.activeEmployeeRate,
    ];
    final labels = [
      'Prisustvo',
      'Ugovori',
      'Odobreni\nzahtjevi',
      'Isplaćene\nplate',
      'Aktivni\nuposlenici',
    ];

    return _buildChartCard(
      title: 'Pregled HR metrika',
      height: 320,
      flexible: flexible,
      chart: RadarChart(
        RadarChartData(
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.transparent),
          titlePositionPercentageOffset: 0.18,
          getTitle: (index, angle) =>
              RadarChartTitle(text: labels[index], angle: 0),
          tickCount: 4,
          ticksTextStyle: const TextStyle(
            color: Colors.transparent,
            fontSize: 0,
          ),
          tickBorderData: BorderSide(color: Colors.grey[200]!, width: 1),
          gridBorderData: BorderSide(color: Colors.grey[200]!, width: 1),
          dataSets: [
            RadarDataSet(
              fillColor: AppColors.primary.withOpacity(0.2),
              borderColor: AppColors.primary,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: [for (final v in values) RadarEntry(value: v)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsGrid(DashboardResponse data, {bool flexible = false}) {
    final charts = <Widget>[
      _buildLineChart(data, flexible: flexible),
      _buildBarChart(data, flexible: flexible),
      _buildDonutChart(data, flexible: flexible),
      _buildRadarChart(data, flexible: flexible),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 1000;

        if (useTwoColumns) {
          // Both cards in a pair must be equal height. In flexible mode the
          // parent Expanded bounds the height so stretch works directly; in
          // scroll mode height is unbounded, so IntrinsicHeight makes both
          // cards match the taller one.
          Widget pairRow(Widget a, Widget b) {
            final row = Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: a),
                const SizedBox(width: 16),
                Expanded(child: b),
              ],
            );
            return flexible ? row : IntrinsicHeight(child: row);
          }

          final row1 = pairRow(charts[0], charts[1]);
          final row2 = pairRow(charts[2], charts[3]);

          return Column(
            children: [
              flexible ? Expanded(child: row1) : row1,
              const SizedBox(height: 16),
              flexible ? Expanded(child: row2) : row2,
            ],
          );
        } else {
          return Column(
            children: [
              for (int i = 0; i < charts.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                charts[i],
              ],
            ],
          );
        }
      },
    );
  }
}
