import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_desktop/providers/contract_provider.dart';
import 'package:lexor_desktop/providers/contract_type_option.dart';
import 'package:lexor_desktop/providers/employee_provider.dart';
import 'package:lexor_desktop/providers/position_option.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_shared/lexor_shared.dart';

class EmployeeAddDialog extends StatefulWidget {
  final EmployeeProvider employeeProvider;
  final ContractProvider contractProvider;
  final List<RefOption> cities;
  final List<RefOption> departments;
  final List<PositionOption> positions;
  final List<ContractTypeOption> contractTypes;

  const EmployeeAddDialog({
    super.key,
    required this.employeeProvider,
    required this.contractProvider,
    required this.cities,
    required this.departments,
    required this.positions,
    required this.contractTypes,
  });

  @override
  State<EmployeeAddDialog> createState() => _EmployeeAddDialogState();
}

class _EmployeeAddDialogState extends State<EmployeeAddDialog> {
  final _formKey = GlobalKey<FormState>();

  // Personal data
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  DateTime? _dateOfBirth;
  DateTime? _hireDate;
  int? _cityId;
  int? _departmentId;
  int? _positionId;

  // First contract
  int? _contractTypeId;
  DateTime? _contractStart;
  DateTime? _contractEnd;

  bool get _needsEndDate {
    final t = widget.contractTypes.firstWhere(
      (c) => c.id == _contractTypeId,
      orElse: () => const ContractTypeOption(
        id: 0,
        name: '',
        endDateRequired: false,
      ),
    );
    return t.endDateRequired;
  }
  final _brutoSalary = TextEditingController();
  final _workHours = TextEditingController(text: '8');

  bool _saving = false;
  String? _error;

  // Positions belong to a department, so only show those for the chosen one.
  List<RefOption> _positionsForDepartment() {
    if (_departmentId == null) return const [];
    return widget.positions
        .where((p) => p.departmentId == _departmentId)
        .map((p) => RefOption(p.id, p.name))
        .toList();
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _address,
      _brutoSalary,
      _workHours,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime? initial, {DateTime? firstDate, DateTime? lastDate}) {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(now.year - 100);
    final last = lastDate ?? DateTime(now.year + 10);
    // showDatePicker asserts firstDate <= initialDate <= lastDate. When no date
    // is selected yet and firstDate is in the future (e.g. end date must be
    // after a future start date), `now` would fall before firstDate and the
    // picker silently fails to open — so clamp the initial date into range.
    var init = initial ?? now;
    if (init.isBefore(first)) init = first;
    if (init.isAfter(last)) init = last;
    return showDatePicker(
      context: context,
      initialDate: init,
      firstDate: first,
      lastDate: last,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      setState(() => _error = 'Datum rođenja je obavezan.');
      return;
    }
    if (_hireDate == null) {
      setState(() => _error = 'Datum zaposlenja je obavezan.');
      return;
    }
    if (_contractStart == null) {
      setState(() => _error = 'Datum početka ugovora je obavezan.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    if (_needsEndDate && _contractEnd == null) {
      setState(() => _error = 'Datum kraja je obavezan za odabrani tip ugovora.');
      return;
    }

    try {
      // 1) Create employee — server returns the new id.
      final created = await widget.employeeProvider.insert({
        'user': {
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'email': _email.text.trim(),
          if (_phone.text.trim().isNotEmpty) 'phoneNumber': _phone.text.trim(),
        },
        'dateOfBirth': _dateOfBirth!.toIso8601String(),
        'address': _address.text.trim(),
        'cityId': _cityId,
        'departmentId': _departmentId,
        'positionId': _positionId,
        'hireDate': _hireDate!.toIso8601String(),
        'isActive': true,
      });

      // 2) Create the first contract for this employee.
      try {
        await widget.contractProvider.insert({
          'employeeId': created.id,
          'contractTypeId': _contractTypeId,
          'startDate': _contractStart!.toIso8601String(),
          if (_needsEndDate) 'endDate': _contractEnd!.toIso8601String(),
          'brutoSalary': double.parse(_brutoSalary.text.trim()),
          'workHoursPerDay': int.parse(_workHours.text.trim()),
          'isActive': true,
        });
      } catch (e) {
        // The employee exists but the contract failed — surface the reason and
        // let the user retry contract creation from the details view.
        if (!mounted) return;
        Navigator.pop(context, true);
        rethrow;
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = messageFor(e);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj uposlenika'),
      content: SizedBox(
        width: 640,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _sectionTitle('Lični podaci'),
                _twoCol(
                  _textField(_firstName, 'Ime', required: true, isName: true),
                  _textField(_lastName, 'Prezime', required: true, isName: true),
                ),
                const SizedBox(height: 16),
                _twoCol(
                  _textField(_email, 'Email', required: true, isEmail: true),
                  _textField(_phone, 'Telefon', isPhone: true),
                ),
                const SizedBox(height: 16),
                _twoCol(
                  _dateField(
                    'Datum rođenja',
                    _dateOfBirth,
                    () async {
                      // Employees must be at least 18 → block a more recent birth date.
                      final now = DateTime.now();
                      final maxBirth = DateTime(now.year - 18, now.month, now.day);
                      final v = await _pickDate(_dateOfBirth, lastDate: maxBirth);
                      if (v != null) setState(() => _dateOfBirth = v);
                    },
                    required: true,
                  ),
                  _dateField(
                    'Datum zaposlenja',
                    _hireDate,
                    () async {
                      // Hire date must be after the birth date and not in the future.
                      final v = await _pickDate(
                        _hireDate,
                        firstDate: _dateOfBirth,
                        lastDate: DateTime.now(),
                      );
                      if (v != null) setState(() => _hireDate = v);
                    },
                    required: true,
                  ),
                ),
                const SizedBox(height: 16),
                _textField(_address, 'Adresa', required: true),
                const SizedBox(height: 16),
                _twoCol(
                  _dropdown<int>(
                    label: 'Grad',
                    value: _cityId,
                    items: widget.cities,
                    onChanged: (v) => setState(() => _cityId = v),
                    requiredLabel: 'Grad je obavezan.',
                  ),
                  _dropdown<int>(
                    label: 'Odjel',
                    value: _departmentId,
                    items: widget.departments,
                    onChanged: (v) => setState(() {
                      _departmentId = v;
                      // Clear a position that no longer belongs to the new department.
                      if (_positionId != null &&
                          !widget.positions.any((p) =>
                              p.id == _positionId && p.departmentId == v)) {
                        _positionId = null;
                      }
                    }),
                    requiredLabel: 'Odjel je obavezan.',
                  ),
                ),
                const SizedBox(height: 16),
                _dropdown<int>(
                  label: 'Pozicija',
                  value: _positionId,
                  items: _positionsForDepartment(),
                  onChanged: (v) => setState(() => _positionId = v),
                  requiredLabel: 'Pozicija je obavezna.',
                ),
                const SizedBox(height: 24),
                _sectionTitle('Prvi ugovor'),
                _twoCol(
                  _dropdown<int>(
                    label: 'Tip ugovora',
                    value: _contractTypeId,
                    items: widget.contractTypes
                        .map((c) => RefOption(c.id, c.name))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _contractTypeId = v;
                      // Reset end date when switching to a type that doesn't need it.
                      if (!_needsEndDate) _contractEnd = null;
                    }),
                    requiredLabel: 'Tip ugovora je obavezan.',
                  ),
                  _dateField(
                    'Datum početka',
                    _contractStart,
                    () async {
                      final v = await _pickDate(_contractStart);
                      if (v != null) setState(() => _contractStart = v);
                    },
                    required: true,
                  ),
                ),
                const SizedBox(height: 16),
                // Second row of the contract section.
                // - For fixed-term ("Na određeno"): EndDate + BrutoSalary;
                //   WorkHours goes on its own line below.
                // - For "Na neodređeno": no EndDate, so we pair Bruto with
                //   WorkHours to keep a clean 2x2 grid (no orphan field).
                if (_needsEndDate) ...[
                  _twoCol(
                    _dateField(
                      'Datum kraja',
                      _contractEnd,
                      () async {
                        final v = await _pickDate(
                          _contractEnd,
                          firstDate: _contractStart,
                        );
                        if (v != null) setState(() => _contractEnd = v);
                      },
                      required: true,
                    ),
                    _numField(_brutoSalary, 'Bruto plata (KM)', isInt: false),
                  ),
                  const SizedBox(height: 16),
                  _numField(_workHours, 'Radni sati dnevno', isInt: true),
                ] else
                  _twoCol(
                    _numField(_brutoSalary, 'Bruto plata (KM)', isInt: false),
                    _numField(_workHours, 'Radni sati dnevno', isInt: true),
                  ),
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
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Otkaži'),
        ),
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
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }

  // ----- Reusable form helpers -----

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  Widget _twoCol(Widget a, Widget b) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: a),
      const SizedBox(width: 12),
      Expanded(child: b),
    ],
  );

  Widget _textField(
    TextEditingController c,
    String label, {
    bool required = false,
    bool isEmail = false,
    bool isPhone = false,
    bool isName = false,
  }) {
    return TextFormField(
      controller: c,
      inputFormatters: isPhone
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))]
          : null,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: isPhone ? 'npr. 062 123 456' : null,
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
        if (isPhone && t.isNotEmpty &&
            !RegExp(r'^(\+387|0)\d{8,9}$').hasMatch(t.replaceAll(' ', ''))) {
          return 'Unesite validan broj telefona (npr. 062 123 456 ili +387 62 123 456).';
        }
        if (isName && t.isNotEmpty &&
            !RegExp(r'^[A-Za-zČčĆćŽžŠšĐđ -]+$').hasMatch(t)) {
          return 'Dozvoljena su samo slova, razmak i crtica.';
        }
        return null;
      },
    );
  }

  Widget _numField(
    TextEditingController c,
    String label, {
    required bool isInt,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
      decoration: InputDecoration(
        labelText: '$label *',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return '$label je obavezno polje.';
        if (isInt) {
          final n = int.tryParse(t);
          if (n == null || n <= 0) return 'Unesite cijeli broj veći od 0.';
        } else {
          final n = double.tryParse(t);
          if (n == null || n <= 0) return 'Unesite broj veći od 0.';
        }
        return null;
      },
    );
  }

  Widget _dateField(
    String label,
    DateTime? value,
    VoidCallback onTap, {
    bool required = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
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

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<RefOption> items,
    required ValueChanged<T?> onChanged,
    required String requiredLabel,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: '$label *',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final o in items)
          DropdownMenuItem<T>(value: o.id as T, child: Text(o.name)),
      ],
      validator: (v) => v == null ? requiredLabel : null,
      onChanged: onChanged,
    );
  }
}
