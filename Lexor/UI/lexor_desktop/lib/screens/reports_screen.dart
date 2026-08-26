import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/models/salary_slip_response.dart';
import 'package:lexor_desktop/models/search_result.dart';
import 'package:lexor_desktop/helpers/pdf_download.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_desktop/providers/employee_provider.dart';
import 'package:lexor_desktop/providers/salary_slip_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/person_avatar.dart';
import 'package:lexor_desktop/widgets/app_notify.dart';
import 'package:lexor_desktop/widgets/pagination_bar.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:provider/provider.dart';

/// Admin reporting module. For accounting it lists PAID salary slips for a chosen year/month
/// and offers a per-employee payslip and a monthly payroll summary as PDF; for HR it adds the
/// monthly attendance report. Which reports are shown follows the signed-in user's role.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SalarySlipProvider _provider = SalarySlipProvider();
  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();

  SearchResult<SalarySlipResponse>? _result;
  bool _isLoading = false;
  bool _generated = false;
  String? _error;
  int _page = 1;
  static const int _pageSize = 10;

  int? _year;
  int? _month;
  int? _employeeId; // null = all employees
  List<RefOption> _employees = const [];

  /// HR gets the attendance report; accounting does not (the endpoint rejects them), so the
  /// card is only built for the role that can actually use it.
  late final bool _isHr;

  /// The attendance report has its own period so choosing one does not disturb the payroll
  /// selection the user may already have made above.
  int? _attendanceYear;
  int? _attendanceMonth;
  bool _downloadingAttendance = false;

  static const double _kHeaderRowHeight = 48;
  static const double _kDataRowHeight = 64;
  final NumberFormat _money = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    // Reports show PAID salaries (for completed months) → default to the previous
    // month, handling the January → December-of-last-year rollover.
    final now = DateTime.now();
    if (now.month == 1) {
      _year = now.year - 1;
      _month = 12;
    } else {
      _year = now.year;
      _month = now.month - 1;
    }
    _attendanceYear = _year;
    _attendanceMonth = _month;
    _isHr = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).roles.contains('HRManager');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generated = true;
      _loadEmployees();
      _load();
    });
  }

  Future<void> _loadEmployees() async {
    try {
      final list = await fetchEmployeeOptions();
      if (mounted) setState(() => _employees = list);
    } catch (_) {
      // Employee filter is optional UX — silently fall back to "all employees".
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
  int get _totalPages =>
      _totalCount <= 0 ? 1 : (_totalCount / _pageSize).ceil();

  String _km(double v) => '${_money.format(v)} KM';

  Future<void> _load() async {
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
          'status': 2, // Paid
          if (_employeeId != null) 'employeeId': _employeeId,
        },
      );
    } catch (e) {
      _error = messageFor(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generate() {
    if (_year == null || _month == null) {
      showSnack(context, 'Odaberite godinu i mjesec.', error: true);
      return;
    }
    _generated = true;
    _page = 1;
    _load();
  }

  Future<void> _downloadSlip(SalarySlipResponse s) async {
    final name = s.employeeFullName.replaceAll(' ', '-');
    try {
      final path = await _provider.downloadSlipPdf(
        s.id,
        'platna-lista-$name-${s.year}-${s.month.toString().padLeft(2, '0')}.pdf',
      );
      if (!mounted || path == null) return;
      showSnack(context, 'Sačuvano: $path');
    } catch (e) {
      if (mounted) showSnack(context, messageFor(e), error: true);
    }
  }

  Future<void> _downloadMonthlyReport() async {
    if (_year == null || _month == null) {
      showSnack(context, 'Odaberite godinu i mjesec.', error: true);
      return;
    }
    try {
      final path = await _provider.downloadMonthlyReport(
        _year!,
        _month!,
        employeeId: _employeeId,
      );
      if (!mounted || path == null) return;
      showSnack(context, 'Sačuvano: $path');
    } catch (e) {
      if (mounted) showSnack(context, messageFor(e), error: true);
    }
  }

  Future<void> _downloadAttendanceReport() async {
    if (_attendanceYear == null || _attendanceMonth == null) {
      showSnack(context, 'Odaberite godinu i mjesec.', error: true);
      return;
    }
    setState(() => _downloadingAttendance = true);
    try {
      final path = await downloadPdf(
        '/Attendances/report/pdf?year=$_attendanceYear&month=$_attendanceMonth',
        'izvjestaj-prisustva-$_attendanceYear-'
            '${_attendanceMonth.toString().padLeft(2, '0')}.pdf',
      );
      if (!mounted || path == null) return; // null = save dialog cancelled
      showSnack(context, 'Sačuvano: $path');
    } catch (e) {
      if (mounted) showSnack(context, messageFor(e), error: true);
    } finally {
      if (mounted) setState(() => _downloadingAttendance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _generateCard(),
          if (_isHr) ...[
            const SizedBox(height: 20),
            _attendanceReportCard(),
          ],
          const SizedBox(height: 20),
          Expanded(child: _tableCard()),
        ],
      ),
    );
  }

  /// Monthly attendance report (HR only): days present, days on approved leave, working days
  /// with no record at all, and hours worked - per employee, grouped by department.
  Widget _attendanceReportCard() {
    final now = DateTime.now();
    final years = [for (var y = now.year; y >= now.year - 3; y--) y];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Izvještaj evidencije radnog vremena',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Po uposleniku i odjelu: dani prisustva, odobrena odsustva, '
            'dani bez evidencije i odrađeni sati.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 140,
                child: _labeled(
                  'Godina',
                  DropdownButtonFormField<int>(
                    initialValue: _attendanceYear,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final y in years)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (v) => setState(() => _attendanceYear = v),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 180,
                child: _labeled(
                  'Mjesec',
                  DropdownButtonFormField<int>(
                    initialValue: _attendanceMonth,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(
                          value: m,
                          child: Text(bosnianMonthName(m)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _attendanceMonth = v),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _downloadingAttendance
                    ? null
                    : _downloadAttendanceReport,
                icon: _downloadingAttendance
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download, size: 18),
                label: const Text('Preuzmi PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _generateCard() {
    final now = DateTime.now();
    final years = [for (var y = now.year; y >= now.year - 3; y--) y];

    final yearField = _labeled(
      'Godina',
      DropdownButtonFormField<int>(
        initialValue: _year,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          for (final y in years) DropdownMenuItem(value: y, child: Text('$y')),
        ],
        onChanged: (v) => setState(() => _year = v),
      ),
    );
    final monthField = _labeled(
      'Mjesec',
      DropdownButtonFormField<int>(
        initialValue: _month,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          for (var m = 1; m <= 12; m++)
            DropdownMenuItem(value: m, child: Text(bosnianMonthName(m))),
        ],
        onChanged: (v) => setState(() => _month = v),
      ),
    );
    final employeeField = _labeled(
      'Uposlenik',
      Autocomplete<RefOption>(
        displayStringForOption: (o) => o.name,
        optionsBuilder: (value) {
          final q = value.text.trim().toLowerCase();
          if (q.isEmpty) return _employees;
          return _employees.where((e) => e.name.toLowerCase().contains(q));
        },
        onSelected: (o) => setState(() => _employeeId = o.id),
        fieldViewBuilder: (context, controller, focusNode, onSubmit) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              hintText: 'Svi uposlenici',
              suffixIcon: controller.text.isEmpty
                  ? const Icon(Icons.search, size: 18)
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Poništi',
                      onPressed: () {
                        controller.clear();
                        setState(() => _employeeId = null);
                      },
                    ),
            ),
            // Only an exact name match selects an employee; anything else (partial or
            // empty text) falls back to "all employees" so a stale id is never used.
            onChanged: (v) {
              final match = _employees.where(
                (e) => e.name.toLowerCase() == v.trim().toLowerCase(),
              );
              setState(() => _employeeId = match.isEmpty ? null : match.first.id);
            },
          );
        },
      ),
    );
    final generateBtn = ElevatedButton(
      onPressed: _generate,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      child: const Text('Prikaži plate'),
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
          const Text(
            'Generiši izvještaj',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(width: 180, child: yearField),
              SizedBox(width: 180, child: monthField),
              SizedBox(width: 240, child: employeeField),
              generateBtn,
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Prikazuju se samo realizovane isplate.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Plaćene plate',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
          const Divider(height: 1),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Tooltip(
                  message: _employeeId != null
                      ? 'Dostupno samo za pregled svih uposlenika. '
                            'Za pojedinca koristite PDF u redu tabele.'
                      : 'Preuzmi zbirni izvještaj za odabrani period. '
                            'Zbirni izvještaji nisu dostupni kada je odabran uposlenik.',
                  child: OutlinedButton.icon(
                    // Aggregate report only makes sense for the whole workforce; when a single
                    // employee is filtered, their individual payslip PDF (row action) is used.
                    onPressed:
                        (_generated && _totalCount > 0 && _employeeId == null)
                        ? _downloadMonthlyReport
                        : null,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Zbirni PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PaginationBar(
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_generated) {
      return const Center(
        child: Text(
          'Odaberite period i prikažite plate.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) return Center(child: Text(_error!));
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'Nema realizovanih isplata za odabrani period.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 980.0;
        final needsHScroll = constraints.maxWidth < minTableWidth;
        final tableWidth = needsHScroll ? minTableWidth : constraints.maxWidth;
        final fit =
            ((constraints.maxHeight - _kHeaderRowHeight) / _kDataRowHeight)
                .floor();
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
                      physics: hasMore
                          ? null
                          : const NeverScrollableScrollPhysics(),
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
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        children: [_headerRow(), ..._items.map(_dataRow)],
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

  Widget _cell(
    Widget child, {
    bool isFirst = false,
    bool isLast = false,
    bool isHeader = false,
  }) {
    return Container(
      height: isHeader ? _kHeaderRowHeight : _kDataRowHeight,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(
        left: isFirst ? 20 : 12,
        right: isLast ? 20 : 12,
      ),
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
          Row(
            children: [
              PersonAvatar(
                fullName: sl.employeeFullName,
                thumbnailBase64: sl.employeeThumbnail,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sl.employeeFullName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          isFirst: true,
        ),
        _cell(Text(_money.format(sl.brutoSalary))),
        _cell(Text(_money.format(sl.totalContributions))),
        _cell(Text(_money.format(sl.tax))),
        _cell(
          Text(
            _money.format(sl.netSalary),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        _cell(_paidBadge()),
        _cell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                color: AppColors.primary,
                tooltip: 'Detalji',
                visualDensity: VisualDensity.compact,
                onPressed: () => _showDetail(sl),
              ),
              IconButton(
                icon: const Icon(Icons.download, size: 20),
                color: AppColors.primary,
                tooltip: 'Preuzmi PDF',
                visualDensity: VisualDensity.compact,
                onPressed: () => _downloadSlip(sl),
              ),
            ],
          ),
          isLast: true,
        ),
      ],
    );
  }

  Widget _paidBadge() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Plaćen',
        style: TextStyle(
          color: AppColors.success,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Future<void> _showDetail(SalarySlipResponse row) async {
    // The list omits `items` (only aggregates); fetch the full slip for the breakdown.
    SalarySlipResponse sl;
    try {
      sl = await _provider.getById(row.id);
    } catch (e) {
      if (mounted) showSnack(context, messageFor(e), error: true);
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${sl.employeeFullName} — Bruto ${_km(sl.brutoSalary)}'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Stavka',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Stopa',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Iznos',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(),
              for (final i in sl.items ?? <SalarySlipItem>[])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(i.name)),
                      Expanded(
                        child: Text(
                          i.rate == null ? '—' : '${i.rate}%',
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Text(_km(i.amount), textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'Neto plata',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  Expanded(
                    child: Text(
                      _km(sl.netSalary),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zatvori'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _downloadSlip(sl);
            },
            icon: const Icon(Icons.download),
            label: const Text('Preuzmi PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
