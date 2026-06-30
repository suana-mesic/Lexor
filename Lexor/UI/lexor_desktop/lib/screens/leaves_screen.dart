import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/models/leave_response.dart';
import 'package:lexor_desktop/models/search_result.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_desktop/providers/leave_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/pagination_bar.dart';
import 'package:lexor_shared/lexor_shared.dart';

/// Admin view of all leave/absence requests ("Zahtjevi"). Read-only table for
/// now; per-status actions (approve/reject/cancel) are added separately.
class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  final LeaveProvider _provider = LeaveProvider();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();

  SearchResult<LeaveResponse>? _result;
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  static const int _pageSize = 10;

  List<RefOption> _leaveTypes = const [];
  int? _leaveTypeFilter;

  // Fixed row heights so the table always shows a whole number of rows
  // (no partially-visible "peeking" row). Rows beyond what fits are reached via
  // the table's own vertical scroll.
  static const double _kHeaderRowHeight = 48;
  static const double _kDataRowHeight = 64;

  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadLeaveTypes();
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

  List<LeaveResponse> get _items => _result?.items ?? [];
  int get _totalCount => _result?.totalCount ?? 0;
  int get _totalPages =>
      _totalCount <= 0 ? 1 : (_totalCount / _pageSize).ceil();

  Future<void> _loadLeaveTypes() async {
    try {
      _leaveTypes = await fetchRefOptions('/LeaveTypes');
      if (mounted) setState(() {});
    } catch (_) {
      // The type filter is optional UX — silently fall back to "Svi tipovi".
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
          'sortBy': 'CreatedAt desc',
          if (_searchController.text.trim().isNotEmpty)
            'employeeName': _searchController.text.trim(),
          if (_leaveTypeFilter != null) 'leaveTypeId': _leaveTypeFilter,
        },
      );
    } catch (e) {
      _error = messageFor(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    _page = 1;
    _load();
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _tableCard()),
        ],
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
    final search = _filterField(
      'Pretraži po uposleniku',
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

    final type = _filterField(
      'Tip zahtjeva',
      DropdownButtonFormField<int?>(
        initialValue: _leaveTypeFilter,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('Svi tipovi')),
          for (final t in _leaveTypes)
            DropdownMenuItem<int?>(value: t.id, child: Text(t.name)),
        ],
        onChanged: (v) => setState(() => _leaveTypeFilter = v),
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
          // Width needed to lay everything out on a single line.
          const inlineWidth = 280 + 240 + 16 * 2 + 150;
          if (constraints.maxWidth >= inlineWidth) {
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(width: 280, child: search),
                SizedBox(width: 240, child: type),
                button,
              ],
            );
          }
          // Narrow: search and the type filter both span the full width so their
          // right edges line up; the button sits below.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 12),
              type,
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
      children: [
        Text(label),
        const SizedBox(height: 6),
        child,
      ],
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
        child: Text('Nema zahtjeva.', style: TextStyle(color: Colors.grey)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 880.0;
        final needsHScroll = constraints.maxWidth < minTableWidth;
        final tableWidth =
            needsHScroll ? minTableWidth : constraints.maxWidth;

        // Show as many WHOLE rows as fit (no partial "peeking" row). Any rows
        // beyond that are reached via the table's own vertical scroll — the
        // page itself never scrolls, so there's only ever one vertical scrollbar.
        final fit =
            ((constraints.maxHeight - _kHeaderRowHeight) / _kDataRowHeight)
                .floor();
        final maxRows = fit < 1 ? 1 : fit;
        final shown = _items.length < maxRows ? _items.length : maxRows;
        final hasMore = _items.length > shown;
        final viewport = _kHeaderRowHeight + shown * _kDataRowHeight;

        // Horizontal scroll wraps the FULL body height so its scrollbar always
        // sits at the bottom of the table area; the rows are snapped to whole
        // rows and top-aligned within.
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
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                          4: FlexColumnWidth(1),
                          5: FlexColumnWidth(2),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        border: TableBorder(
                          horizontalInside:
                              BorderSide(color: Colors.grey.shade200),
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
    // Fixed height per cell keeps every row uniform so the viewport shows a
    // whole number of rows (no partial "peeking" row).
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

  TableRow _buildHeaderTableRow() {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey[50]),
      children: [
        _tableCell(const Text('Uposlenik', style: style),
            isFirst: true, isHeader: true),
        _tableCell(const Text('Tip zahtjeva', style: style), isHeader: true),
        _tableCell(const Text('Od', style: style), isHeader: true),
        _tableCell(const Text('Do', style: style), isHeader: true),
        _tableCell(const Text('Dani', style: style), isHeader: true),
        _tableCell(const Text('Status', style: style),
            isLast: true, isHeader: true),
      ],
    );
  }

  TableRow _buildDataTableRow(LeaveResponse l) {
    return TableRow(
      children: [
        _tableCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  _initials(l.employeeFullName),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.employeeFullName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          isFirst: true,
        ),
        _tableCell(Text(l.leaveType.name, overflow: TextOverflow.ellipsis)),
        _tableCell(Text(_dateFormat.format(l.dateFrom))),
        _tableCell(Text(_dateFormat.format(l.dateTo))),
        _tableCell(Text('${l.numberOfDays}')),
        _tableCell(_statusBadge(l.status), isLast: true),
      ],
    );
  }

  Widget _statusBadge(LeaveStateType? status) {
    final (Color fg, Color bg) = switch (status) {
      LeaveStateType.pending => (AppColors.warning, AppColors.warningBg),
      LeaveStateType.approved => (AppColors.success, AppColors.successBg),
      LeaveStateType.rejected => (AppColors.error, AppColors.errorBg),
      LeaveStateType.cancelled => (AppColors.grey, const Color(0xFFEEEEEE)),
      null => (AppColors.grey, const Color(0xFFEEEEEE)),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status?.label ?? 'Nepoznato',
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
