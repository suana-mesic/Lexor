import 'package:flutter/material.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/models/payroll_settings_response.dart';
import 'package:lexor_desktop/providers/payroll_settings_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/app_notify.dart';

class PayrollSettingsScreen extends StatefulWidget {
  const PayrollSettingsScreen({super.key});

  @override
  State<PayrollSettingsScreen> createState() => _PayrollSettingsScreenState();
}

class _PayrollSettingsScreenState extends State<PayrollSettingsScreen> {
  final _provider = PayrollSettingsProvider();

  PayrollSettingsResponse? _current;
  bool _loading = true;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  DateTime? _validFrom;
  String _workDays = 'Pon-Pet';
  final _overtime = TextEditingController(text: '1.3');
  final _deduction = TextEditingController(text: '300');
  final _pio = TextEditingController(text: '17');
  final _health = TextEditingController(text: '12.5');
  final _unemployment = TextEditingController(text: '1.5');
  final _tax = TextEditingController(text: '10');
  bool _saving = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrent());
  }

  @override
  void dispose() {
    for (final c in [
      _overtime,
      _deduction,
      _pio,
      _health,
      _unemployment,
      _tax,
    ]) {
      c.dispose();
    }
    _provider.dispose();
    super.dispose();
  }

  void _loadCurrent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _current = await _provider.getCurrent();
    } catch (e) {
      _error = messageFor(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentCard(),
          const SizedBox(height: 24),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );

  Widget _buildCurrentCard() {
    if (_loading) {
      return _card(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    if (_error != null) return _card(child: Text(_error!));

    final c = _current;
    if (c == null) {
      return _card(child: const Text('Trenutno nema važećih stopa.'));
    }

    final money = NumberFormat('#,##0.00', 'de_DE');
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trenutno važeće stope',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Više kolona na širem ekranu → manje redova → niža kartica.
              final cols = constraints.maxWidth >= 1000
                  ? 4
                  : constraints.maxWidth >= 550
                      ? 2
                      : 1;
              final itemWidth =
                  (constraints.maxWidth - 40 * (cols - 1)) / cols;
              return Wrap(
                spacing: 40,
                runSpacing: 16,
                children: [
                  _readItem(
                    'Važi od',
                    DateFormat('dd.MM.yyyy').format(c.validFrom),
                    itemWidth,
                  ),
                  _readItem('Radni dani', _workDaysLabel(c), itemWidth),
                  _readItem(
                    'Koeficijent prekovremenih',
                    '${c.overtimeMultiplier}',
                    itemWidth,
                  ),
                  _readItem(
                    'Lični odbitak (KM)',
                    money.format(c.personalDeduction),
                    itemWidth,
                  ),
                  _readItem('Stopa PIO/MIO (%)', '${c.pioMioRate}', itemWidth),
                  _readItem(
                    'Stopa zdravstvenog (%)',
                    '${c.healthInsuranceRate}',
                    itemWidth,
                  ),
                  _readItem(
                    'Stopa za nezaposlene (%)',
                    '${c.unemploymentRate}',
                    itemWidth,
                  ),
                  _readItem(
                    'Porez na dohodak (%)',
                    '${c.incomeTaxRate}',
                    itemWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _readItem(String label, String value, double width) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  String _workDaysLabel(PayrollSettingsResponse c) {
    if (c.workDaysDescription.trim().isNotEmpty) return c.workDaysDescription;
    return _maskToLabel(c.workDaysMask);
  }

  String _maskToLabel(int mask) {
    if (mask == 31) return 'Pon-Pet'; // Pon-Pet
    if (mask == 63) return 'Pon-Sub'; // Pon-Sub
    if (mask == 127) return 'Pon-Ned'; // svi dani
    const days = ['Pon', 'Uto', 'Sri', 'Čet', 'Pet', 'Sub', 'Ned'];
    final active = <String>[];
    for (var i = 0; i < 7; i++) {
      if ((mask & (1 << i)) != 0) active.add(days[i]);
    }
    return active.isEmpty ? '—' : active.join(', ');
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    showSnack(context, msg, error: error);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _validFrom ?? now,
    );
    if (picked != null) setState(() => _validFrom = picked);
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();

    if (_validFrom == null) {
      setState(() => _formError = 'Datum važenja je obavezan');
      return;
    }

    if (!formOk) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      await _provider.insert({
        'validFrom': DateFormat('yyyy-MM-dd').format(_validFrom!),
        'workDaysDescription': _workDays,
        'overtimeMultiplier': double.parse(_overtime.text.trim()),
        'personalDeduction': double.parse(_deduction.text.trim()),
        'pioMioRate': double.parse(_pio.text.trim()),
        'healthInsuranceRate': double.parse(_health.text.trim()),
        'unemploymentRate': double.parse(_unemployment.text.trim()),
        'incomeTaxRate': double.parse(_tax.text.trim()),
      });

      _snack('Nove stope sačuvane');
      _loadCurrent();
    } catch (e) {
      setState(() => _formError = messageFor(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildForm() {
    return _card(
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 2 kolone na širokom ekranu (4 polja po koloni), 1 na uskom.
            final cols = constraints.maxWidth >= 550 ? 2 : 1;
            final fieldWidth =
                (constraints.maxWidth - 16 * (cols - 1)) / cols;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dodaj nove stope',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _dateField(fieldWidth),
                    _dropdownField(fieldWidth),
                    _numField(
                      'Koeficijent prekovremenih',
                      _overtime,
                      fieldWidth,
                      greaterThanZero: true,
                    ),
                    _numField(
                      'Lični odbitak (KM)',
                      _deduction,
                      fieldWidth,
                      min: 0,
                    ),
                    _numField(
                      'Stopa PIO/MIO (%)',
                      _pio,
                      fieldWidth,
                      min: 0,
                      max: 100,
                    ),
                    _numField(
                      'Stopa zdravstvenog osiguranja (%)',
                      _health,
                      fieldWidth,
                      min: 0,
                      max: 100,
                    ),
                    _numField(
                      'Stopa za nezaposlene (%)',
                      _unemployment,
                      fieldWidth,
                      min: 0,
                      max: 100,
                    ),
                    _numField(
                      'Porez na dohodak (%)',
                      _tax,
                      fieldWidth,
                      min: 0,
                      max: 100,
                    ),
                  ],
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _formError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
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
                        : const Text('Sačuvaj nove stope'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dateField(double width) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Važi od *'),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            child: Text(
              _validFrom == null
                  ? 'Odaberite datum'
                  : DateFormat('dd.MM.yyyy').format(_validFrom!),
              style: TextStyle(
                color: _validFrom == null ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _dropdownField(double width) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Radni dani u sedmici'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _workDays,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'Pon-Pet', child: Text('Pon-Pet')),
            DropdownMenuItem(value: 'Pon-Sub', child: Text('Pon-Sub')),
            DropdownMenuItem(value: 'Pon-Ned', child: Text('Pon-Ned')),
          ],
          onChanged: (v) => setState(() => _workDays = v ?? 'Pon-Pet'),
        ),
      ],
    ),
  );

  Widget _numField(
    String label,
    TextEditingController c,
    double width, {
    double? min,
    double? max,
    bool greaterThanZero = false,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          TextFormField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return 'Obavezno polje.';
              final n = double.tryParse(t);
              if (n == null) return 'Unesite broj.';
              if (greaterThanZero && n <= 0) return 'Mora biti veći od 0.';
              if (min != null && n < min) return 'Najmanje $min.';
              if (max != null && n > max) return 'Najviše $max.';
              return null;
            },
          ),
        ],
      ),
    );
  }
}
