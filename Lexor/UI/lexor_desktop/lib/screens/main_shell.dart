import 'package:flutter/material.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/providers/dashboard_provider.dart';
import 'package:lexor_desktop/screens/attendance_screen.dart';
import 'package:lexor_desktop/screens/dashboard_screen.dart';
import 'package:lexor_desktop/screens/employees_screen.dart';
import 'package:lexor_desktop/screens/leaves_screen.dart';
import 'package:lexor_desktop/screens/legal_document_screen.dart';
import 'package:lexor_desktop/screens/login_screen.dart';
import 'package:lexor_desktop/screens/payroll_screen.dart';
import 'package:lexor_desktop/screens/payroll_settings_screen.dart';
import 'package:lexor_desktop/screens/reference_data_screen.dart';
import 'package:lexor_desktop/screens/reports_screen.dart';
import 'package:lexor_desktop/screens/rfid_cards_screen.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/app_header.dart';
import 'package:provider/provider.dart';
import 'package:lexor_desktop/screens/absence_prediction_screen.dart';
import 'package:lexor_desktop/providers/absence_prediction_provider.dart';
import 'package:lexor_desktop/screens/news_screen.dart';
import 'package:lexor_desktop/providers/news_provider.dart';
import 'package:lexor_desktop/screens/my_profile_screen.dart';
import 'package:lexor_desktop/providers/account_provider.dart';

const Color _sidebarBg = AppColors.primary;
const Color _navActive = AppColors.navActive;

// Which role may see each screen. Employees never reach the desktop app.
const _rHr = 'HRManager';
const _rAcc = 'Accounting';
const _rAdmin = 'Administrator';

class _NavItem {
  final IconData icon;
  final String label;
  final Set<String> roles;
  const _NavItem(this.icon, this.label, this.roles);
}

const _navItems = [
  _NavItem(Icons.home_outlined, 'Dashboard', {_rHr}),
  _NavItem(Icons.people_outline, 'Uposlenici', {_rHr}),
  _NavItem(Icons.credit_card_outlined, 'RFID kartice', {_rHr}),
  _NavItem(Icons.access_time_outlined, 'Prisustvo', {_rHr}),
  _NavItem(Icons.inbox_outlined, 'Zahtjevi', {_rHr}),
  _NavItem(Icons.bar_chart_outlined, 'Izvještaji', {_rHr, _rAcc}),
  _NavItem(Icons.account_balance_wallet_outlined, 'Obračun plata', {_rAcc}),
  _NavItem(Icons.balance_outlined, 'Pravni dokumenti', {_rHr}),
  _NavItem(Icons.settings_outlined, 'Postavke obračuna', {_rAcc}),
  _NavItem(Icons.storage_outlined, 'Referentni podaci', {_rHr}),
  _NavItem(Icons.insights_outlined, 'Predikcija odsustva', {_rHr}),
  _NavItem(Icons.campaign_outlined, 'Obavijesti', {_rHr}),
  _NavItem(Icons.account_circle_outlined, 'Moj profil', {_rHr, _rAcc, _rAdmin}),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late final Set<String> _roles;

  @override
  void initState() {
    super.initState();
    _roles = Provider.of<AuthProvider>(context, listen: false).roles.toSet();
    // Land on the first screen this role is allowed to open.
    final allowed = _allowedIndices;
    _selectedIndex = allowed.isNotEmpty ? allowed.first : 0;
    // Load the current user's account so the header can show their name/avatar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountProvider>(context, listen: false).fetch();
    });
  }

  // Global nav indices this role may see (keeps _buildContent's index switch intact).
  List<int> get _allowedIndices => [
    for (var i = 0; i < _navItems.length; i++)
      if (_navItems[i].roles.any(_roles.contains)) i,
  ];

  String get _panelTitle {
    if (_roles.contains(_rHr)) return 'HR panel';
    if (_roles.contains(_rAcc)) return 'Računovodstvo';
    if (_roles.contains(_rAdmin)) return 'Administracija';
    return 'Lexor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: Column(
                children: [
                  AppHeader(title: _navItems[_selectedIndex].label),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const EmployeesScreen();
      case 2:
        return const RfidCardsScreen();
      case 3:
        return const AttendanceScreen();
      case 4:
        return const LeavesScreen();
      case 5:
        return const ReportsScreen();
      case 6:
        return const PayrollScreen();
      case 7:
        return const LegalDocumentScreen();
      case 8:
        return const PayrollSettingsScreen();
      case 9:
        return const ReferenceDataScreen();
      case 10:
        return const AbsencePredictionScreen();
      case 11:
        return const NewsScreen();
      case 12:
        return const MyProfileScreen();
      default:
        return const Center(child: Text('Uskoro...'));
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 230,
      color: _sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            child: Text(
              _panelTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                final allowed = _allowedIndices;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: allowed.length,
                  itemBuilder: (context, i) => _buildNavTile(allowed[i]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
            child: _buildNavTileRaw(
              icon: Icons.logout_outlined,
              label: 'Odjava',
              onTap: () async {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final dashboardProvider = Provider.of<DashboardProvider>(
                  context,
                  listen: false,
                );
                final navigator = Navigator.of(context);
                dashboardProvider.reset();
                Provider.of<AbsencePredictionProvider>(
                  context,
                  listen: false,
                ).reset();
                Provider.of<NewsProvider>(context, listen: false).reset();
                Provider.of<AccountProvider>(context, listen: false).reset();
                await authProvider.logout();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              isSelected: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: _buildNavTileRaw(
        icon: _navItems[index].icon,
        label: _navItems[index].label,
        isSelected: _selectedIndex == index,
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildNavTileRaw({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashColor: Colors.white12,
      hoverColor: Colors.white10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? _navActive : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
