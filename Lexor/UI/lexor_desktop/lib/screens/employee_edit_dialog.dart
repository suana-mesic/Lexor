import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/models/employee_response.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_desktop/providers/contract_provider.dart';
import 'package:lexor_desktop/providers/contract_type_option.dart';
import 'package:lexor_desktop/providers/employee_provider.dart';
import 'package:lexor_desktop/providers/position_option.dart';
import 'package:lexor_desktop/screens/edit_contract_dialog.dart';
import 'package:lexor_desktop/screens/new_contract_dialog.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/app_notify.dart';
import 'package:lexor_shared/lexor_shared.dart';

/// Tabbed edit dialog:
/// - "Lični podaci": edits user/employee fields (firstName, address, city, ...).
/// - "Ugovori": manages contracts (add new, edit/delete upcoming, view history).
class EmployeeEditDialog extends StatefulWidget {
  final EmployeeProvider provider;
  final ContractProvider contractProvider;
  final EmployeeResponse employee;
  final List<RefOption> cities;
  final List<RefOption> departments;
  final List<PositionOption> positions;
  final List<ContractTypeOption> contractTypes;

  const EmployeeEditDialog({
    super.key,
    required this.provider,
    required this.contractProvider,
    required this.employee,
    required this.cities,
    required this.departments,
    required this.positions,
    required this.contractTypes,
  });

  @override
  State<EmployeeEditDialog> createState() => _EmployeeEditDialogState();
}

class _EmployeeEditDialogState extends State<EmployeeEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late DateTime? _dateOfBirth;
  late int? _cityId;
  late int? _departmentId;
  late int? _positionId;
  late bool _isActive;

  EmployeeResponse? _employee;
  bool _contractsLoading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _firstName = TextEditingController(text: e.user.firstName);
    _lastName = TextEditingController(text: e.user.lastName);
    _email = TextEditingController(text: e.user.email);
    _phone = TextEditingController(text: e.user.phoneNumber ?? '');
    _address = TextEditingController(text: e.address);
    _dateOfBirth = e.dateOfBirth;
    _cityId = e.city?.id;
    _departmentId = e.department?.id;
    _positionId = e.position?.id;
    _isActive = e.isActive;
    _employee = e;
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  // Positions belong to a department, so only show those for the chosen one.
  List<RefOption> _positionsForDepartment() {
    if (_departmentId == null) return const [];
    return widget.positions
        .where((p) => p.departmentId == _departmentId)
        .map((p) => RefOption(p.id, p.name))
        .toList();
  }

  Future<void> _reloadEmployee() async {
    setState(() => _contractsLoading = true);
    try {
      _employee = await widget.provider.getById(widget.employee.id);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, messageFor(e), error: true);
    } finally {
      if (mounted) setState(() => _contractsLoading = false);
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? now,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.provider.update(widget.employee.id, {
        'user': {
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'email': _email.text.trim(),
          'phoneNumber':
              _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        },
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'address': _address.text.trim(),
        'cityId': _cityId,
        'departmentId': _departmentId,
        'positionId': _positionId,
        'isActive': _isActive,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = messageFor(e);
        _saving = false;
      });
    }
  }

  Future<void> _openNewContract() async {
    final e = _employee;
    if (e == null) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NewContractDialog(
        provider: widget.contractProvider,
        employeeId: e.id,
        currentActive: e.activeContract,
        contractTypes: widget.contractTypes,
      ),
    );
    if (saved == true) {
      if (!mounted) return;
      showSnack(context, 'Novi ugovor dodan');
      await _reloadEmployee();
    }
  }

  Future<void> _openEditContract(EmployeeContractResponse c) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditContractDialog(
        provider: widget.contractProvider,
        contract: c,
        contractTypes: widget.contractTypes,
        activeContract: _employee?.activeContract,
      ),
    );
    if (saved == true) {
      if (!mounted) return;
      showSnack(context, 'Ugovor ažuriran');
      await _reloadEmployee();
    }
  }

  Future<void> _deleteContract(EmployeeContractResponse c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Obriši budući ugovor'),
        content: Text(
          'Da li ste sigurni da želite obrisati budući ugovor koji počinje '
          '${DateFormat('dd.MM.yyyy').format(c.startDate.toLocal())}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.contractProvider.remove(c.id);
      if (!mounted) return;
      showSnack(context, 'Budući ugovor obrisan');
      await _reloadEmployee();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, messageFor(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 720,
        height: 560,
        child: DefaultTabController(
          length: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Uredi uposlenika',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Zatvori',
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Lični podaci'),
                    Tab(text: 'Ugovori'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      _personalTab(),
                      _contractsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _personalTab() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 12, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _twoCol(
                    _text(_firstName, 'Ime', required: true),
                    _text(_lastName, 'Prezime', required: true),
                  ),
                  const SizedBox(height: 16),
                  _twoCol(
                    _text(_email, 'Email', required: true, isEmail: true),
                    _text(_phone, 'Telefon'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _dateField(
                            'Datum rođenja *', _dateOfBirth, _pickDateOfBirth),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _statusToggle()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _text(_address, 'Adresa', required: true),
                  const SizedBox(height: 16),
                  _twoCol(
                    _dropdown('Grad', _cityId, widget.cities,
                        (v) => setState(() => _cityId = v)),
                    _dropdown('Odjel', _departmentId, widget.departments, (v) {
                      setState(() {
                        _departmentId = v;
                        // Clear a position that no longer belongs to the new department.
                        if (_positionId != null &&
                            !widget.positions.any((p) =>
                                p.id == _positionId && p.departmentId == v)) {
                          _positionId = null;
                        }
                      });
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Guard the value: if the stored position doesn't belong to
                  // the current department (legacy/inconsistent data), show it
                  // empty rather than crash, forcing a valid pick.
                  Builder(builder: (_) {
                    final posItems = _positionsForDepartment();
                    final posValue = posItems.any((o) => o.id == _positionId)
                        ? _positionId
                        : null;
                    return _dropdown('Pozicija', posValue, posItems,
                        (v) => setState(() => _positionId = v));
                  }),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _saving ? null : () => Navigator.pop(context, false),
                child: const Text('Otkaži'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sačuvaj izmjene'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contractsTab() {
    if (_contractsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final e = _employee;
    if (e == null) return const SizedBox.shrink();

    final history = [...e.contracts]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final active = e.activeContract;
    final upcoming =
        history.where((c) => c.status == ContractStatus.upcoming).toList();
    final past =
        history.where((c) => c.status == ContractStatus.expired).toList();

    // Contracts can only be created for active employees. The personal-data tab
    // can toggle status, but that must be saved first — the server is the source
    // of truth, so we guard on the persisted/reloaded value here.
    final canAddContract = e.isActive;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Trenutno aktivan ugovor',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: canAddContract ? _openNewContract : null,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Dodaj novi ugovor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (!canAddContract) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Uposlenik je neaktivan, pa nije moguće kreirati nove '
                      'ugovore. Aktivirajte uposlenika u kartici „Lični podaci" '
                      'i sačuvajte izmjene.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _contractCard(EmployeeContractResponse c, {bool highlight = false}) {
    final canEdit = c.status == ContractStatus.upcoming;
    return Stack(
      children: [
        Container(
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
        ),
        if (canEdit)
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Uredi budući ugovor',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _openEditContract(c),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red[400],
                  ),
                  tooltip: 'Obriši budući ugovor',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _deleteContract(c),
                ),
              ],
            ),
          ),
      ],
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

  Widget _twoCol(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );

  Widget _text(
    TextEditingController c,
    String label, {
    bool required = false,
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (v) {
        final t = (v ?? '').trim();
        if (required && t.isEmpty) return '$label je obavezno polje.';
        if (isEmail && t.isNotEmpty &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
          return 'Unesite ispravan email.';
        }
        return null;
      },
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(
          value == null ? '' : DateFormat('dd.MM.yyyy').format(value),
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    int? value,
    List<RefOption> items,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: '$label *',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final o in items)
          DropdownMenuItem<int>(value: o.id, child: Text(o.name)),
      ],
      validator: (v) => v == null ? '$label je obavezno polje.' : null,
      onChanged: onChanged,
    );
  }

  Widget _statusToggle() {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('Aktivan'),
          selected: _isActive,
          selectedColor: AppColors.success,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelStyle: TextStyle(
            color: _isActive ? Colors.white : Colors.black87,
          ),
          onSelected: (_) => setState(() => _isActive = true),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Neaktivan'),
          selected: !_isActive,
          selectedColor: Colors.grey[600],
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelStyle: TextStyle(
            color: !_isActive ? Colors.white : Colors.black87,
          ),
          onSelected: (_) => setState(() => _isActive = false),
        ),
      ],
    );
  }
}
