import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/helpers/image_decode.dart';
import 'package:lexor_desktop/models/employee_response.dart';
import 'package:lexor_desktop/providers/employee_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_shared/lexor_shared.dart';

/// Read-only view: personal data + active/upcoming/historical contracts.
/// Contract management (add/edit/delete) lives in the Edit dialog's
/// "Ugovori" tab; this view is for quick reading only.
class EmployeeDetailsDialog extends StatefulWidget {
  final EmployeeProvider employeeProvider;
  final int employeeId;

  const EmployeeDetailsDialog({
    super.key,
    required this.employeeProvider,
    required this.employeeId,
  });

  @override
  State<EmployeeDetailsDialog> createState() => _EmployeeDetailsDialogState();
}

class _EmployeeDetailsDialogState extends State<EmployeeDetailsDialog> {
  EmployeeResponse? _employee;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _employee = await widget.employeeProvider.getById(widget.employeeId);
    } catch (e) {
      _error = messageFor(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 720,
        height: 640,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detalji uposlenika',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Zatvori',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    final e = _employee;
    if (e == null) return const SizedBox.shrink();

    final history = [...e.contracts]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final active = e.activeContract;
    final upcoming = history
        .where((c) => c.status == ContractStatus.upcoming)
        .toList();
    final past = history
        .where((c) => c.status == ContractStatus.expired)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _personalCard(e),
          const SizedBox(height: 20),
          const Text(
            'Trenutno aktivan ugovor',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (active != null)
            _contractCard(active, highlight: true)
          else
            _noActiveBanner(),
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Budući ugovori',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final c in upcoming) _contractCard(c),
          ],
          const SizedBox(height: 20),
          const Text(
            'Historija ugovora',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (past.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Nema starijih ugovora.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            Column(children: [for (final c in past) _contractCard(c)]),
        ],
      ),
    );
  }

  Widget _avatar(EmployeeResponse e) {
    final img = e.user.profileImageBase64;
    ImageProvider? bg;
    if (img != null && img.isNotEmpty) {
      try {
        bg = MemoryImage(cachedImageBytes(img));
      } catch (_) {
        bg = null;
      }
    }
    return CircleAvatar(
      radius: 32,
      backgroundColor: AppColors.primary,
      backgroundImage: bg,
      child: bg == null
          ? Text(
              _initials(e.user.fullName),
              style: const TextStyle(color: Colors.white, fontSize: 20),
            )
          : null,
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  Widget _personalCard(EmployeeResponse e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(e),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.user.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${e.position?.name ?? '-'} • ${e.department?.name ?? '-'}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _kv('Email', e.user.email),
              _kv('Telefon', e.user.phoneNumber ?? '-'),
              _kv(
                'Datum rođenja',
                DateFormat('dd.MM.yyyy').format(e.dateOfBirth.toLocal()),
              ),
              _kv(
                'Datum zaposlenja',
                DateFormat('dd.MM.yyyy').format(e.hireDate.toLocal()),
              ),
              _kv(
                'Grad',
                e.city == null
                    ? '-'
                    : '${e.city!.name}, ${e.city!.country.name}',
              ),
              _kv('Adresa', e.address),
              _kv('Status', e.isActive ? 'Aktivan' : 'Neaktivan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contractCard(EmployeeContractResponse c, {bool highlight = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.successBg : Colors.grey[50],
        border: Border.all(
          color: highlight ? AppColors.success : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 6,
        children: [
          _kv('Tip', c.contractTypeName),
          _kv(
            'Period',
            '${DateFormat('dd.MM.yyyy').format(c.startDate.toLocal())} – '
                '${c.endDate == null ? 'neodređeno' : DateFormat('dd.MM.yyyy').format(c.endDate!.toLocal())}',
          ),
          _kv('Bruto plata', '${c.brutoSalary.toStringAsFixed(2)} KM'),
          _kv('Sati dnevno', '${c.workHoursPerDay}'),
          _statusKv(c.status),
        ],
      ),
    );
  }

  Widget _statusKv(ContractStatus status) {
    final (Color fg, Color bg, Color? border) = switch (status) {
      ContractStatus.active => (
        AppColors.success,
        Colors.white,
        AppColors.success,
      ),
      ContractStatus.upcoming => (AppColors.indigo, AppColors.indigoBg, null),
      ContractStatus.expired => (AppColors.grey, const Color(0xFFEEEEEE), null),
    };
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: border != null ? Border.all(color: border) : null,
            ),
            child: Text(
              status.label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noActiveBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Uposlenik trenutno nema aktivan ugovor.',
        style: TextStyle(color: Colors.grey[700]),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 2),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
