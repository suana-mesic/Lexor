import 'package:flutter/material.dart';
import 'package:lexor_mobile/providers/attendance_provider.dart';
import 'package:lexor_mobile/providers/leave_provider.dart';
import 'package:lexor_mobile/providers/news_provider.dart';
import 'package:lexor_mobile/providers/notification_provider.dart';
import 'package:lexor_mobile/providers/salary_slip_provider.dart';
import 'package:lexor_mobile/screens/attendance_tab.dart';
import 'package:lexor_mobile/screens/chat_tab.dart';
import 'package:lexor_mobile/screens/home_tab.dart';
import 'package:lexor_mobile/screens/leave_requests_tab.dart';
import 'package:lexor_mobile/screens/salary_tab.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  NotificationProvider? _notif;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceProvider>(context, listen: false).fetchSummary();
      Provider.of<LeaveProvider>(context, listen: false).fetchLatestLeave();
      Provider.of<SalarySlipProvider>(
        context,
        listen: false,
      ).fetchLatestSalarySlip();
      Provider.of<LeaveProvider>(context, listen: false).fetchLeaves();
      Provider.of<NewsProvider>(context, listen: false).fetchNews();
      _notif = Provider.of<NotificationProvider>(context, listen: false);
      _notif!.startPolling();
    });
  }

  @override
  void dispose() {
    _notif?.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeTab(),
      const AttendanceTab(),
      const SalaryTab(),
      const LeaveRequestsTab(),
      const ChatTab(),
    ];
    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => {setState(() => _selectedIndex = index)},
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Početna'),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Prisustvo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Plate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Zahtjevi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}
