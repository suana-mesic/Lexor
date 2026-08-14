import 'package:flutter/material.dart';
import 'package:lexor_desktop/helpers/role_labels.dart';
import 'package:lexor_desktop/providers/admin_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Provider.of<AdminProvider>(context, listen: false).fetchStats(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final stats = provider.stats;

    if (provider.isLoading && stats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && stats == null) {
      return Center(
        child: Text(provider.error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pregled sistema',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          _section('Nalozi'),
          Wrap(spacing: 16, runSpacing: 16, children: [
            _mini('Ukupno korisnika', stats.totalUsers, AppColors.primary),
            _mini('Aktivni', stats.activeUsers, AppColors.success),
            _mini('Neaktivni', stats.inactiveUsers, AppColors.error),
            _mini('Nisu aktivirali pristup', stats.notActivatedUsers, AppColors.warning),
          ]),

          const SizedBox(height: 24),
          _section('Korisnici po ulozi'),
          for (final r in stats.usersPerRole) _roleRow(r.roleName, r.count),

          const SizedBox(height: 24),
          _section('Ugovori'),
          Wrap(spacing: 16, runSpacing: 16, children: [
            _mini('Aktivni ugovori', stats.activeContracts, AppColors.success),
            _mini('Uskoro ističu (30 dana)', stats.expiringSoonContracts, AppColors.warning),
            _mini('Istekli ugovori', stats.expiredContracts, AppColors.error),
          ]),

          const SizedBox(height: 24),
          _section('Konfiguracija sistema'),
          Wrap(spacing: 16, runSpacing: 16, children: [
            _mini('Odjeli', stats.departments, AppColors.info),
            _mini('Pozicije', stats.positions, AppColors.info),
            _mini('Gradovi', stats.cities, AppColors.info),
            _mini('Tipovi ugovora', stats.contractTypes, AppColors.info),
            _mini('Tipovi odsustva', stats.leaveTypes, AppColors.info),
          ]),

          const SizedBox(height: 24),
          _section('Sadržaj i uređaji'),
          Wrap(spacing: 16, runSpacing: 16, children: [
            _mini('Pravni dokumenti', stats.legalDocuments, AppColors.info),
            _mini('RFID kartice (aktivne)', stats.activeRfidCards, AppColors.primary),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _mini(String label, int value, Color color) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          const SizedBox(height: 8),
          Text('$value',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _roleRow(String roleName, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(roleLabel(roleName), style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
