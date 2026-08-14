import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/models/employee_response.dart';
import 'package:lexor_desktop/providers/contract_provider.dart';
import 'package:lexor_desktop/providers/contract_type_option.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_shared/lexor_shared.dart';

/// Dialog for "Dodaj novi ugovor" — calls the server's atomic replace endpoint
/// which closes the currently active contract (if any) and creates the new one
/// in a single transaction.
class NewContractDialog extends StatefulWidget {
  final ContractProvider provider;
  final int employeeId;
  final EmployeeContractResponse? currentActive;
  final List<ContractTypeOption> contractTypes;

  const NewContractDialog({
    super.key,
    required this.provider,
    required this.employeeId,
    required this.currentActive,
    required this.contractTypes,
  });

  @override
  State<NewContractDialog> createState() => _NewContractDialogState();
}

class _NewContractDialogState extends State<NewContractDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _contractTypeId;
  DateTime? _startDate;
  DateTime? _endDate;
  final _brutoSalary = TextEditingController();
  final _workHours = TextEditingController();
  bool _saving = false;
  String? _error;

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

  @override
  void dispose() {
    _brutoSalary.dispose();
    _workHours.dispose();
    super.dispose();
  }

  // Minimum start date for the new contract:
  // - If active contract is fixed-term (has EndDate): must start the day after it expires.
  // - If active contract is indefinite (no EndDate): must start after its start date.
  // - No active contract: allow dates from 5 years ago.
  DateTime _minStartDate(DateTime now) {
    final a = widget.currentActive;
    if (a == null) return DateTime(now.year - 5);
    if (a.endDate != null) return a.endDate!.toLocal().add(const Duration(days: 1));
    return a.startDate.toLocal().add(const Duration(days: 1));
  }

  // Gap exists when active contract has a defined EndDate and the selected start date
  // is more than one day after that EndDate (employment break period).
  bool get _hasGap {
    final a = widget.currentActive;
    if (a == null || a.endDate == null || _startDate == null) return false;
    return _startDate!.isAfter(a.endDate!.toLocal().add(const Duration(days: 1)));
  }

  Future<void> _pick(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? (_minStartDate(now).isAfter(now) ? _minStartDate(now) : now))
          : (_endDate ?? _startDate ?? now),
      firstDate: isStart ? _minStartDate(now) : (_startDate ?? now),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      setState(() => _error = 'Datum početka je obavezan.');
      return;
    }
    if (_needsEndDate && _endDate == null) {
      setState(() => _error = 'Datum kraja je obavezan za odabrani tip ugovora.');
      return;
    }

    // Scenario A: active contract is indefinite — confirm automatic closure.
    final active = widget.currentActive;
    if (active != null && active.endDate == null) {
      final dayBefore = _startDate!.subtract(const Duration(days: 1));
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Potvrda zatvaranja ugovora'),
          content: Text(
            'Dodavanjem novog ugovora koji počinje '
            '${DateFormat('dd.MM.yyyy').format(_startDate!)} datum isteka '
            'aktivnog ugovora na Neodređeno bit će automatski postavljen na '
            '${DateFormat('dd.MM.yyyy').format(dayBefore)}.',
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
      await widget.provider.replaceActive(widget.employeeId, {
        'contractTypeId': _contractTypeId,
        'startDate': _startDate!.toIso8601String(),
        if (_needsEndDate) 'endDate': _endDate!.toIso8601String(),
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
      title: const Text('Dodaj novi ugovor'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.currentActive != null && widget.currentActive!.endDate == null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.info, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Trenutni ugovor (${widget.currentActive!.contractTypeName}, '
                          '${widget.currentActive!.brutoSalary.toStringAsFixed(2)} KM) '
                          'biće automatski zatvoren danom prije početka novog.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.currentActive != null && widget.currentActive!.endDate == null)
                const SizedBox(height: 16),
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
                validator: (v) => v == null
                    ? 'Tip ugovora je obavezno polje.'
                    : null,
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
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Napomena o prekidu kontinuiteta: Unosom datuma '
                          '${DateFormat('dd.MM.yyyy').format(_startDate!)} kreirate prekid '
                          'radnog odnosa od '
                          '${DateFormat('dd.MM.yyyy').format(widget.currentActive!.endDate!.toLocal().add(const Duration(days: 1)))} '
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
              // End date shown only when the contract type requires it
              // (e.g. fixed-term). Hidden for indefinite so the form
              // doesn't suggest an unused field.
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
                  if (n == null || n <= 0) {
                    return 'Unesite plate veću od 0.';
                  }
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
