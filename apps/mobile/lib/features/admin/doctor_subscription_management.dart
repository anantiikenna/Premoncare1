import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import 'admin_avatar.dart';
import 'admin_scaffold.dart';

class DoctorSubscriptionManagement extends ConsumerStatefulWidget {
  const DoctorSubscriptionManagement({super.key});

  @override
  ConsumerState<DoctorSubscriptionManagement> createState() =>
      _DoctorSubscriptionManagementState();
}

class _DoctorSubscriptionManagementState
    extends ConsumerState<DoctorSubscriptionManagement> {
  bool _loading = true;
  String _error = '';
  String _selectedFilter = 'all';
  String _searchQuery = '';

  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _allSubscriptions = [];

  int _totalDoctors = 0;
  int _activeCount = 0;
  int _expiringSoonCount = 0;
  int _expiredCount = 0;
  int _overdueCount = 0;
  int _suspendedCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  Future<void> _fetchSubscriptions() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final client = Supabase.instance.client;

      final response = await client
          .from('doctor_subscriptions')
          .select(
            '*, profiles!doctor_subscriptions_doctor_id_fkey(id, full_name, email, avatar_url, role, subscription_status, subscription_expires_at), subscription_plans!doctor_subscriptions_plan_id_fkey(name, price, duration_months)',
          )
          .order('expiry_date', ascending: true);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        response,
      );

      int active = 0;
      int expiringSoon = 0;
      int expired = 0;
      int overdue = 0;
      int suspended = 0;

      for (final sub in data) {
        final status = sub['status'] as String? ?? 'inactive';
        switch (status) {
          case 'active':
            active++;
            break;
          case 'expiring_soon':
            expiringSoon++;
            break;
          case 'expired':
            expired++;
            break;
          case 'overdue':
            overdue++;
            break;
          case 'suspended':
            suspended++;
            break;
        }
      }

      final doctorCountResponse = await client
          .from('profiles')
          .select('id')
          .eq('role', 'doctor');

      if (mounted) {
        setState(() {
          _allSubscriptions = data;
          _totalDoctors = doctorCountResponse.length;
          _activeCount = active;
          _expiringSoonCount = expiringSoon;
          _expiredCount = expired;
          _overdueCount = overdue;
          _suspendedCount = suspended;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _applyFilter() {
    List<Map<String, dynamic>> filtered = List.from(_allSubscriptions);
    if (_selectedFilter != 'all') {
      filtered = filtered.where((s) => s['status'] == _selectedFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        final profile = s['profiles'] as Map<String, dynamic>?;
        final plan = s['subscription_plans'] as Map<String, dynamic>?;
        final name = (profile?['full_name'] as String? ?? '').toLowerCase();
        final email = (profile?['email'] as String? ?? '').toLowerCase();
        final planName = (plan?['name'] as String? ?? '').toLowerCase();
        return name.contains(q) || email.contains(q) || planName.contains(q);
      }).toList();
    }
    setState(() => _subscriptions = filtered);
  }

  String _getFilterCount(String filter) {
    switch (filter) {
      case 'all':
        return _allSubscriptions.length.toString();
      case 'active':
        return _activeCount.toString();
      case 'expiring_soon':
        return _expiringSoonCount.toString();
      case 'expired':
        return _expiredCount.toString();
      case 'overdue':
        return _overdueCount.toString();
      case 'suspended':
        return _suspendedCount.toString();
      default:
        return '0';
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₦0';
    final num = double.tryParse(amount.toString()) ?? 0;
    return '₦${num.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  String _formatExpiry(String? expiryDate) {
    if (expiryDate == null) return 'N/A';
    final expiry = DateTime.tryParse(expiryDate);
    if (expiry == null) return 'N/A';
    final now = DateTime.now();
    final diff = expiry.difference(now).inDays;
    if (diff < 0) return 'Expired ${-diff}d ago';
    if (diff == 0) return 'Expires today';
    return 'Expires in $diff days';
  }

  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'expiring_soon':
        return 'Expiring Soon';
      case 'expired':
        return 'Expired';
      case 'overdue':
        return 'Overdue';
      case 'suspended':
        return 'Suspended';
      case 'inactive':
        return 'Inactive';
      default:
        return status ?? 'Unknown';
    }
  }

  List<Map<String, dynamic>> _getExpiringSoon() {
    final now = DateTime.now();
    final sevenDays = now.add(const Duration(days: 7));
    return _allSubscriptions
        .where((s) {
          final expiry = DateTime.tryParse(s['expiry_date'] as String? ?? '');
          if (expiry == null) return false;
          return s['status'] == 'expiring_soon' ||
              (s['status'] == 'active' && expiry.isBefore(sevenDays));
        })
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 4,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load subscriptions',
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error,
                    style: TextStyle(
                      color: AppColors.textTertiaryOf(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _fetchSubscriptions,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchSubscriptions,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildMetricsGrid(),
                    const SizedBox(height: 24),
                    _buildFilterTabs(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    _buildSubscriptionTable(),
                    const SizedBox(height: 24),
                    _buildBulkActions(),
                    const SizedBox(height: 32),
                    _buildAnalyticsSection(),
                    const SizedBox(height: 32),
                    _buildLowerGrids(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surfaceOf(context),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _MetricCard(
              label: 'Total Doctors',
              value: '$_totalDoctors',
              trend: '',
              trendColor: AppColors.success,
              icon: Icons.people_outline_rounded,
              iconColor: AppColors.primary,
            ),
            _MetricCard(
              label: 'Active',
              value: '$_activeCount',
              trend: _totalDoctors > 0
                  ? '${(_activeCount / _totalDoctors * 100).toStringAsFixed(1)}%'
                  : '0%',
              trendColor: AppColors.success,
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.success,
            ),
            _MetricCard(
              label: 'Expiring Soon',
              value: '$_expiringSoonCount',
              trend: 'Next 7 days',
              trendColor: AppColors.warning,
              icon: Icons.timer_outlined,
              iconColor: AppColors.warning,
            ),
            _MetricCard(
              label: 'Expired',
              value: '$_expiredCount',
              trend: 'Requires attention',
              trendColor: AppColors.error,
              icon: Icons.history_rounded,
              iconColor: AppColors.error,
            ),
            _MetricCard(
              label: 'Overdue',
              value: '$_overdueCount',
              trend: 'Payment overdue',
              trendColor: AppColors.error,
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.pink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      ('all', 'All'),
      ('active', 'Active'),
      ('expiring_soon', 'Expiring Soon'),
      ('expired', 'Expired'),
      ('overdue', 'Overdue'),
      ('suspended', 'Suspended'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f.$1;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFilter = f.$1);
              _applyFilter();
            },
            child: _TabButton(
              label: '${f.$2} (${_getFilterCount(f.$1)})',
              isSelected: isSelected,
              activeColor: AppColors.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLightOf(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.textTertiaryOf(context),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        _searchQuery = value;
                        _applyFilter();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search doctor by name, email or plan...',
                        hintStyle: TextStyle(
                          color: AppColors.textTertiaryOf(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _IconButton(icon: Icons.filter_list_rounded, label: 'Filter'),
          const SizedBox(width: 12),
          _IconButton(icon: Icons.swap_vert_rounded, label: 'Sort'),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          if (_subscriptions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.subscriptions_outlined,
                    size: 48,
                    color: AppColors.textTertiaryOf(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No subscriptions found',
                    style: TextStyle(
                      color: AppColors.textTertiaryOf(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._subscriptions.map((sub) {
              final profile = sub['profiles'] as Map<String, dynamic>?;
              final plan = sub['subscription_plans'] as Map<String, dynamic>?;
              final doctorName = profile?['full_name'] as String? ?? 'Unknown';
              final planName = plan?['name'] as String? ?? 'No Plan';
              final amount = sub['last_payment_amount'];
              final status = sub['status'] as String?;
              final expiryDate = sub['expiry_date'] as String?;
              final lastPayDate = sub['last_payment_date'] as String?;

              return _SubscriptionRow(
                name: doctorName,
                plan: planName,
                amount: _formatCurrency(amount),
                status: _statusLabel(status),
                expiry: _formatExpiry(expiryDate),
                lastPay: _formatCurrency(amount),
                payDate: lastPayDate != null
                    ? _formatExpiry(lastPayDate)
                          .replaceAll('Expires in ', '')
                          .replaceAll('Expired ', 'Paid ')
                    : 'N/A',
                initial: _getInitial(doctorName),
                avatarUrl: profile?['avatar_url'] as String?,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Doctor',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiaryOf(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Plan & Amount',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiaryOf(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status & Expiry',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiaryOf(context),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Last Payment',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiaryOf(context),
              ),
            ),
          ),
          Text(
            'Actions',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_subscriptions.length} Loaded',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              Text(
                'Select doctors to perform bulk actions',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          _BulkActionButton(
            icon: Icons.send_rounded,
            label: 'Send Reminder',
            color: AppColors.primary,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Select doctors to send reminders.'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _BulkActionButton(
            icon: Icons.calendar_today_rounded,
            label: 'Extend Subscription',
            color: AppColors.primary,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Select doctors to extend subscriptions.'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _BulkActionButton(
            icon: Icons.block_rounded,
            label: 'Suspend',
            color: AppColors.error,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select doctors to suspend.')),
              );
            },
          ),
          const SizedBox(width: 8),
          _BulkActionButton(
            icon: Icons.file_download_outlined,
            label: 'Export',
            color: AppColors.textTertiaryOf(context),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export is being prepared.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    final total = _allSubscriptions.length;
    final activeRatio = total > 0 ? _activeCount / total : 0.0;
    final expiringRatio = total > 0 ? _expiringSoonCount / total : 0.0;
    final expiredRatio = total > 0 ? _expiredCount / total : 0.0;
    final overdueRatio = total > 0 ? _overdueCount / total : 0.0;

    final expiringSoon = _getExpiringSoon();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLightOf(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscription Overview',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _CircularChart(
                        value: activeRatio > 0 ? activeRatio : 0,
                        label: '$total',
                        subLabel: 'Total',
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          children: [
                            _LegendItem(
                              label: 'Active',
                              value: '($_activeCount)',
                              percentage:
                                  '${(activeRatio * 100).toStringAsFixed(1)}%',
                              color: AppColors.primary,
                            ),
                            _LegendItem(
                              label: 'Expiring Soon',
                              value: '($_expiringSoonCount)',
                              percentage:
                                  '${(expiringRatio * 100).toStringAsFixed(1)}%',
                              color: AppColors.warning,
                            ),
                            _LegendItem(
                              label: 'Expired',
                              value: '($_expiredCount)',
                              percentage:
                                  '${(expiredRatio * 100).toStringAsFixed(1)}%',
                              color: AppColors.error,
                            ),
                            _LegendItem(
                              label: 'Overdue',
                              value: '($_overdueCount)',
                              percentage:
                                  '${(overdueRatio * 100).toStringAsFixed(1)}%',
                              color: AppColors.pink,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLightOf(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expiring Soon (Next 7 Days)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (expiringSoon.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No subscriptions expiring soon',
                        style: TextStyle(
                          color: AppColors.textTertiaryOf(context),
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    ...expiringSoon.map((sub) {
                      final profile = sub['profiles'] as Map<String, dynamic>?;
                      final doctorName =
                          profile?['full_name'] as String? ?? 'Unknown';
                      final expiry = _formatExpiry(
                        sub['expiry_date'] as String?,
                      );
                      return _SmallDoctorItem(
                        name: doctorName,
                        sub: expiry,
                        initial: _getInitial(doctorName),
                        avatarUrl: profile?['avatar_url'] as String?,
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowerGrids() {
    final total = _allSubscriptions.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                _SectionHeader('Status Breakdown'),
                const SizedBox(height: 16),
                _ProgressRow(
                  label: 'Active',
                  value: '$_activeCount',
                  percentage: total > 0
                      ? '${(_activeCount / total * 100).toStringAsFixed(1)}%'
                      : '0%',
                  color: AppColors.primary,
                ),
                _ProgressRow(
                  label: 'Expiring Soon',
                  value: '$_expiringSoonCount',
                  percentage: total > 0
                      ? '${(_expiringSoonCount / total * 100).toStringAsFixed(1)}%'
                      : '0%',
                  color: AppColors.warning,
                ),
                _ProgressRow(
                  label: 'Expired',
                  value: '$_expiredCount',
                  percentage: total > 0
                      ? '${(_expiredCount / total * 100).toStringAsFixed(1)}%'
                      : '0%',
                  color: AppColors.error,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _SectionHeader('Total Doctors'),
                const SizedBox(height: 16),
                _ProgressRow(
                  label: 'With Active Sub',
                  value: '$_activeCount',
                  percentage: '$_totalDoctors total',
                  color: AppColors.primary,
                ),
                _ProgressRow(
                  label: 'No Sub (Inactive)',
                  value: '${_totalDoctors - _allSubscriptions.length}',
                  percentage: _totalDoctors > 0
                      ? '${((_totalDoctors - _allSubscriptions.length) / _totalDoctors * 100).toStringAsFixed(1)}%'
                      : '0%',
                  color: AppColors.textTertiaryOf(context),
                ),
                _ProgressRow(
                  label: 'Overdue',
                  value: '$_overdueCount',
                  percentage: total > 0
                      ? '${(_overdueCount / total * 100).toStringAsFixed(1)}%'
                      : '0%',
                  color: AppColors.pink,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader('Quick Actions'),
                const SizedBox(height: 16),
                _QuickActionTile(
                  icon: Icons.warning_amber_rounded,
                  label: 'Overdue Payments',
                  color: AppColors.error,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Overdue payments list is under development.',
                        ),
                      ),
                    );
                  },
                ),
                _QuickActionTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Subscription Reports',
                  color: AppColors.primary,
                  onTap: () => context.push('/admin/reports'),
                ),
                _QuickActionTile(
                  icon: Icons.verified_user_rounded,
                  label: 'Payment Verification',
                  color: AppColors.success,
                  onTap: () => context.push('/admin/financial-moderation'),
                ),
                _QuickActionTile(
                  icon: Icons.notifications_active_rounded,
                  label: 'Notification Settings',
                  color: AppColors.pink,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Notification Settings'),
                        content: const Text(
                          'Configure subscription notifications.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final Color trendColor;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.trendColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const Spacer(),
              if (trend.isNotEmpty)
                Text(
                  trend,
                  style: TextStyle(
                    color: trendColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: AppColors.textTertiaryOf(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? activeColor.withValues(alpha: 0.1)
            : AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? activeColor : AppColors.borderLightOf(context),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? activeColor : AppColors.textTertiaryOf(context),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IconButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label coming soon'),
            backgroundColor: AppColors.primary,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLightOf(context)),
        ),
        child: Icon(icon, color: AppColors.textTertiaryOf(context), size: 20),
      ),
    );
  }
}

class _SubscriptionRow extends StatelessWidget {
  final String name;
  final String plan;
  final String amount;
  final String status;
  final String expiry;
  final String lastPay;
  final String payDate;
  final String initial;
  final String? avatarUrl;

  const _SubscriptionRow({
    required this.name,
    required this.plan,
    required this.amount,
    required this.status,
    required this.expiry,
    required this.lastPay,
    required this.payDate,
    required this.initial,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLightOf(context)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                AdminAvatar(imageUrl: avatarUrl, name: name, radius: 16),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      plan,
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textTertiaryOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textTertiaryOf(context),
                  ),
                ),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(label: status),
                const SizedBox(height: 4),
                Text(
                  expiry,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lastPay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                Text(
                  payDate,
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textTertiaryOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_vert_rounded,
            color: AppColors.textTertiaryOf(context),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (label.toLowerCase()) {
      case 'active':
        color = AppColors.success;
        break;
      case 'expiring soon':
        color = AppColors.warning;
        break;
      case 'expired':
        color = AppColors.error;
        break;
      case 'overdue':
        color = AppColors.pink;
        break;
      case 'suspended':
        color = AppColors.textTertiaryOf(context);
        break;
      default:
        color = AppColors.textTertiaryOf(context);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _BulkActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLightOf(context)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _CircularChart extends StatelessWidget {
  final double value;
  final String label;
  final String subLabel;
  final Color color;
  const _CircularChart({
    required this.value,
    required this.label,
    required this.subLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: CircularProgressIndicator(
            value: value > 0 ? value : 0,
            strokeWidth: 8,
            backgroundColor: AppColors.borderLightOf(context),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 8,
                color: AppColors.textTertiaryOf(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final String value;
  final String percentage;
  final Color color;
  const _LegendItem({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiaryOf(context),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiaryOf(context),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallDoctorItem extends StatelessWidget {
  final String name;
  final String sub;
  final String initial;
  final String? avatarUrl;
  const _SmallDoctorItem({
    required this.name,
    required this.sub,
    required this.initial,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AdminAvatar(imageUrl: avatarUrl, name: name, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(label: 'Remind'),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: AppColors.textTertiaryOf(context),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final String percentage;
  final Color color;
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final parsedValue = int.tryParse(value) ?? 0;
    final total = parsedValue > 0 ? parsedValue : 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiaryOf(context),
                ),
              ),
              Text(
                '$value ($percentage)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: parsedValue > 0 ? (parsedValue / total).clamp(0.0, 1.0) : 0,
            backgroundColor: AppColors.borderLightOf(context),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
