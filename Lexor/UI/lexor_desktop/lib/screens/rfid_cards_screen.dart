import 'package:flutter/material.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/models/rfid_response.dart';
import 'package:lexor_desktop/models/search_result.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_desktop/providers/rfid_card_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/app_notify.dart';
import 'package:lexor_desktop/widgets/pagination_bar.dart';
import 'package:lexor_desktop/providers/employee_provider.dart';

class RfidCardsScreen extends StatefulWidget {
  const RfidCardsScreen({super.key});

  @override
  State<RfidCardsScreen> createState() => _RfidCardsScreenState();
}

class _RfidCardsScreenState extends State<RfidCardsScreen> {
  final RfidCardProvider _provider = RfidCardProvider();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();

  SearchResult<RfidResponse>? _result;
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  static const int _pageSize = 10;
  String? _statusFilter; // null = 'All', 'Active', 'Inactive'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  List<RfidResponse> get _items => _result?.items ?? [];
  int get _totalCount => _result?.totalCount ?? 0;
  int get _totalPages =>
      _totalCount <= 0 ? 1 : (_totalCount / _pageSize).ceil();

  @override
  void dispose() {
    _searchController.dispose();
    _hScroll.dispose();
    _vScroll.dispose();
    _provider.dispose();
    super.dispose();
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
          'sortBy': 'AssignedAt desc',

          if (_searchController.text.trim().isNotEmpty)
            'employeeName': _searchController.text.trim(),

          if (_statusFilter != null) 'activityStatus': _statusFilter,
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

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    showSnack(context, msg, error: error);
  }

  Future<void> _deactivate(RfidResponse rfidCard) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deaktivacija kartice'),
        content: Text(
          'Deaktivirati karticu za "${rfidCard.employeeFullName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deaktiviraj'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _provider.deactivate(rfidCard.id);
      _snack('Kartica deaktivirana');
      await _load();
    } catch (e) {
      _snack(messageFor(e), error: true);
    }
  }

  Future<void> _reactivate(RfidResponse rfidCard) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reaktivacija kartice'),
        content: Text(
          'Ponovo aktivirati karticu za "${rfidCard.employeeFullName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reaktiviraj'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _provider.reactivate(rfidCard.id);
      _snack('Kartica reaktivirana');
      await _load();
    } catch (e) {
      _snack(messageFor(e), error: true);
    }
  }

  Future<void> _openAddDialog() async {
    List<RefOption> employees;
    try {
      employees = await fetchEmployeeOptions();
    } catch (e) {
      _snack(messageFor(e), error: true);
      return;
    }

    if (employees.isEmpty) {
      _snack('Prvo dodajte uposlenike prije dodavanja kartice.', error: true);
      return;
    }

    // Pre-load which employees already have an active card so the form can warn
    // immediately. The backend enforces the same rule authoritatively.
    Set<int> activeEmployeeIds = {};
    try {
      final active = await _provider.get(filter: {
        'activityStatus': 'Active',
        'page': 1,
        'pageSize': 1000,
      });
      activeEmployeeIds = active.items.map((c) => c.employee.id).toSet();
    } catch (_) {
      // Non-fatal — fall back to the backend check if this lookup fails.
    }

    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddRfidDialog(
        employees: employees,
        activeEmployeeIds: activeEmployeeIds,
        onSubmit: (employeeId, uid) => _provider.insert({
          'employeeId': employeeId,
          'uid': uid,
          'isActive': true,
        }),
      ),
    );

    if (saved == true) {
      _snack('Kartica dodana');
      _page = 1;
      await _load();
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // Fixed row heights so the table always shows a whole number of rows
  // (no partially-visible "peeking" row). Rows beyond what fits are reached via
  // the table's own vertical scroll.
  static const double _kHeaderRowHeight = 48;
  static const double _kDataRowHeight = 64;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _openAddDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Dodaj karticu'),
            ),
          ),
          const SizedBox(height: 16),
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
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final search = _filterField(
      'Pretraži',
      TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Pretraži po uposleniku',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onSubmitted: (_) => _applyFilter(),
      ),
    );

    final status = _filterField(
      'Status',
      DropdownButtonFormField<String?>(
        initialValue: _statusFilter,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: const [
          DropdownMenuItem(value: null, child: Text('Sve')),
          DropdownMenuItem(value: 'Active', child: Text('Aktivna')),
          DropdownMenuItem(value: 'Inactive', child: Text('Neaktivna')),
        ],
        onChanged: (v) => setState(() => _statusFilter = v),
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
          const inlineWidth = 280 + 180 + 16 * 2 + 150;
          if (constraints.maxWidth >= inlineWidth) {
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(width: 280, child: search),
                SizedBox(width: 180, child: status),
                button,
              ],
            );
          }
          // Narrow: search and Status both span the full width so their right
          // edges line up; the button sits below.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 12),
              status,
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
        child: Text('Nema kartica.', style: TextStyle(color: Colors.grey)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 720.0;
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
                          2: FlexColumnWidth(3),
                          3: FlexColumnWidth(2),
                          4: IntrinsicColumnWidth(),
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
        _tableCell(const Text('Uposlenik', style: style), isFirst: true, isHeader: true),
        _tableCell(const Text('UID kartice', style: style), isHeader: true),
        _tableCell(const Text('Datum dodjele', style: style), isHeader: true),
        _tableCell(const Text('Status', style: style), isHeader: true),
        _tableCell(const Text('Akcije', style: style), isLast: true, isHeader: true),
      ],
    );
  }

  TableRow _buildDataTableRow(RfidResponse card) {
    return TableRow(
      children: [
        _tableCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  _initials(card.employeeFullName),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  card.employeeFullName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          isFirst: true,
        ),
        _tableCell(Text(card.uid)),
        _tableCell(Text(DateFormat('dd.MM.yyyy').format(card.assignedAt.toLocal()))),
        _tableCell(_statusBadge(card.isActive)),
        _tableCell(
          card.isActive
              ? IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Deaktiviraj',
                  icon: const Icon(
                    Icons.power_settings_new,
                    color: AppColors.error,
                  ),
                  onPressed: () => _deactivate(card),
                )
              : IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Reaktiviraj',
                  icon: const Icon(
                    Icons.power_settings_new,
                    color: AppColors.success,
                  ),
                  onPressed: () => _reactivate(card),
                ),
          isLast: true,
        ),
      ],
    );
  }

  Widget _statusBadge(bool active) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.successBg : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          active ? 'Aktivna' : 'Neaktivna',
          style: TextStyle(
            color: active ? AppColors.success : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() => PaginationBar(
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
  );
}

class _AddRfidDialog extends StatefulWidget {
  final List<RefOption> employees;
  final Set<int> activeEmployeeIds;
  final Future<void> Function(int employeeId, String uid) onSubmit;

  const _AddRfidDialog({
    required this.employees,
    required this.activeEmployeeIds,
    required this.onSubmit,
  });

  @override
  State<_AddRfidDialog> createState() => _AddRfidDialogState();
}

class _AddRfidDialogState extends State<_AddRfidDialog> {
  final _formKey = GlobalKey<FormState>();
  final _uidController = TextEditingController();
  int? _employeeId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // One active card per employee — warn before hitting the server.
    if (widget.activeEmployeeIds.contains(_employeeId)) {
      final name = widget.employees
          .firstWhere((e) => e.id == _employeeId,
              orElse: () => const RefOption(0, ''))
          .name;
      setState(() => _error =
          'Uposlenik $name već ima aktivnu karticu. Potrebno je prvo '
          'deaktivirati staru karticu kako bi se nova mogla dodati.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSubmit(_employeeId!, _uidController.text.trim());
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
      title: const Text('Dodaj karticu'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _employeeId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Uposlenik',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final e in widget.employees)
                    DropdownMenuItem(value: e.id, child: Text(e.name)),
                ],
                validator: (v) =>
                    v == null ? 'Uposlenik je obavezno polje.' : null,
                onChanged: (v) => setState(() {
                  _employeeId = v;
                  _error = null;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _uidController,
                decoration: InputDecoration(
                  labelText: 'UID kartice',
                  hintText: 'npr. A3:F2:91:BC',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'UID je obavezno polje.';
                  if (!RegExp(r'[0-9A-Fa-f:]+$').hasMatch(value)) {
                    return 'UID može sadržavati samo hex znakove (0-9, A-F) i dvotačke.';
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
}
