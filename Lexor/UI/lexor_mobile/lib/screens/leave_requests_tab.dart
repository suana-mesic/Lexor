import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_mobile/providers/leave_provider.dart';
import 'package:lexor_mobile/screens/create_leave_request.dart';
import 'package:lexor_mobile/widgets/error_view.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:provider/provider.dart';
import 'package:lexor_mobile/theme/app_colors.dart';

class LeaveRequestsTab extends StatefulWidget {
  const LeaveRequestsTab({super.key});

  @override
  State<LeaveRequestsTab> createState() => _LeaveRequestsTabState();
}

class _LeaveRequestsTabState extends State<LeaveRequestsTab> {
  int _selectedFilter = 0;
  String? _currentFilter;
  final ScrollController _scrollController = ScrollController();

  static const _filters = ['Svi', 'Na čekanju', 'Odobreni', 'Odbijeni'];
  static const _stateFilters = <LeaveStateType?>[
    null,
    LeaveStateType.pending,
    LeaveStateType.approved,
    LeaveStateType.rejected,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveProvider>(
        context,
        listen: false,
      ).fetchLeaves(reset: true);
    });
    _scrollController.addListener(() {
      final provider = Provider.of<LeaveProvider>(context, listen: false);
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        provider.fetchLeaves(stateFilter: _currentFilter);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildStatusChip(String? state) {
    final (label, bg, fg) = switch (LeaveStateType.fromApi(state)) {
      LeaveStateType.pending => (
        'Na čekanju',
        AppColors.warningBg,
        AppColors.warningDark,
      ),
      LeaveStateType.approved => (
        'Odobren',
        AppColors.successBg,
        AppColors.successDark,
      ),
      LeaveStateType.rejected => (
        'Odbijen',
        AppColors.errorBg,
        AppColors.error,
      ),
      LeaveStateType.cancelled => (
        'Otkazan',
        AppColors.neutralBg,
        AppColors.neutralFg,
      ),
      _ => ('Nepoznato', AppColors.neutralBg, AppColors.neutralFg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaveProvider = Provider.of<LeaveProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFilterRow(context),
            const SizedBox(height: 16),
            _buildNewRequestButton(context),
            const SizedBox(height: 16),
            if (leaveProvider.error != null && leaveProvider.leaves.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ErrorView(
                  message: leaveProvider.error!,
                  onRetry: () =>
                      leaveProvider.fetchLeaves(reset: true, stateFilter: _currentFilter),
                ),
              )
            else
              ...leaveProvider.leaves.map((item) => _buildLeaveCard(item)),
            if (leaveProvider.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Moji zahtjevi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Row(
            children: [
              Icon(Icons.notifications, color: Colors.white, size: 26),
              SizedBox(width: 16),
              Icon(Icons.person, color: Colors.white, size: 26),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (i) {
        final selected = _selectedFilter == i;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: TextButton(
            onPressed: () {
              setState(
                () => {
                  _selectedFilter = i,
                  _currentFilter = _stateFilters[i]?.apiValue,
                },
              );
              Provider.of<LeaveProvider>(
                context,
                listen: false,
              ).fetchLeaves(stateFilter: _stateFilters[i]?.apiValue, reset: true);
            },
            style: TextButton.styleFrom(
              backgroundColor: selected
                  ? AppColors.primary
                  : Colors.transparent,
              foregroundColor: selected ? Colors.white : Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(_filters[i], style: const TextStyle(fontSize: 13)),
          ),
        );
      }),
      ),
    );
  }

  Widget _buildNewRequestButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateLeaveRequest()),
          );
          if (result == 'reload' && context.mounted) {
            Provider.of<LeaveProvider>(
              context,
              listen: false,
            ).fetchLeaves(reset: true);
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Novi zahtjev',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLeaveCard(item) {
    final dateFormat = DateFormat('dd.MM');
    final yearFormat = DateFormat('dd.MM.yyyy');
    final dateRange =
        '${dateFormat.format(item.dateFrom)} — ${yearFormat.format(item.dateTo)}';

    final canEdit = item.allowedActions.contains('UpdateAsync');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySoftBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.leaveType.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateRange,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${item.numberOfDays} dana',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(item.state),
                  ],
                ),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateLeaveRequest(leave: item),
                  ),
                );

                if (result == 'reload' && context.mounted) {
                  Provider.of<LeaveProvider>(
                    context,
                    listen: false,
                  ).fetchLeaves(reset: true);
                }
              },
            ),
        ],
      ),
    );
  }
}
