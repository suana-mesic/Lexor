import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/helpers/image_decode.dart';
import 'package:lexor_desktop/models/employee_response.dart';
import 'package:lexor_desktop/models/search_result.dart';
import 'package:lexor_desktop/providers/employee_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/pagination_bar.dart';
import 'package:lexor_shared/lexor_shared.dart';

/// Read-only employee directory for the accounting role. It only calls GET /Employees, so it
/// never touches the HR/admin-only reference endpoints the full HR screen depends on, and it
/// exposes no create/edit/delete controls.
class EmployeesReadonlyScreen extends StatefulWidget {
  const EmployeesReadonlyScreen({super.key});

  @override
  State<EmployeesReadonlyScreen> createState() => _EmployeesReadonlyScreenState();
}

class _EmployeesReadonlyScreenState extends State<EmployeesReadonlyScreen> {
  final EmployeeProvider _provider = EmployeeProvider();
  final TextEditingController _search = TextEditingController();
  final NumberFormat _money = NumberFormat('#,##0.00');

  SearchResult<EmployeeResponse>? _result;
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    _provider.dispose();
    super.dispose();
  }

  List<EmployeeResponse> get _items => _result?.items ?? [];
  int get _totalCount => _result?.totalCount ?? 0;
  int get _totalPages => _totalCount <= 0 ? 1 : (_totalCount / _pageSize).ceil();

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final q = _search.text.trim();
      _result = await _provider.get(
        filter: {
          'page': _page,
          'pageSize': _pageSize,
          'includeTotalCount': true,
          'sortBy': 'Id',
          if (q.isNotEmpty) 'fullName': q,
        },
      );
    } catch (e) {
      _error = messageFor(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySearch() {
    _page = 1;
    _load();
  }

  String _initials(String n) {
    final p = n.trim().split(RegExp(r'\s+'));
    if (p.isEmpty || p[0].isEmpty) return '?';
    return (p.length == 1 ? p[0][0] : p[0][0] + p[1][0]).toUpperCase();
  }

  /// Profile photo next to the name (guideline 6), initials when there is none.
  Widget _avatar(EmployeeResponse e) {
    final thumb = e.user.profileThumbnailBase64;
    if (thumb != null && thumb.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: MemoryImage(cachedImageBytes(thumb)),
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primary,
      child: Text(_initials(e.user.fullName),
          style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Uposlenici (pregled)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _search,
                  onSubmitted: (_) => _applySearch(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Pretraži po imenu',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      onPressed: _applySearch,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) return Center(child: Text(_error!));
    if (_items.isEmpty) {
      return const Center(
        child: Text('Nema uposlenika za prikaz.', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _row(_items[i]),
    );
  }

  Widget _row(EmployeeResponse e) {
    final contract = e.activeContract;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          _avatar(e),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  '${e.department?.name ?? '—'} · ${e.position?.name ?? '—'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          if (contract != null) ...[
            Text('${_money.format(contract.brutoSalary)} KM',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 16),
          ],
          _statusChip(e.isActive),
        ],
      ),
    );
  }

  Widget _statusChip(bool active) {
    final (Color fg, Color bg, String label) = active
        ? (AppColors.success, AppColors.successBg, 'Aktivan')
        : (AppColors.grey, const Color(0xFFEEEEEE), 'Neaktivan');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
