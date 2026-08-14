import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/models/employee_response.dart';
import 'package:lexor_desktop/providers/contract_provider.dart';
import 'package:lexor_desktop/providers/contract_type_option.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_shared/lexor_shared.dart';

class EditContractDialog extends StatefulWidget {
  final ContractProvider provider;
  final EmployeeContractResponse contract;
  final List<ContractTypeOption> contractTypes;
  final EmployeeContractResponse? activeContract;

  const EditContractDialog({
    super.key,
    required this.provider,
    required this.contract,
    required this.contractTypes,
    this.activeContract,
  });

  @override
  State<EditContractDialog> createState() => _EditContractDialogState();
}

class _EditContractDialogState extends State<EditContractDialog> {
  final _formKey = GlobalKey<FormState>();
  late int? _contractTypeId;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late final TextEditingController _brutoSalary;
  late final TextEditingController _workHours;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _contractTypeId = widget.contract.contractTypeId;
    _startDate = widget.contract.startDate.toLocal();
    _endDate = widget.contract.endDate?.toLocal();
    _brutoSalary = TextEditingController(
      text: widget.contract.brutoSalary.toStringAsFixed(2),
    );
    _workHours = TextEditingController(
      text: widget.contract.workHoursPerDay.toString(),
    );
  }

  @override
  void dispose() {
    _brutoSalary.dispose();
    _workHours.dispose();
    super.dispose();
  }

  bool get _needsEndDate {
    final t = widget.contractTypes.firstWhere(
      (c) => c.id == _contractTypeId,
      orElse: () =>
          const ContractTypeOption(id: 0, name: '', endDateRequired: false),
    );
    return t.endDateRequired;
  }

  // Whether the active contract is a fixed-term type, resolved from
  // the loaded contract types by the active contract's type id.
  bool get _activeIsFixedTerm {
    final a = widget.activeContract;
    if (a == null) return false;
    final t = widget.contractTypes.firstWhere(
      (c) => c.id == a.contractTypeId,
      orElse: () =>
          const ContractTypeOption(id: 0, name: '', endDateRequired: false),
    );
    return t.endDateRequired;
  }

  // Earliest start date allowed so this contract's period can't overlap the active
  // one: after a fixed-term contract ends, or after an open/linked (indefinite)
  // contract's start. Never earlier than tomorrow.
  DateTime get _minStartDate {
    final now = DateTime.now();
    final tomorrow =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final a = widget.activeContract;
    if (a == null) return tomorrow;
    final floor = (_activeIsFixedTerm && a.endDate != null)
        ? a.endDate!.toLocal().add(const Duration(days: 1))
        : a.startDate.toLocal().add(const Duration(days: 1));
    return floor.isAfter(tomorrow) ? floor : tomorrow;
  }

  Future<void> _pick(bool isStart) async {
    final now = DateTime.now();
    final minStart = _minStartDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? ((_startDate == null || _startDate!.isBefore(minStart))
                ? minStart
                : _startDate!)
          : (_endDate ?? _startDate ?? now.add(const Duration(days: 1))),
      firstDate: isStart ? minStart : (_startDate ?? minStart),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Returns true if changing this contract's start date will automatically
  // update the active indefinite contract's end date on the server.
  bool get _willShiftActiveEndDate {
    if (_startDate == null) return false;
    if (_isSameDay(_startDate!, widget.contract.startDate.toLocal())) {
      return false;
    }
    final a = widget.activeContract;
    if (a == null || a.endDate == null) return false;
    // Only an indefinite active contract is auto-closed. A fixed-term contract is
    // immutable, so its end date is never shifted — even if it happens to end the
    // day before this contract starts.
    if (_activeIsFixedTerm) return false;
    // Active contract is "linked" to this upcoming contract if its EndDate is
    // exactly one day before this contract's current StartDate.
    final linkedDate = widget.contract.startDate.toLocal().subtract(
      const Duration(days: 1),
    );
    return _isSameDay(a.endDate!.toLocal(), linkedDate);
  }

  // Gap exists when the active contract has a defined EndDate (fixed-term, or
  // an unlinked indefinite) and the selected start date leaves a break in
  // employment. Suppressed when the backend will auto-shift the EndDate.
  bool get _hasGap {
    final a = widget.activeContract;
    if (a == null || a.endDate == null || _startDate == null) return false;
    if (_willShiftActiveEndDate) return false;
    return _startDate!.isAfter(
      a.endDate!.toLocal().add(const Duration(days: 1)),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      setState(() => _error = 'Datum početka je obavezan.');
      return;
    }
    if (_needsEndDate && _endDate == null) {
      setState(
        () => _error = 'Datum kraja je obavezan za odabrani tip ugovora.',
      );
      return;
    }
    if (_startDate!.isBefore(_minStartDate)) {
      setState(
        () => _error =
            'Datum početka mora biti nakon završetka prethodnog ugovora.',
      );
      return;
    }

    if (_willShiftActiveEndDate) {
      final newDayBefore = _startDate!.subtract(const Duration(days: 1));
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Potvrda zatvaranja ugovora'),
          content: Text(
            'Pomicanjem datuma početka ugovora na '
            '${DateFormat('dd.MM.yyyy').format(_startDate!)} datum isteka '
            'aktivnog ugovora na Neodređeno bit će automatski ažuriran na '
            '${DateFormat('dd.MM.yyyy').format(newDayBefore)}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Potvrdi'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.provider.update(widget.contract.id, {
        'contractTypeId': _contractTypeId,
        'startDate': _startDate!.toIso8601String(),
        if (_needsEndDate && _endDate != null)
          'endDate': _endDate!.toIso8601String(),
        'brutoSalary': double.parse(_brutoSalary.text.trim()),
        'workHoursPerDay': int.parse(_workHours.text.trim()),
      });
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
      title: const Text('Uredi budući ugovor'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _contractTypeId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tip ugovora *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final c in widget.contractTypes)
                    DropdownMenuItem<int>(value: c.id, child: Text(c.name)),
                ],
                validator: (v) =>
                    v == null ? 'Tip ugovora je obavezno polje.' : null,
                onChanged: (v) => setState(() {
                  _contractTypeId = v;
                  if (!_needsEndDate) _endDate = null;
                }),
              ),
              const SizedBox(height: 12),
              _dateField('Datum početka *', _startDate, () => _pick(true)),
              if (_hasGap) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Napomena o prekidu kontinuiteta: Unosom datuma '
                          '${DateFormat('dd.MM.yyyy').format(_startDate!)} kreirate prekid '
                          'radnog odnosa od '
                          '${DateFormat('dd.MM.yyyy').format(widget.activeContract!.endDate!.toLocal().add(const Duration(days: 1)))} '
                          'do '
                          '${DateFormat('dd.MM.yyyy').format(_startDate!.subtract(const Duration(days: 1)))}. '
                          'U ovom periodu uposlenik neće biti osiguran i sistem neće obračunavati '
                          'platu. Datum možete naknadno urediti u postavkama ugovora.',
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
              if (_needsEndDate) ...[
                const SizedBox(height: 12),
                _dateField('Datum kraja *', _endDate, () => _pick(false)),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _brutoSalary,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Bruto plata (KM) *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Unesite platu veću od 0.';
                  if (n > 1000000) {
                    return 'Bruto plata ne može biti veća od 1.000.000 KM.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _workHours,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Radni sati dnevno *',
                  hintText: '8',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n < 1 || n > 24) {
                    return 'Broj radnih sati po danu mora biti između 1 i 24.';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
            ],
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

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
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
}
