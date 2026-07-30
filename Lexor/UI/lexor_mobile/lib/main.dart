import 'package:flutter/material.dart';
import 'package:lexor_mobile/auth_store.dart';
import 'package:lexor_mobile/providers/attendance_provider.dart';
import 'package:lexor_mobile/providers/auth_provider.dart';
import 'package:lexor_mobile/providers/chat_provider.dart';
import 'package:lexor_mobile/providers/leave_provider.dart';
import 'package:lexor_mobile/providers/leave_type_provider.dart';
import 'package:lexor_mobile/providers/news_provider.dart';
import 'package:lexor_mobile/providers/notification_provider.dart';
import 'package:lexor_mobile/providers/payroll_settings_provider.dart';
import 'package:lexor_mobile/providers/profile_provider.dart';
import 'package:lexor_mobile/providers/salary_slip_provider.dart';
import 'package:lexor_mobile/screens/home_screen.dart';
import 'package:lexor_mobile/screens/login_screen.dart';
import 'package:lexor_mobile/session.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final loggedIn = await loadToken();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => SalarySlipProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => LeaveTypeProvider()),
        ChangeNotifierProvider(create: (_) => PayrollSettingsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
      ],
      child: MyApp(loggedIn: loggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool loggedIn;
  const MyApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Lexor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: loggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
