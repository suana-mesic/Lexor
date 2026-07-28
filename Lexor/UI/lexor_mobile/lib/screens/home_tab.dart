import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_mobile/providers/attendance_provider.dart';
import 'package:lexor_mobile/providers/auth_provider.dart';
import 'package:lexor_mobile/providers/leave_provider.dart';
import 'package:lexor_mobile/providers/salary_slip_provider.dart';
import 'package:lexor_mobile/screens/create_leave_request.dart';
import 'package:lexor_mobile/screens/profile_screen.dart';
import 'package:lexor_mobile/widgets/error_banner.dart';
import 'package:lexor_mobile/widgets/notifications_bell.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:provider/provider.dart';
import 'package:lexor_mobile/theme/app_colors.dart';

String _salaryStatusLabel(int status) =>
    SalarySlipStatus.fromCode(status)?.label ?? 'Plata procesirana';

String _leaveStateLabel(String? state) =>
    switch (LeaveStateType.fromApi(state)) {
      LeaveStateType.pending => 'Zahtjev na čekanju',
      LeaveStateType.approved => 'Zahtjev odobren',
      LeaveStateType.rejected => 'Zahtjev odbijen',
      LeaveStateType.cancelled => 'Zahtjev otkazan',
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

    final errorMessage =
        attendanceProvider.error ??
        salarySlipProvider.error ??
        leaveProvider.error;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, authProvider),
              const SizedBox(height: 16),
              if (errorMessage != null) ...[
                ErrorBanner(
                  message: errorMessage,
                  onRetry: () {
                    attendanceProvider.fetchSummary();
                    salarySlipProvider.fetchLatestSalarySlip();
                    leaveProvider.fetchLatestLeave();
                  },
                ),
                const SizedBox(height: 16),
              ],
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

  Widget _buildHeader(BuildContext context, AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
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
          Row(
            children: [
              const NotificationBell(),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(AttendanceProvider attendanceProvider) {
    final summary = attendanceProvider.summary;

    // New employee (or no hours recorded this month) → friendly empty state, not zeros.
    if (summary == null || summary.monthTotalHours == 0) {
      return _emptyCard(
        icon: Icons.access_time_outlined,
        message: 'Nema evidencije o prisustvu',
      );
    }

    return Column(
      children: [
        _statCard(
          title: 'Prisutnost danas',
          value: '${summary.todayWorkedHours.toStringAsFixed(1)}h',
          subtitle: summary.todayStatus,
        ),
        const SizedBox(height: 16),
        _statCard(
          title: 'Prisutnost ovaj mjesec',
          value: '${summary.monthTotalHours.toStringAsFixed(1)}h',
          subtitle:
              '↑ ${summary.monthAttendanceRate.toStringAsFixed(1)}% prisustvo',
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
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
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.green, fontSize: 14),
          ),
        ],
      ),
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
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: AppColors.info,
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

    final cards = <Widget>[];
    if (salarySlip != null) {
      cards.add(
        _activityCard(
          dotColor: Colors.green,
          title: _salaryStatusLabel(salarySlip.status),
          subtitle:
              '${bosnianMonthName(salarySlip.month)} ${salarySlip.year} - ${salarySlip.netSalary.toStringAsFixed(2)} KM',
          time: _formatRelativeDate(salarySlip.generatedAt),
        ),
      );
    }
    if (leave != null) {
      cards.add(
        _activityCard(
          dotColor: Colors.blue,
          title: _leaveStateLabel(leave.state),
          subtitle:
              '${leave.leaveType.name} - ${DateFormat('dd.MM').format(leave.dateFrom)} - ${DateFormat('dd.MM').format(leave.dateTo)}',
          time: _formatRelativeDate(leave.createdAt),
        ),
      );
    }

    final content = <Widget>[];
    if (cards.isEmpty) {
      content.add(
        _emptyCard(
          icon: Icons.history_outlined,
          message: 'Nema evidencije o nedavnoj aktivnosti',
        ),
      );
    } else {
      for (var i = 0; i < cards.length; i++) {
        if (i > 0) content.add(const SizedBox(height: 12));
        content.add(cards[i]);
      }
    }

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
        ...content,
      ],
    );
  }

  Widget _activityCard({
    required Color dotColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      width: double.infinity,
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
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.neutralFg),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.neutralFg, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
