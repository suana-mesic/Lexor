import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/models/salary_slip_response.dart';
import 'package:lexor_desktop/models/search_result.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_desktop/providers/employee_provider.dart';
import 'package:lexor_desktop/providers/salary_slip_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/person_avatar.dart';
import 'package:lexor_desktop/widgets/app_notify.dart';
import 'package:lexor_desktop/widgets/pagination_bar.dart';
import 'package:lexor_shared/lexor_shared.dart';

/// Admin payroll screen. Runs the monthly calculation (-> Pending) and drives
/// the Pending -> Approved -> Paid transitions, per row or in bulk.
class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final SalarySlipProvider _provider = SalarySlipProvider();
  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();

  SearchResult<SalarySlipResponse>? _result;
  bool _isLoading = false;
  bool _busy = false;
  String? _error;
  int _page = 1;
  static const int _pageSize = 10;

  int? _year;
  int? _month;

  // Employee view filter (table only — never scopes the calculation or bulk actions).
  int? _employeeId;
  List<RefOption> _employees = const [];

  static const double _kHeaderRowHeight = 48;
  static const double _kDataRowHeight = 64;
  final NumberFormat _money = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    // Payroll runs for the previous (completed) month; handle the January rollover.
    final now = DateTime.now();
    if (now.month == 1) {
      _year = now.year - 1;
      _month = 12;
    } else {
      _year = now.year;
      _month = now.month - 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _loadEmployees();
    });
  }

  Future<void> _loadEmployees() async {
    try {
      final list = await fetchEmployeeOptions();
      if (mounted) setState(() => _employees = list);
    } catch (_) {
      // Filter is optional UX — silently fall back to "no filter".
    }
  }

  @override
  void dispose() {
    _hScroll.dispose();
    _vScroll.dispose();
    _provider.dispose();
    super.dispose();
  }

  List<SalarySlipResponse> get _items => _result?.items ?? [];
  int get _totalCount => _result?.totalCount ?? 0;
  int get _totalPages => _totalCount <= 0 ? 1 : (_totalCount / _pageSize).ceil();

  bool get _loaded => _result != null;

  // Payroll can only run for a month that has fully ended (from the 1st of the next month).
  bool get _periodEnded {
    if (_year == null || _month == null) return false;
    final now = DateTime.now();
    return _year! < now.year || (_year! == now.year && _month! < now.month);
  }

  bool get _canCalculate =>
      !_isLoading &&
      !_busy &&
      _year != null &&
      _month != null &&
      _loaded &&
      _items.isEmpty &&
      _periodEnded &&
      _employeeId == null; // an empty FILTERED list must not read as "not yet calculated"
  bool get _hasPending => _items.any((s) => s.status == SalarySlipStatus.pending.code);
  bool get _hasApproved => _items.any((s) => s.status == SalarySlipStatus.approved.code);


  Future<void> _load() async {
    if (_year == null || _month == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _result = await _provider.get(
        filter: {
          'page': _page,
          'pageSize': _pageSize,
          'includeTotalCount': true,
          'sortBy': 'Id desc',
          'year': _year,
          'month': _month,
          if (_employeeId != null) 'employeeId': _employeeId,
        },
      );
    } catch (e) {
      _error = messageFor(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _reloadPeriod() {
    _page = 1;
    _load();
  }

  /// Runs the period calculation and reports how many payslips were actually
  /// generated. A count of 0 means no employee had a contract covering the
  /// period, so we warn instead of showing a misleading success message.
  Future<void> _runCalculation() async {
    setState(() => _busy = true);
    try {
      final count = await _provider.calculate(_year!, _month!);
      if (!mounted) return;
      if (count > 0) {
        showSnack(context, 'Obračun pokrenut: obračunato $count platnih lista.');
      } else {
        showSnack(
          context,
          'Nijedna platna lista nije obračunata — nijedan uposlenik nema '
          'ugovor koji pokriva odabrani period.',
          error: true,
        );
      }
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, messageFor(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(Future<void> Function() fn, String ok) async {
    setState(() => _busy = true);
    try {
      await fn();
      if (!mounted) return;
      showSnack(context, ok);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, messageFor(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String message, String confirmLabel) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Otkaži')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _runCard(),
          const SizedBox(height: 20),
          Expanded(child: _tableCard()),
        ],
      ),
    );
  }

  Widget _runCard() {
    final now = DateTime.now();
    final years = [for (var y = now.year; y >= now.year - 3; y--) y];

    final yearField = _labeled(
      'Godina',
      DropdownButtonFormField<int>(
        initialValue: _year,
        isExpanded: true,
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
        items: [for (final y in years) DropdownMenuItem(value: y, child: Text('$y'))],
        onChanged: (v) => setState(() {
          _year = v;
          _reloadPeriod();
        }),
      ),
    );
    final monthField = _labeled(
      'Mjesec',
      DropdownButtonFormField<int>(
        initialValue: _month,
        isExpanded: true,
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
        items: [
          for (var m = 1; m <= 12; m++)
            DropdownMenuItem(value: m, child: Text(bosnianMonthName(m))),
        ],
        onChanged: (v) => setState(() {
          _month = v;
          _reloadPeriod();
        }),
      ),
    );
    final runBtn = ElevatedButton(
      onPressed: _canCalculate ? _runCalculation : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      child: const Text('Pokreni obračun'),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pokreni obračun',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 640;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(width: 200, child: yearField),
                    const SizedBox(width: 16),
                    SizedBox(width: 200, child: monthField),
                    const SizedBox(width: 16),
                    runBtn,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  yearField,
                  const SizedBox(height: 12),
                  monthField,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: runBtn),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            !_periodEnded
                ? 'Obračun se može pokrenuti tek nakon što mjesec završi.'
                : _loaded && _items.isNotEmpty
                    ? 'Obračun za odabrani period je već pokrenut.'
                    : 'Pokreće obračun za sve aktivne uposlenike za odabrani period.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Table-only view filter, visually set apart from the "Pokreni obračun" card so it is never
  // mistaken for running payroll for a single employee. Clearing the field auto-removes the filter.
  Widget _filterBar() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt_outlined, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 10),
              // Expanded so the field shrinks with the window instead of forcing an overflow.
              Expanded(
                child: Autocomplete<RefOption>(
                  optionsBuilder: (value) {
                    final q = value.text.toLowerCase();
                    if (q.isEmpty) return _employees;
                    return _employees.where((e) => e.name.toLowerCase().contains(q));
                  },
                  displayStringForOption: (o) => o.name,
                  onSelected: (o) {
                    setState(() => _employeeId = o.id);
                    _page = 1;
                    _load();
                  },
                  fieldViewBuilder: (context, controller, focusNode, _) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (v) {
                        // Emptying the field removes an active filter automatically.
                        if (v.isEmpty && _employeeId != null) {
                          setState(() => _employeeId = null);
                          _page = 1;
                          _load();
                        }
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        labelText: 'Filtriraj po uposleniku',
                        prefixIcon: Icon(Icons.search, size: 18),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Filtrira samo prikaz platnih lista — ne pokreće obračun.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _labeled(String label, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(label), const SizedBox(height: 6), child],
      );

  Widget _tableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Text('Platne liste',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_employeeId == null && _hasPending)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _approveAll,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Odobri sve'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                if (_employeeId == null && (_hasApproved || _hasPending)) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: _hasPending
                        ? 'Sve plate moraju biti odobrene prije isplate.'
                        : 'Isplati sve odobrene plate',
                    child: ElevatedButton.icon(
                      // Only enabled once nothing is still pending (no partial payout).
                      onPressed: (_busy || _hasPending) ? null : _payAll,
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text('Isplati sve'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _filterBar(),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
          const Divider(height: 1),
          PaginationBar(
            shownCount: _items.length,
            totalCount: _totalCount,
            hasPrev: _page > 1,
            hasNext: _page < _totalPages,
            onPrev: () {
              _page--;
              _load();
            },
            onNext: () {
              _page++;
              _load();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _approveAll() async {
    if (!await _confirm('Odobri sve',
        'Da li ste sigurni da želite odobriti sve obračunate plate za odabrani period?',
        'Odobri sve')) {
      return;
    }
    await _action(() => _provider.approveAll(_year!, _month!), 'Sve plate odobrene');
  }

  Future<void> _payAll() async {
    if (!await _confirm('Isplati sve',
        'Da li ste sigurni da želite isplatiti sve odobrene plate za odabrani period?',
        'Isplati sve')) {
      return;
    }
    await _action(() => _provider.payAll(_year!, _month!), 'Sve plate isplaćene');
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) return Center(child: Text(_error!));
    if (_items.isEmpty) {
      // Scrollable so the placeholder centers when there is room but never overflows a short viewport.
      return LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                        _employeeId != null
                            ? 'Nema platnih lista za odabranog uposlenika u ovom periodu.'
                            : 'Pokrenite obračun za odabrani period\nda biste vidjeli platne liste.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 980.0;
        final needsHScroll = constraints.maxWidth < minTableWidth;
        final tableWidth = needsHScroll ? minTableWidth : constraints.maxWidth;
        final fit = ((constraints.maxHeight - _kHeaderRowHeight) / _kDataRowHeight).floor();
        final maxRows = fit < 1 ? 1 : fit;
        final shown = _items.length < maxRows ? _items.length : maxRows;
        final hasMore = _items.length > shown;
        final viewport = _kHeaderRowHeight + shown * _kDataRowHeight;

        return Scrollbar(
          controller: _hScroll,
          thumbVisibility: needsHScroll,
          child: SingleChildScrollView(
            controller: _hScroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: tableWidth,
                  height: viewport,
                  child: Scrollbar(
                    controller: _vScroll,
                    thumbVisibility: hasMore,
                    child: SingleChildScrollView(
                      controller: _vScroll,
                      physics: hasMore ? null : const NeverScrollableScrollPhysics(),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                          4: FlexColumnWidth(2),
                          5: FlexColumnWidth(2),
                          6: IntrinsicColumnWidth(),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey.shade200),
                        ),
                        children: [
                          _headerRow(),
                          ..._items.map(_dataRow),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cell(Widget child,
      {bool isFirst = false, bool isLast = false, bool isHeader = false}) {
    return Container(
      height: isHeader ? _kHeaderRowHeight : _kDataRowHeight,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: isFirst ? 20 : 12, right: isLast ? 20 : 12),
      child: child,
    );
  }

  TableRow _headerRow() {
    const s = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey[50]),
      children: [
        _cell(const Text('Uposlenik', style: s), isFirst: true, isHeader: true),
        _cell(const Text('Bruto (KM)', style: s), isHeader: true),
        _cell(const Text('Doprinosi (KM)', style: s), isHeader: true),
        _cell(const Text('Porez (KM)', style: s), isHeader: true),
        _cell(const Text('Neto (KM)', style: s), isHeader: true),
        _cell(const Text('Status', style: s), isHeader: true),
        _cell(const Text('Akcije', style: s), isLast: true, isHeader: true),
      ],
    );
  }

  TableRow _dataRow(SalarySlipResponse sl) {
    return TableRow(
      children: [
        _cell(
          Row(children: [
            PersonAvatar(
              fullName: sl.employeeFullName,
              thumbnailBase64: sl.employeeThumbnail,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(sl.employeeFullName, overflow: TextOverflow.ellipsis)),
          ]),
          isFirst: true,
        ),
        _cell(Text(_money.format(sl.brutoSalary))),
        _cell(Text(_money.format(sl.totalContributions))),
        _cell(Text(_money.format(sl.tax))),
        _cell(Text(_money.format(sl.netSalary),
            style: const TextStyle(fontWeight: FontWeight.bold))),
        _cell(_statusBadge(sl.status)),
        _cell(_actions(sl), isLast: true),
      ],
    );
  }

  Widget _statusBadge(int status) {
    final st = SalarySlipStatus.fromCode(status);
    final (Color fg, Color bg) = switch (st) {
      SalarySlipStatus.pending => (AppColors.warning, AppColors.warningBg),
      SalarySlipStatus.approved => (AppColors.info, AppColors.infoBg),
      SalarySlipStatus.paid => (AppColors.success, AppColors.successBg),
      null => (AppColors.grey, const Color(0xFFEEEEEE)),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(st?.label ?? 'Nepoznato',
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _actions(SalarySlipResponse sl) {
    final empId = sl.employee.id;
    if (sl.status == SalarySlipStatus.pending.code) {
      return TextButton.icon(
        onPressed: _busy
            ? null
            : () => _action(() => _provider.approveSingle(_year!, _month!, empId),
                'Plata odobrena'),
        icon: const Icon(Icons.check, size: 18),
        label: const Text('Odobri'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      );
    }
    if (sl.status == SalarySlipStatus.approved.code) {
      return TextButton.icon(
        onPressed: _busy
            ? null
            : () => _action(
                () => _provider.paySingle(_year!, _month!, empId), 'Plata isplaćena'),
        icon: const Icon(Icons.payments_outlined, size: 18),
        label: const Text('Isplati'),
        style: TextButton.styleFrom(foregroundColor: AppColors.success),
      );
    }
    return Text('—', style: TextStyle(color: Colors.grey[400]));
  }
}
