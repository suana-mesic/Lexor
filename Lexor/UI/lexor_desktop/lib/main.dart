import 'package:flutter/material.dart';
import 'package:lexor_desktop/providers/account_provider.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/providers/dashboard_provider.dart';
import 'package:lexor_desktop/providers/payroll_dashboard_provider.dart';
import 'package:lexor_desktop/providers/news_provider.dart';
import 'package:lexor_desktop/providers/admin_provider.dart';
import 'package:lexor_desktop/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(768, 650));
  runApp(const LexorDesktopApp());
}

class LexorDesktopApp extends StatelessWidget {
  const LexorDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => PayrollDashboardProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'Lexor HR Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
