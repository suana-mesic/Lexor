import 'package:flutter/material.dart';
import 'package:lexor_mobile/widgets/header_actions.dart';
import 'package:lexor_mobile/models/attendance_response.dart';
import 'package:lexor_mobile/models/leave_response.dart';
import 'package:lexor_mobile/providers/attendance_provider.dart';
import 'package:lexor_mobile/providers/leave_provider.dart';
import 'package:lexor_mobile/providers/payroll_settings_provider.dart';
import 'package:lexor_mobile/widgets/error_banner.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lexor_mobile/theme/app_colors.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  bool _isNonWorkDay(DateTime day, PayrollSettingsProvider settings) =>
      !settings.isWorkDay(day);

  Color? _getDayColor(
    DateTime day,
    List<AttendanceResponse> attendances,
    List<LeaveResponse> leaves,
    PayrollSettingsProvider settings,
  ) {
    if (_isNonWorkDay(day, settings)) return Colors.grey[200];

    final matchLeave = leaves
        .where(
          (l) =>
              (isSameDay(day, l.dateFrom) || day.isAfter(l.dateFrom)) &&
              (isSameDay(day, l.dateTo) || day.isBefore(l.dateTo)) &&
              l.state == LeaveStateType.approved.apiValue,
        )
        .firstOrNull;

    if (day.isAfter(DateTime.now())) {
      if (matchLeave != null) {
        return matchLeave.leaveType.isPaid
            ? AppColors.primary
            : AppColors.error;
      }
      return null;
    }

    final matchAttendance = attendances.where(
      (a) =>
          a.date.year == day.year &&
          a.date.month == day.month &&
          a.date.day == day.day,
    );

    if (matchAttendance.isEmpty && matchLeave == null) {
      return isSameDay(day, DateTime.now()) ? null : Colors.grey[200];
    }
    if (matchLeave != null) {
      return matchLeave.leaveType.isPaid
          ? AppColors.primary
          : AppColors.error;
    }
    return AppColors.success;
  }

  AttendanceResponse? findMatch(
    DateTime day,
    List<AttendanceResponse> attendances,
  ) {
    final match = attendances.where(
      (a) =>
          a.date.year == day.year &&
          a.date.month == day.month &&
          a.date.day == day.day,
    );
    if (match.isEmpty) return null;
    return match.firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).fetchAttendances(now.year, now.month);

      Provider.of<LeaveProvider>(
        context,
        listen: false,
      ).fetchLeaves(year: now.year, month: now.month);

      Provider.of<PayrollSettingsProvider>(
        context,
        listen: false,
      ).fetchCurrentSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: true,
    );
    final leaveProvider = Provider.of<LeaveProvider>(context, listen: true);
    final settings = Provider.of<PayrollSettingsProvider>(context, listen: true);

    final attendances = attendanceProvider.attendances;
    final leaves = leaveProvider.leaves;
    final errorMessage = attendanceProvider.error ?? leaveProvider.error;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (errorMessage != null) ...[
                ErrorBanner(
                  message: errorMessage,
                  onRetry: () {
                    attendanceProvider.fetchAttendances(
                      _focusedDay.year,
                      _focusedDay.month,
                    );
                    leaveProvider.fetchLeaves(
                      year: _focusedDay.year,
                      month: _focusedDay.month,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
              _buildCalendar(attendances, leaves, settings),
              const SizedBox(height: 16),
              if (_selectedDay != null)
                _buildDayDetails(_selectedDay!, attendances, leaves, settings),
            ],
          ),
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
            'Moje prisustvo',
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

  Widget _buildCalendar(
    List<AttendanceResponse> attendances,
    List<LeaveResponse> leaves,
    PayrollSettingsProvider settings,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime(2022),
              lastDay: DateTime(2030),
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
                Provider.of<AttendanceProvider>(
                  context,
                  listen: false,
                ).fetchAttendances(focusedDay.year, focusedDay.month);
                Provider.of<LeaveProvider>(
                  context,
                  listen: false,
                ).fetchLeaves(year: focusedDay.year, month: focusedDay.month);
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) =>
                    '${bosnianMonths[date.month - 1]} ${date.year}',
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.primary,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  const days = [
                    'Pon',
                    'Uto',
                    'Sri',
                    'Čet',
                    'Pet',
                    'Sub',
                    'Ned',
                  ];
                  return Center(
                    child: Text(
                      days[day.weekday - 1],
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                },
                defaultBuilder: (context, day, focusedDay) {
                  final color = _getDayColor(day, attendances, leaves, settings);
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: color != null && color != Colors.grey[200]
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  final color = _getDayColor(day, attendances, leaves, settings);
                  final hasColor = color != null && color != Colors.grey[200];
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black87, width: 2.5),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: hasColor ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  final color = _getDayColor(day, attendances, leaves, settings);
                  final hasColor = color != null && color != Colors.grey[200];
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: hasColor ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem(AppColors.success, 'Radni dan'),
                  const SizedBox(height: 8),
                  _legendItem(AppColors.error, 'Neplaćen odmor'),
                ],
              ),
              const SizedBox(width: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem(AppColors.primary, 'Plaćen odmor'),
                  const SizedBox(height: 8),
                  _legendItem(Colors.grey[200]!, 'Neradni dan'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildDayDetails(
    DateTime day,
    List<AttendanceResponse> attendances,
    List<LeaveResponse> leaves,
    PayrollSettingsProvider settings,
  ) {
    final record = findMatch(day, attendances);
    final isWeekend = _isNonWorkDay(day, settings);
    final isFuture = day.isAfter(DateTime.now());
    final matchLeave = leaves
        .where(
          (l) =>
              (isSameDay(day, l.dateFrom) || day.isAfter(l.dateFrom)) &&
              (isSameDay(day, l.dateTo) || day.isBefore(l.dateTo)) &&
              l.state == LeaveStateType.approved.apiValue,
        )
        .firstOrNull;

    String formatTime(DateTime? dt) {
      if (dt == null) return '--:--';
      final local = dt.toLocal();
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }

    Widget buildInfoMessage(IconData icon, Color color, String message) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalji za ${day.day}. ${bosnianMonths[day.month - 1]} ${day.year}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (isWeekend)
            buildInfoMessage(
              Icons.weekend,
              Colors.grey,
              'Odabrani dan je neradni dan — nema radnog vremena.',
            )
          else if (matchLeave != null)
            buildInfoMessage(
              Icons.beach_access,
              matchLeave.leaveType.isPaid
                  ? AppColors.primary
                  : AppColors.error,
              'Odobreno ${matchLeave.leaveType.isPaid ? 'plaćeno' : 'neplaćeno'} odsustvo — nema evidencije dolaska.',
            )
          else if (isSameDay(day, DateTime.now())) ...[
            _buildDetailRow(
              Icons.login,
              AppColors.success,
              'Dolazak',
              record != null
                  ? formatTime(record.dateTimeEntered)
                  : 'Nema dolazne evidencije',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.logout,
              AppColors.error,
              'Odlazak',
              record != null
                  ? formatTime(record.dateTimeLeft)
                  : 'Nema odlazne evidencije',
            ),
          ]
          else if (isFuture && record == null)
            buildInfoMessage(
              Icons.event_busy,
              Colors.grey,
              'Nema informacija za odabrani dan jer je u budućnosti.',
            )
          else if (record == null)
            buildInfoMessage(
              Icons.info_outline,
              Colors.orange,
              'Nema informacija za odabrani dan jer ste odabrali neradni ili slobodan dan.',
            )
          else ...[
            _buildDetailRow(
              Icons.login,
              AppColors.success,
              'Dolazak',
              formatTime(record.dateTimeEntered),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.logout,
              AppColors.error,
              'Odlazak',
              formatTime(record.dateTimeLeft),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    Color color,
    String label,
    String time,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              time,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}
