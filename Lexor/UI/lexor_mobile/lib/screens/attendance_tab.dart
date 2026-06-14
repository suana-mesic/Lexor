import 'package:flutter/material.dart';
import 'package:lexor_mobile/models/attendance_response.dart';
import 'package:lexor_mobile/models/leave_response.dart';
import 'package:lexor_mobile/providers/attendance_provider.dart';
import 'package:lexor_mobile/providers/leave_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

const _bosnianMonths = [
  'Januar',
  'Februar',
  'Mart',
  'April',
  'Maj',
  'Juni',
  'Juli',
  'August',
  'Septembar',
  'Oktobar',
  'Novembar',
  'Decembar',
];

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  bool _isWeekend(DateTime day) => day.weekday == 6 || day.weekday == 7;

  // placeholder — returns null for future days (no background)
  Color? _getDayColor(
    DateTime day,
    List<AttendanceResponse> attendances,
    List<LeaveResponse> leaves,
  ) {
    if (day.weekday == 6 || day.weekday == 7) return Colors.grey[200];

    final matchLeave = leaves
        .where(
          (l) =>
              (isSameDay(day, l.dateFrom) || day.isAfter(l.dateFrom)) &&
              (isSameDay(day, l.dateTo) || day.isBefore(l.dateTo)) &&
              l.state == 'ApprovedLeaveState',
        )
        .firstOrNull;

    if (day.isAfter(DateTime.now())) {
      if (matchLeave != null) {
        return matchLeave.leaveType.isPaid
            ? const Color(0xFF1A237E)
            : const Color(0xFFC62828);
      }
      return null;
    }

    final matchAttendance = attendances.where(
      (a) =>
          a.date.year == day.year &&
          a.date.month == day.month &&
          a.date.day == day.day,
    );

    if (matchAttendance.isEmpty && matchLeave == null) return Colors.grey[200];
    if (matchLeave != null) {
      return matchLeave.leaveType.isPaid
          ? const Color(0xFF1A237E)
          : const Color(0xFFC62828);
    }
    return const Color(0xFF43A047);
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendances = Provider.of<AttendanceProvider>(
      context,
      listen: true,
    ).attendances;

    final leaves = Provider.of<LeaveProvider>(context, listen: true).leaves;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildCalendar(attendances, leaves),
              const SizedBox(height: 16),
              if (_selectedDay != null)
                _buildDayDetails(_selectedDay!, attendances, leaves),
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
        color: const Color(0xFF1A237E),
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
          Row(
            children: [
              Icon(Icons.notifications, color: Colors.white, size: 26),
              SizedBox(width: 16),
              Icon(Icons.person, color: Colors.white, size: 26),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(
    List<AttendanceResponse> attendances,
    List<LeaveResponse> leaves,
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
                    '${_bosnianMonths[date.month - 1]} ${date.year}',
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A237E),
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF1A237E),
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF1A237E),
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
                  final color = _getDayColor(day, attendances, leaves);
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
                          color: color != null && !_isWeekend(day)
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
                  final color = _getDayColor(day, attendances, leaves);
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color ?? const Color(0xFF1A237E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF1A237E),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: _isWeekend(day)
                              ? Colors.black87
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  final color = _getDayColor(day, attendances, leaves);
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF1A237E),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: color != null && !_isWeekend(day)
                              ? Colors.white
                              : Colors.black87,
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
                  _legendItem(const Color(0xFF43A047), 'Radni dan'),
                  const SizedBox(height: 8),
                  _legendItem(const Color(0xFFC62828), 'Neplaćen odmor'),
                ],
              ),
              const SizedBox(width: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem(const Color(0xFF1A237E), 'Plaćen odmor'),
                  const SizedBox(height: 8),
                  _legendItem(Colors.grey[200]!, 'Vikend'),
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
  ) {
    final record = findMatch(day, attendances);
    final isWeekend = day.weekday == 6 || day.weekday == 7;
    final isFuture = day.isAfter(DateTime.now());
    final matchLeave = leaves
        .where(
          (l) =>
              (isSameDay(day, l.dateFrom) || day.isAfter(l.dateFrom)) &&
              (isSameDay(day, l.dateTo) || day.isBefore(l.dateTo)) &&
              l.state == 'ApprovedLeaveState',
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
            'Detalji za ${day.day}. ${_bosnianMonths[day.month - 1]} ${day.year}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (isWeekend)
            buildInfoMessage(
              Icons.weekend,
              Colors.grey,
              'Odabrani dan je vikend — nema radnog vremena.',
            )
          else if (matchLeave != null)
            buildInfoMessage(
              Icons.beach_access,
              matchLeave.leaveType.isPaid
                  ? const Color(0xFF1A237E)
                  : const Color(0xFFC62828),
              'Odobreno ${matchLeave.leaveType.isPaid ? 'plaćeno' : 'neplaćeno'} odsustvo — nema evidencije dolaska.',
            )
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
              const Color(0xFF43A047),
              'Dolazak',
              formatTime(record.dateTimeEntered),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.logout,
              const Color(0xFFC62828),
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
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Text(
              time,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}
