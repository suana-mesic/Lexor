import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_mobile/providers/attendance_provider.dart';
import 'package:lexor_mobile/providers/auth_provider.dart';
import 'package:lexor_mobile/providers/leave_provider.dart';
import 'package:lexor_mobile/providers/salary_slip_provider.dart';
import 'package:lexor_mobile/screens/create_leave_request.dart';
import 'package:provider/provider.dart';

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

String _salaryStatusLabel(int status) => switch (status) {
  1 => 'Plata na čekanju',
  2 => 'Plata isplaćena',
  _ => 'Plata procesirana',
};

String _leaveStateLabel(String? state) => switch (state) {
  'PendingLeaveState' => 'Zahtjev na čekanju',
  'ApprovedLeaveState' => 'Zahtjev odobren',
  'RejectedLeaveState' => 'Zahtjev odbijen',
  'CancelledLeaveState' => 'Zahtjev otkazan',
  _ => 'Zahtjev',
};

String _formatRelativeDate(DateTime dt) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(local.year, local.month, local.day);
  final time = DateFormat('HH:mm').format(local);

  if (date == today) return 'Danas, $time';
  if (date == today.subtract(const Duration(days: 1))) return 'Jučer, $time';
  return '${DateFormat('dd.MM.yyyy').format(local)}, $time';
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: true,
    );
    final leaveProvider = Provider.of<LeaveProvider>(context, listen: true);
    final salarySlipProvider = Provider.of<SalarySlipProvider>(
      context,
      listen: true,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(authProvider),
              const SizedBox(height: 16),
              _buildStatCards(attendanceProvider),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildRecentActivities(salarySlipProvider, leaveProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dobrodošli,',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  authProvider.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Row(
            children: [
              Icon(Icons.notifications, color: Colors.white, size: 28),
              SizedBox(width: 16),
              Icon(Icons.person, color: Colors.white, size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(AttendanceProvider attendanceProvider) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prisutnost danas',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                Text(
                  '${attendanceProvider.summary?.todayWorkedHours.toStringAsFixed(1) ?? '-'}h',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  attendanceProvider.summary?.todayStatus ?? '-',
                  style: const TextStyle(color: Colors.green, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ovaj mjesec',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                Text(
                  '${attendanceProvider.summary?.monthWorkedHours.toStringAsFixed(1) ?? '-'}h',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '↑ ${attendanceProvider.summary?.monthAttendaceRate.toStringAsFixed(1) ?? '-'}% prisustvo',
                  style: const TextStyle(color: Colors.green, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Brze akcije',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateLeaveRequest()),
              );

              if (result == 'reload' && context.mounted) {
                Provider.of<LeaveProvider>(
                  context,
                  listen: false,
                ).fetchLatestLeave();
              }
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF1976D2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateLeaveRequest(),
                        ),
                      ),
                      child: const Text('Zatraži odmor'),
                    ),
                    const Text(
                      'Godišnji, bolovanje',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities(
    SalarySlipProvider salarySlipProvider,
    LeaveProvider leaveProvider,
  ) {
    final salarySlip = salarySlipProvider.salarySlipRecentActivityResponse;
    final leave = leaveProvider.leaveRecentActivityResponse;

    final salaryTitle = salarySlip != null
        ? _salaryStatusLabel(salarySlip.status)
        : '-';
    final salarySubtitle = salarySlip != null
        ? '${_bosnianMonths[salarySlip.month - 1]} ${salarySlip.year} - ${salarySlip.netSalary.toStringAsFixed(2)} KM'
        : '-';
    final salaryTime = salarySlip != null
        ? _formatRelativeDate(salarySlip.generatedAt)
        : '-';

    final leaveTitle = _leaveStateLabel(leave?.state);
    final leaveSubtitle = leave != null
        ? '${leave.leaveType.name} - ${DateFormat('dd.MM').format(leave.dateFrom)} - ${DateFormat('dd.MM').format(leave.dateTo)}'
        : '-';
    final leaveTime = leave != null
        ? _formatRelativeDate(leave.createdAt)
        : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nedavna aktivnost',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salaryTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      salarySubtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Text(
                      salaryTime,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leaveTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      leaveSubtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Text(
                      leaveTime,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
