import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/helpers/image_decode.dart';
import 'package:lexor_desktop/models/employee_response.dart';
import 'package:lexor_desktop/models/search_result.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_desktop/providers/contract_provider.dart';
import 'package:lexor_desktop/providers/contract_type_option.dart';
import 'package:lexor_desktop/providers/employee_provider.dart';
import 'package:lexor_desktop/providers/position_option.dart';
import 'package:lexor_desktop/screens/employee_add_dialog.dart';
import 'package:lexor_desktop/screens/employee_details_dialog.dart';
import 'package:lexor_desktop/screens/employee_edit_dialog.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/app_notify.dart';
import 'package:lexor_desktop/widgets/pagination_bar.dart';
import 'package:lexor_shared/lexor_shared.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final EmployeeProvider _provider = EmployeeProvider();
  final ContractProvider _contractProvider = ContractProvider();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();

  SearchResult<EmployeeResponse>? _result;
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  static const int _pageSize = 10;

  List<RefOption> _departments = const [];
  List<RefOption> _cachedCities = const [];
  List<PositionOption> _cachedPositions = const [];
  List<ContractTypeOption> _cachedContractTypes = const [];
  int? _departmentFilter;
  String? _statusFilter; // null = Sve, 'Active', 'Inactive'

  Future<({List<RefOption> cities, List<RefOption> departments, List<PositionOption> positions, List<ContractTypeOption> contractTypes})>
      _loadRefOptions() async {
    if (_cachedCities.isNotEmpty &&
        _departments.isNotEmpty &&
        _cachedPositions.isNotEmpty &&
        _cachedContractTypes.isNotEmpty) {
      return (
        cities: _cachedCities,
        departments: _departments,
        positions: _cachedPositions,
        contractTypes: _cachedContractTypes,
      );
    }
    // Kick off in parallel; await typed futures individually so we don't have
    // to do runtime casts (Future.wait collapses heterogeneous element types).
    final citiesF = fetchRefOptions('/Cities');
    final departmentsF = fetchRefOptions('/Departments');
    final positionsF = fetchPositionOptions();
    final contractTypesF = fetchContractTypeOptions();
    _cachedCities = await citiesF;
    _departments = await departmentsF;
    _cachedPositions = await positionsF;
    _cachedContractTypes = await contractTypesF;
    return (
      cities: _cachedCities,
      departments: _departments,
      positions: _cachedPositions,
      contractTypes: _cachedContractTypes,
    );
  }

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
    _contractProvider.dispose();
    super.dispose();
  }

  List<EmployeeResponse> get _items => _result?.items ?? [];
  int get _totalCount => _result?.totalCount ?? 0;
  int get _totalPages =>
      _totalCount <= 0 ? 1 : (_totalCount / _pageSize).ceil();

  Future<void> _loadDepartments() async {
    try {
      _departments = await fetchRefOptions('/Departments');
      if (mounted) setState(() {});
    } catch (_) {
      // Department dropdown is optional UX — silent fallback to "Sve".
    }
  }

  Future<({List<RefOption> cities, List<RefOption> departments, List<PositionOption> positions, List<ContractTypeOption> contractTypes})?>
      _ensureRefOptions() async {
    try {
      return await _loadRefOptions();
    } catch (e) {
      if (mounted) showSnack(context, messageFor(e), error: true);
      return null;
    }
  }

  Future<void> _openDetails(EmployeeResponse e) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => EmployeeDetailsDialog(
        employeeProvider: _provider,
        employeeId: e.id,
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _openEdit(EmployeeResponse e) async {
    final refs = await _ensureRefOptions();
    if (refs == null || !mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmployeeEditDialog(
        provider: _provider,
        contractProvider: _contractProvider,
        employee: e,
        cities: refs.cities,
        departments: refs.departments,
        positions: refs.positions,
        contractTypes: refs.contractTypes,
      ),
    );
    if (saved == true) {
      if (!mounted) return;
      showSnack(context, 'Izmjene sačuvane');
      await _load();
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
          'sortBy': 'HireDate desc',
          if (_searchController.text.trim().isNotEmpty)
            'fullName': _searchController.text.trim(),
          if (_departmentFilter != null) 'departmentId': _departmentFilter,
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

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Profile photo next to the name (guideline 6). Falls back to initials for
  /// employees who never uploaded one.
  Widget _avatar(EmployeeResponse e) {
    final thumb = e.user.profileThumbnailBase64;
    if (thumb != null && thumb.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: MemoryImage(cachedImageBytes(thumb)),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary,
      child: Text(
        _initials(e.user.fullName),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Future<void> _openAddDialog() async {
    final refs = await _ensureRefOptions();
    if (refs == null || !mounted) return;

    // Reference data is a hard prerequisite — fail closed with a clear message
    // rather than show a half-empty form.
    if (refs.departments.isEmpty ||
        refs.positions.isEmpty ||
        refs.cities.isEmpty ||
        refs.contractTypes.isEmpty) {
      showSnack(
        context,
        'Prvo unesite gradove, odjele, pozicije i tipove ugovora.',
        error: true,
      );
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmployeeAddDialog(
        employeeProvider: _provider,
        contractProvider: _contractProvider,
        cities: refs.cities,
        departments: refs.departments,
        positions: refs.positions,
        contractTypes: refs.contractTypes,
      ),
    );

    if (saved == true) {
      if (!mounted) return;
      showSnack(context, 'Uposlenik dodan');
      _page = 1;
      await _load();
    }
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
              onPressed: _openAddDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Dodaj uposlenika'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
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
      'Pretraži',
      TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Pretraži po imenu ili prezimenu',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onSubmitted: (_) => _applyFilter(),
      ),
    );

    final odjel = _filterField(
      'Odjel',
      DropdownButtonFormField<int?>(
        initialValue: _departmentFilter,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('Sve')),
          for (final d in _departments)
            DropdownMenuItem<int?>(value: d.id, child: Text(d.name)),
        ],
        onChanged: (v) => setState(() => _departmentFilter = v),
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
          DropdownMenuItem(value: 'Active', child: Text('Aktivan')),
          DropdownMenuItem(value: 'Inactive', child: Text('Neaktivan')),
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
          const inlineWidth = 280 + 220 + 180 + 16 * 3 + 150;
          if (constraints.maxWidth >= inlineWidth) {
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(width: 280, child: search),
                SizedBox(width: 220, child: odjel),
                SizedBox(width: 180, child: status),
                button,
              ],
            );
          }
          // Narrow: search spans the full width; Odjel + Status split the row
          // below so the Status field's right edge lines up with the search
          // field's right edge.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: odjel),
                  const SizedBox(width: 16),
                  Expanded(child: status),
                ],
              ),
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
        child: Text('Nema uposlenika.', style: TextStyle(color: Colors.grey)),
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
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(3),
                          3: FlexColumnWidth(2),
                          4: FlexColumnWidth(2),
                          5: IntrinsicColumnWidth(),
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
        _tableCell(const Text('Odjel', style: style), isHeader: true),
        _tableCell(const Text('Pozicija', style: style), isHeader: true),
        _tableCell(const Text('Datum zaposlenja', style: style), isHeader: true),
        _tableCell(const Text('Status', style: style), isHeader: true),
        _tableCell(const Text('Akcije', style: style), isLast: true, isHeader: true),
      ],
    );
  }

  TableRow _buildDataTableRow(EmployeeResponse e) {
    return TableRow(
      children: [
        _tableCell(
          Row(
            children: [
              _avatar(e),
              const SizedBox(width: 12),
              Expanded(
                child: Text(e.user.fullName, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          isFirst: true,
        ),
        _tableCell(Text(e.department?.name ?? '-')),
        _tableCell(Text(e.position?.name ?? '-')),
        _tableCell(Text(DateFormat('dd.MM.yyyy').format(e.hireDate.toLocal()))),
        _tableCell(_statusBadge(e.isActive)),
        _tableCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Detalji',
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: AppColors.primary,
                ),
                onPressed: () => _openDetails(e),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Uredi',
                icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
                onPressed: () => _openEdit(e),
              ),
            ],
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
          active ? 'Aktivan' : 'Neaktivan',
          style: TextStyle(
            color: active ? AppColors.success : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
