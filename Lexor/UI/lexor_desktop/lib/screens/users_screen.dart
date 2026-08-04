import 'package:flutter/material.dart';
import 'package:lexor_desktop/helpers/role_labels.dart';
import 'package:lexor_desktop/models/admin_user_response.dart';
import 'package:lexor_desktop/providers/admin_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:provider/provider.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _search = TextEditingController();
  String? _roleFilter; // role value or null (Sve)
  String? _statusFilter; // 'Active' / 'Inactive' / null

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<AdminProvider>(context, listen: false);
      p.fetchRoles();
      p.fetchUsers();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _apply() {
    Provider.of<AdminProvider>(context, listen: false).fetchUsers(
      name: _search.text,
      roleName: _roleFilter,
      status: _statusFilter,
    );
  }

  Future<void> _runAction(Future<String?> Function() action, String successMsg) async {
    final messenger = ScaffoldMessenger.of(context);
    final err = await action();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? successMsg),
        backgroundColor: err == null ? AppColors.successBright : AppColors.error,
      ),
    );
  }

  Future<void> _changeRole(AdminUserResponse user) async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    final selected = await showDialog<int>(
      context: context,
      builder: (_) => _ChangeRoleDialog(provider: provider, user: user),
    );
    if (selected == null) return;
    await _runAction(
      () => provider.changeRole(user.id, selected),
      'Uloga je promijenjena.',
    );
  }

  Future<void> _toggleActive(AdminUserResponse user) async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    if (user.isActive) {
      final ok = await _confirm(
        'Deaktivacija naloga',
        'Deaktivirati nalog "${user.fullName}"? Korisnik se neće moći prijaviti.',
        'Deaktiviraj',
      );
      if (ok != true) return;
    }
    await _runAction(
      () => provider.setActive(user.id, !user.isActive),
      user.isActive ? 'Nalog je deaktiviran.' : 'Nalog je aktiviran.',
    );
  }

  Future<bool?> _confirm(String title, String message, String confirmLabel) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Korisnici',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _filterBar(provider),
          const SizedBox(height: 16),
          Expanded(child: _body(provider)),
        ],
      ),
    );
  }

  Widget _filterBar(AdminProvider provider) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(
              hintText: 'Pretraži po imenu ili emailu',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => _apply(),
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            initialValue: _roleFilter,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Sve uloge')),
              for (final r in provider.roles)
                DropdownMenuItem<String?>(value: r.name, child: Text(roleLabel(r.name))),
            ],
            onChanged: (v) => setState(() => _roleFilter = v),
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String?>(
            initialValue: _statusFilter,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('Svi statusi')),
              DropdownMenuItem<String?>(value: 'Active', child: Text('Aktivni')),
              DropdownMenuItem<String?>(value: 'Inactive', child: Text('Neaktivni')),
            ],
            onChanged: (v) => setState(() => _statusFilter = v),
          ),
        ),
        ElevatedButton(
          onPressed: _apply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          child: const Text('Primijeni'),
        ),
      ],
    );
  }

  Widget _body(AdminProvider provider) {
    if (provider.isLoading && provider.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.users.isEmpty) {
      return Center(
        child: Text(provider.error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (provider.users.isEmpty) {
      return const Center(child: Text('Nema korisnika.'));
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 320),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Ime')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Uloga')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Akcije')),
              ],
              rows: [for (final u in provider.users) _row(u)],
            ),
          ),
        ),
      ),
    );
  }

  DataRow _row(AdminUserResponse u) {
    return DataRow(
      cells: [
        DataCell(Text(u.fullName)),
        DataCell(Text(u.email)),
        DataCell(_roleChip(u.roleName)),
        DataCell(_statusBadge(u.isActive)),
        DataCell(
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'role':
                  _changeRole(u);
                case 'active':
                  _toggleActive(u);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'role', child: Text('Promijeni ulogu')),
              PopupMenuItem(
                value: 'active',
                child: Text(u.isActive ? 'Deaktiviraj' : 'Aktiviraj'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roleChip(String roleName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        roleLabel(roleName),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: active ? AppColors.successBg : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        active ? 'Aktivan' : 'Neaktivan',
        style: TextStyle(
          color: active ? AppColors.success : Colors.grey[700],
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChangeRoleDialog extends StatefulWidget {
  final AdminProvider provider;
  final AdminUserResponse user;

  const _ChangeRoleDialog({required this.provider, required this.user});

  @override
  State<_ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends State<_ChangeRoleDialog> {
  int? _selectedRoleId;

  @override
  void initState() {
    super.initState();
    // Preselect the user's current role if we can match it by name.
    final current = widget.provider.roles
        .where((r) => r.name == widget.user.roleName)
        .toList();
    if (current.isNotEmpty) _selectedRoleId = current.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Promjena uloge: ${widget.user.fullName}'),
      content: SizedBox(
        width: 360,
        child: DropdownButtonFormField<int>(
          initialValue: _selectedRoleId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Uloga',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final r in widget.provider.roles)
              DropdownMenuItem<int>(value: r.id, child: Text(roleLabel(r.name))),
          ],
          onChanged: (v) => setState(() => _selectedRoleId = v),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _selectedRoleId == null
              ? null
              : () => Navigator.pop(context, _selectedRoleId),
          child: const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
