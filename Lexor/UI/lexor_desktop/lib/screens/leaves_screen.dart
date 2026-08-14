import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/models/leave_response.dart';
import 'package:lexor_desktop/models/search_result.dart';
import 'package:lexor_desktop/providers/auth_provider.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_desktop/providers/leave_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/app_notify.dart';
import 'package:lexor_desktop/widgets/pagination_bar.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:provider/provider.dart';

/// Admin view of all leave/absence requests ("Zahtjevi"). Per-status actions
/// (approve / reject / cancel) are driven by the server's `allowedActions`.
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
      children: [Text(label), const SizedBox(height: 6), child],
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
        const minTableWidth = 980.0;
        final needsHScroll = constraints.maxWidth < minTableWidth;
        final tableWidth = needsHScroll ? minTableWidth : constraints.maxWidth;

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
        _tableCell(
          const Text('Uposlenik', style: style),
          isFirst: true,
          isHeader: true,
        ),
        _tableCell(const Text('Tip zahtjeva', style: style), isHeader: true),
        _tableCell(const Text('Od', style: style), isHeader: true),
        _tableCell(const Text('Do', style: style), isHeader: true),
        _tableCell(const Text('Dani', style: style), isHeader: true),
        _tableCell(const Text('Status', style: style), isHeader: true),
        _tableCell(
          const Text('Akcije', style: style),
          isLast: true,
          isHeader: true,
        ),
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
        _tableCell(_statusBadge(l.status)),
        _tableCell(_actionsCell(l), isLast: true),
      ],
    );
  }

  /// Action icons are driven by the server's `allowedActions`:
  /// - Pending  → Odobri (✓) + Odbij (✗)
  /// - Approved → Poništi (only if it hasn't started yet)
  /// - terminal states → no actions
  Widget _actionsCell(LeaveResponse l) {
    final currentUserId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).userId;
    final isOwnRequest = l.employee?.user.id == currentUserId;

    final actions = l.allowedActions;
    final canApprove = actions.contains('ApproveAsync');
    final canReject = actions.contains('RejectAsync');
    // Cancel is shown on the panel only for Approved requests (admin override), not for Pending.
    final canCancel = actions.contains('CancelAsync') && !canApprove;

    // Own pending request → show an explanation instead of Approve/Reject.
    if (isOwnRequest && (canApprove || canReject || canCancel)) {
      return Tooltip(
        message: 'Ne možete odlučivati o vlastitom zahtjevu za odsustvo.',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              'Vaš zahtjev',
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

    final showApprove = !isOwnRequest && canApprove;
    final showReject = !isOwnRequest && canReject;
    final showCancel = !isOwnRequest && canCancel;

    if (!showApprove && !showReject && !showCancel) {
      return Text('—', style: TextStyle(color: Colors.grey[400]));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showApprove)
          IconButton(
            icon: const Icon(Icons.check, size: 20),
            color: AppColors.success,
            tooltip: 'Odobri',
            visualDensity: VisualDensity.compact,
            onPressed: () => _approve(l),
          ),
        if (showReject)
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.error,
            tooltip: 'Odbij',
            visualDensity: VisualDensity.compact,
            onPressed: () => _reject(l),
          ),
        if (showCancel)
          IconButton(
            icon: const Icon(Icons.cancel_outlined, size: 20),
            color: AppColors.grey,
            tooltip: 'Poništi',
            visualDensity: VisualDensity.compact,
            onPressed: () => _cancel(l),
          ),
      ],
    );
  }

  Future<void> _approve(LeaveResponse l) async {
    final ok = await _confirm(
      title: 'Odobri zahtjev',
      message:
          'Odobriti zahtjev za odsustvo uposlenika '
          '${l.employeeFullName}?',
      confirmLabel: 'Odobri',
      confirmColor: AppColors.success,
    );
    if (ok != true) return;
    await _runAction(() => _provider.approve(l.id), 'Zahtjev odobren');
  }

  Future<void> _cancel(LeaveResponse l) async {
    final result = await _askCancellationReason(l);
    if (result == null) return; // dialog dismissed
    final reason = result.isEmpty ? null : result;
    await _runAction(() => _provider.cancel(l.id, reason), 'Zahtjev poništen');
  }

  Future<void> _reject(LeaveResponse l) async {
    final reason = await _askRejectionReason(l);
    if (reason == null) return; // cancelled the dialog
    await _runAction(() => _provider.reject(l.id, reason), 'Zahtjev odbijen');
  }

  /// Runs a state-changing action, then reloads the list and shows feedback.
  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!mounted) return;
      showSnack(context, successMessage);
      await _load();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, messageFor(e), error: true);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  /// Reject requires a reason (enforced on the server too). Returns the reason,
  /// or null if the admin cancels the dialog.
  Future<String?> _askRejectionReason(LeaveResponse l) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) {
        String? error;
        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            title: const Text('Odbij zahtjev'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Razlog odbijanja zahtjeva uposlenika '
                    '${l.employeeFullName}:',
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    maxLength: 1000,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Unesite razlog…',
                      border: const OutlineInputBorder(),
                      errorText: error,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Otkaži'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) {
                    setLocalState(() => error = 'Razlog je obavezan.');
                    return;
                  }
                  Navigator.pop(context, text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Odbij'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Cancellation reason is optional. Returns the text (possibly empty) on confirm,
  // or null if the admin dismissed the dialog.
  Future<String?> _askCancellationReason(LeaveResponse l) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Poništi zahtjev'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Poništiti odobreni zahtjev uposlenika ${l.employeeFullName}?',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Razlog (opcionalno)',
                  hintText: 'Unesite razlog poništavanja…',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // null → dismissed
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Poništi'),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(LeaveStateType? status) {
    final (Color fg, Color bg) = switch (status) {
      LeaveStateType.pending => (AppColors.warning, AppColors.warningBg),
      LeaveStateType.approved => (AppColors.success, AppColors.successBg),
      LeaveStateType.rejected => (AppColors.error, AppColors.errorBg),
      LeaveStateType.cancelled => (AppColors.grey, const Color(0xFFEEEEEE)),
      LeaveStateType.completed => (AppColors.info, AppColors.infoBg),
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
