import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/models/attendance_response.dart';
import 'package:lexor_desktop/models/search_result.dart';
import 'package:lexor_desktop/providers/attendance_provider.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/app_notify.dart';
import 'package:lexor_desktop/widgets/pagination_bar.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:provider/provider.dart';

/// Admin view of attendance records ("Evidencija prisustva"). An admin can
/// correct or delete other employees' records, but never their own.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceProvider _provider = AttendanceProvider();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();

  SearchResult<AttendanceResponse>? _result;
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  static const int _pageSize = 10;

  List<RefOption> _departments = const [];
  int? _departmentFilter;
  DateTime? _fromDate;
  DateTime? _toDate;

  // Fixed row heights so the table always shows a whole number of rows.
  static const double _kHeaderRowHeight = 48;
  static const double _kDataRowHeight = 56;

  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDepartments();
      await _load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hScroll.dispose();
    _vScroll.dispose();
    _provider.dispose();
    super.dispose();
  }

  List<AttendanceResponse> get _items => _result?.items ?? [];
  int get _totalCount => _result?.totalCount ?? 0;
  int get _totalPages => _totalCount <= 0 ? 1 : (_totalCount / _pageSize).ceil();

  Future<void> _loadDepartments() async {
    try {
      _departments = await fetchRefOptions('/Departments');
      if (mounted) setState(() {});
    } catch (_) {
      // The department filter is optional UX — silently fall back to "Svi".
    }
  }

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
          'sortBy': 'Date desc',
          if (_searchController.text.trim().isNotEmpty)
            'employeeName': _searchController.text.trim(),
          if (_departmentFilter != null) 'departmentId': _departmentFilter,
          if (_fromDate != null)
            'fromDate': DateFormat('yyyy-MM-dd').format(_fromDate!),
          if (_toDate != null)
            'toDate': DateFormat('yyyy-MM-dd').format(_toDate!),
        },
      );
    } catch (e) {
      _error = messageFor(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (_fromDate != null && _toDate != null && _fromDate!.isAfter(_toDate!)) {
      showSnack(context, 'Period "od" ne može biti nakon perioda "do".',
          error: true);
      return;
    }
    _page = 1;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: _tableCard())],
      ),
    );
  }

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
          _buildFilterBar(),
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

  Widget _buildFilterBar() {
    final from = _filterField(
      'Period od',
      _dateFilter('dd.MM.yyyy', _fromDate, (v) => setState(() => _fromDate = v)),
    );
    final to = _filterField(
      'Period do',
      _dateFilter('dd.MM.yyyy', _toDate, (v) => setState(() => _toDate = v)),
    );
    final employee = _filterField(
      'Uposlenik',
      TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Unesite ime uposlenika',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onSubmitted: (_) => _applyFilter(),
      ),
    );
    final department = _filterField(
      'Odjeljenje',
      DropdownButtonFormField<int?>(
        initialValue: _departmentFilter,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('Sva')),
          for (final d in _departments)
            DropdownMenuItem<int?>(value: d.id, child: Text(d.name)),
        ],
        onChanged: (v) => setState(() => _departmentFilter = v),
      ),
    );

    final button = ElevatedButton(
      onPressed: _applyFilter,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      child: const Text('Primijeni filter'),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const inlineWidth = 170 + 170 + 220 + 200 + 16 * 3 + 150;
          if (constraints.maxWidth >= inlineWidth) {
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(width: 170, child: from),
                SizedBox(width: 170, child: to),
                SizedBox(width: 220, child: employee),
                SizedBox(width: 200, child: department),
                button,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: from),
                  const SizedBox(width: 12),
                  Expanded(child: to),
                ],
              ),
              const SizedBox(height: 12),
              employee,
              const SizedBox(height: 12),
              department,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: button),
            ],
          );
        },
      ),
    );
  }

  Widget _filterField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(label), const SizedBox(height: 6), child],
    );
  }

  Widget _dateFilter(
    String hint,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 1),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today, size: 18)
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Očisti',
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(value == null ? '' : _dateFormat.format(value)),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(child: Text(_error!));
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('Nema evidencije.', style: TextStyle(color: Colors.grey)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 900.0;
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
                          4: FlexColumnWidth(1),
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
                        children: [
                          _buildHeaderTableRow(),
                          ..._items.map(_buildDataTableRow),
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

  Widget _tableCell(
    Widget child, {
    bool isFirst = false,
    bool isLast = false,
    bool isHeader = false,
  }) {
    return Container(
      height: isHeader ? _kHeaderRowHeight : _kDataRowHeight,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: isFirst ? 20 : 12, right: isLast ? 20 : 12),
      child: child,
    );
  }

  TableRow _buildHeaderTableRow() {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey[50]),
      children: [
        _tableCell(const Text('Ime i prezime', style: style),
            isFirst: true, isHeader: true),
        _tableCell(const Text('Datum', style: style), isHeader: true),
        _tableCell(const Text('Check-in', style: style), isHeader: true),
        _tableCell(const Text('Check-out', style: style), isHeader: true),
        _tableCell(const Text('Sati', style: style), isHeader: true),
        _tableCell(const Text('Odjeljenje', style: style), isHeader: true),
        _tableCell(const Text('Akcije', style: style),
            isLast: true, isHeader: true),
      ],
    );
  }

  TableRow _buildDataTableRow(AttendanceResponse a) {
    final checkIn = a.dateTimeEntered == null
        ? '-'
        : _timeFormat.format(a.dateTimeEntered!.toLocal());
    final checkOut = a.dateTimeLeft == null
        ? '-'
        : _timeFormat.format(a.dateTimeLeft!.toLocal());
    final hours =
        a.workedHours == null ? '-' : '${a.workedHours!.toStringAsFixed(1)}h';

    return TableRow(
      children: [
        _tableCell(
          Text(a.employeeFullName, overflow: TextOverflow.ellipsis),
          isFirst: true,
        ),
        _tableCell(Text(_dateFormat.format(a.date))),
        _tableCell(Text(checkIn)),
        _tableCell(Text(checkOut)),
        _tableCell(Text(hours)),
        _tableCell(Text(a.departmentName, overflow: TextOverflow.ellipsis)),
        _tableCell(_actionsCell(a), isLast: true),
      ],
    );
  }

  Widget _actionsCell(AttendanceResponse a) {
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).userId;
    final isOwn = a.employee?.user?.id == currentUserId;

    // An admin can't correct or delete their own attendance — show why instead.
    if (isOwn) {
      return Tooltip(
        message: 'Ne možete uređivati niti brisati vlastito prisustvo.',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              'Vaše prisustvo',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: AppColors.primary,
          tooltip: 'Uredi',
          visualDensity: VisualDensity.compact,
          onPressed: () => _edit(a),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          color: AppColors.error,
          tooltip: 'Obriši',
          visualDensity: VisualDensity.compact,
          onPressed: () => _delete(a),
        ),
      ],
    );
  }

  Future<void> _delete(AttendanceResponse a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Obriši evidenciju'),
        content: Text(
          'Obrisati evidenciju prisustva za ${a.employeeFullName} '
          '(${_dateFormat.format(a.date)})?',
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
    if (ok != true) return;
    try {
      await _provider.remove(a.id);
      if (!mounted) return;
      showSnack(context, 'Evidencija obrisana');
      await _load();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, messageFor(e), error: true);
    }
  }

  Future<void> _edit(AttendanceResponse a) async {
    final reasonController =
        TextEditingController(text: a.correctionReason ?? '');
    TimeOfDay? checkIn = a.dateTimeEntered == null
        ? null
        : TimeOfDay.fromDateTime(a.dateTimeEntered!.toLocal());
    TimeOfDay? checkOut = a.dateTimeLeft == null
        ? null
        : TimeOfDay.fromDateTime(a.dateTimeLeft!.toLocal());

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        String? error;
        bool saving = false;
        return StatefulBuilder(
          builder: (dialogContext, setLocal) {
            DateTime? combine(TimeOfDay? t) => t == null
                ? null
                : DateTime(a.date.year, a.date.month, a.date.day, t.hour, t.minute);

            Future<void> pick(bool isIn) async {
              final picked = await showTimePicker(
                context: dialogContext,
                initialTime: (isIn ? checkIn : checkOut) ?? TimeOfDay.now(),
              );
              if (picked != null) {
                setLocal(() => isIn ? checkIn = picked : checkOut = picked);
              }
            }

            Future<void> submit() async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                setLocal(() => error = 'Razlog korekcije je obavezan.');
                return;
              }
              if (checkIn == null && checkOut == null) {
                setLocal(() => error = 'Unesite bar jedno vrijeme.');
                return;
              }
              final inDt = combine(checkIn);
              final outDt = combine(checkOut);
              if (inDt != null && outDt != null && !outDt.isAfter(inDt)) {
                setLocal(() => error = 'Vrijeme izlaska mora biti nakon ulaska.');
                return;
              }
              setLocal(() {
                saving = true;
                error = null;
              });
              try {
                await _provider.update(a.id, {
                  'dateTimeEntered': inDt?.toUtc().toIso8601String(),
                  'dateTimeLeft': outDt?.toUtc().toIso8601String(),
                  'correctionReason': reason,
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (e) {
                setLocal(() {
                  saving = false;
                  error = messageFor(e);
                });
              }
            }

            return AlertDialog(
              title: const Text('Uredi prisustvo'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _roText('Uposlenik', a.employeeFullName),
                    _roText('Datum', _dateFormat.format(a.date)),
                    _roText('Odjeljenje', a.departmentName),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _timeField('Ulazak', checkIn, () => pick(true)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child:
                              _timeField('Izlazak', checkOut, () => pick(false)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Razlog korekcije *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (error != null)
                      Text(
                        error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.pop(dialogContext, false),
                  child: const Text('Otkaži'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Sačuvaj'),
                ),
              ],
            );
          },
        );
      },
    );

    reasonController.dispose();
    if (saved == true && mounted) {
      showSnack(context, 'Prisustvo ažurirano');
      await _load();
    }
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _roText(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(label, style: TextStyle(color: Colors.grey[600])),
            ),
            Expanded(
              child:
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  Widget _timeField(String label, TimeOfDay? time, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: const Icon(Icons.access_time, size: 18),
          ),
          child: Text(time == null ? '-' : _fmtTime(time)),
        ),
      );
}
