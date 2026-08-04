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
import 'package:lexor_desktop/screens/users_screen.dart';
import 'package:lexor_desktop/screens/roles_screen.dart';
import 'package:lexor_desktop/screens/admin_dashboard_screen.dart';
import 'package:lexor_desktop/providers/admin_provider.dart';

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
  final Widget screen;
  const _NavItem(this.icon, this.label, this.roles, this.screen);
}

// Ordered so each role's first visible item is a sensible landing page.
const _navItems = [
  _NavItem(Icons.home_outlined, 'Dashboard', {_rHr}, DashboardScreen()),
  _NavItem(Icons.people_outline, 'Uposlenici', {_rHr}, EmployeesScreen()),
  _NavItem(Icons.access_time_outlined, 'Prisustvo', {_rHr}, AttendanceScreen()),
  _NavItem(Icons.inbox_outlined, 'Zahtjevi', {_rHr}, LeavesScreen()),
  _NavItem(Icons.bar_chart_outlined, 'Izvještaji', {_rHr, _rAcc}, ReportsScreen()),
  _NavItem(Icons.account_balance_wallet_outlined, 'Obračun plata', {_rAcc}, PayrollScreen()),
  _NavItem(Icons.settings_outlined, 'Postavke obračuna', {_rAcc}, PayrollSettingsScreen()),
  _NavItem(Icons.insights_outlined, 'Predikcija odsustva', {_rHr}, AbsencePredictionScreen()),
  _NavItem(Icons.campaign_outlined, 'Obavijesti', {_rHr}, NewsScreen()),
  _NavItem(Icons.dashboard_outlined, 'Admin pregled', {_rAdmin}, AdminDashboardScreen()),
  _NavItem(Icons.manage_accounts_outlined, 'Korisnici', {_rAdmin}, UsersScreen()),
  _NavItem(Icons.badge_outlined, 'Uloge', {_rAdmin}, RolesScreen()),
  _NavItem(Icons.credit_card_outlined, 'RFID kartice', {_rAdmin}, RfidCardsScreen()),
  _NavItem(Icons.storage_outlined, 'Referentni podaci', {_rAdmin}, ReferenceDataScreen()),
  _NavItem(Icons.balance_outlined, 'Pravni dokumenti', {_rAdmin}, LegalDocumentScreen()),
  _NavItem(Icons.account_circle_outlined, 'Moj profil', {_rHr, _rAcc, _rAdmin}, MyProfileScreen()),
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
    // Load the current user's account so the header can show their name/avatar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountProvider>(context, listen: false).fetch();
    });
  }

  // Items this role may see, in declaration order (index 0 is the landing page).
  List<_NavItem> get _visibleItems =>
      [for (final item in _navItems) if (item.roles.any(_roles.contains)) item];

  String get _panelTitle {
    if (_roles.contains(_rHr)) return 'HR panel';
    if (_roles.contains(_rAcc)) return 'Računovodstvo';
    if (_roles.contains(_rAdmin)) return 'Administracija';
    return 'Lexor';
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    if (items.isEmpty) {
      return const Scaffold(body: Center(child: Text('Nema dostupnih ekrana.')));
    }
    final index = _selectedIndex.clamp(0, items.length - 1);

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(items, index),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: Column(
                children: [
                  AppHeader(title: items[index].label),
                  Expanded(child: items[index].screen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(List<_NavItem> items, int selectedIndex) {
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: items.length,
              itemBuilder: (context, i) => _buildNavTile(items[i], i, selectedIndex),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
            child: _buildNavTileRaw(
              icon: Icons.logout_outlined,
              label: 'Odjava',
              onTap: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final navigator = Navigator.of(context);
                Provider.of<DashboardProvider>(context, listen: false).reset();
                Provider.of<AbsencePredictionProvider>(context, listen: false).reset();
                Provider.of<NewsProvider>(context, listen: false).reset();
                Provider.of<AccountProvider>(context, listen: false).reset();
                Provider.of<AdminProvider>(context, listen: false).reset();
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

  Widget _buildNavTile(_NavItem item, int index, int selectedIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: _buildNavTileRaw(
        icon: item.icon,
        label: item.label,
        isSelected: index == selectedIndex,
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
