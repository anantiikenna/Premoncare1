import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import 'admin_avatar.dart';
import 'admin_scaffold.dart';

class P2PMonitoringPanel extends ConsumerStatefulWidget {
  const P2PMonitoringPanel({super.key});

  @override
  ConsumerState<P2PMonitoringPanel> createState() => _P2PMonitoringPanelState();
}

class _P2PMonitoringPanelState extends ConsumerState<P2PMonitoringPanel> {
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0;

  List<Map<String, dynamic>> _transactions = [];
  int _totalVolume = 0;
  int _completedCount = 0;
  int _pendingCount = 0;
  int _disputedCount = 0;
  int _flaggedCount = 0;

  int _highRiskCount = 0;
  int _mediumRiskCount = 0;
  int _lowRiskCount = 0;

  List<Map<String, dynamic>> _topUsers = [];

  static const _tabLabels = [
    'All Transactions',
    'Pending Review',
    'Disputes',
    'Resolved',
  ];

  static const _tabStatuses = <String?>[
    null,
    'pending',
    'disputed',
    'approved',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await Future.wait([
      _loadStats(),
      _loadTransactions(),
      _loadRiskOverview(),
      _loadTopUsers(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadStats() async {
    try {
      final payments = await supabase
          .from('payments')
          .select('amount, status')
          .eq('method', 'manual');

      int total = 0;
      int completed = 0;
      int pending = 0;
      int disputed = 0;
      int flagged = 0;

      for (final p in payments) {
        final amount = (p['amount'] as num?)?.toInt() ?? 0;
        final status = p['status'] as String? ?? '';
        total += amount;
        switch (status) {
          case 'approved':
            completed += amount;
            break;
          case 'pending':
            pending++;
            break;
          case 'disputed':
            disputed++;
            break;
          case 'rejected':
            flagged++;
            break;
        }
      }

      if (mounted) {
        setState(() {
          _totalVolume = total;
          _completedCount = completed;
          _pendingCount = pending;
          _disputedCount = disputed;
          _flaggedCount = flagged;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load stats: $e');
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final status = _tabStatuses[_selectedTab];
      var query = supabase
          .from('payments')
          .select('''
            id, amount, status, created_at, method, receipt_url,
            user_id, recipient_id
          ''')
          .eq('method', 'manual');

      if (status != null) {
        query = query.eq('status', status);
      }

      final data = await query.order('created_at', ascending: false).limit(20);

      final senderIds = <String>{};
      final recipientIds = <String>{};
      for (final t in data) {
        final s = t['user_id'] as String?;
        final r = t['recipient_id'] as String?;
        if (s != null) senderIds.add(s);
        if (r != null) recipientIds.add(r);
      }

      final allIds = {...senderIds, ...recipientIds};
      final profileMap = <String, Map<String, dynamic>>{};
      if (allIds.isNotEmpty) {
        final profiles = await supabase
            .from('profiles')
            .select('id, full_name, email, avatar_url')
            .inFilter('id', allIds.toList());
        for (final p in profiles) {
          profileMap[p['id'] as String] = p;
        }
      }

      final enriched = data.map((t) {
        final sender = profileMap[t['user_id']];
        final recipient = profileMap[t['recipient_id']];
        return {
          ...t,
          'sender_name': sender?['full_name'] ?? 'Unknown',
          'recipient_name': recipient?['full_name'] ?? 'Unknown',
          'sender_avatar': sender?['avatar_url'],
          'recipient_avatar': recipient?['avatar_url'],
        };
      }).toList();

      if (mounted) setState(() => _transactions = enriched);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to load transactions: $e');
      }
    }
  }

  Future<void> _loadRiskOverview() async {
    try {
      final disputes = await supabase
          .from('disputes')
          .select('id, risk_level, status');

      int high = 0;
      int medium = 0;
      int low = 0;

      for (final d in disputes) {
        final level = d['risk_level'] as String? ?? 'low';
        switch (level) {
          case 'high':
            high++;
            break;
          case 'medium':
            medium++;
            break;
          default:
            low++;
            break;
        }
      }

      if (mounted) {
        setState(() {
          _highRiskCount = high;
          _mediumRiskCount = medium;
          _lowRiskCount = low;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to load risk overview: $e');
      }
    }
  }

  Future<void> _loadTopUsers() async {
    try {
      final payments = await supabase
          .from('payments')
          .select('user_id, recipient_id, amount')
          .eq('method', 'manual')
          .eq('status', 'approved');

      final userVolume = <String, int>{};
      final userCount = <String, int>{};

      for (final p in payments) {
        final recipientId = p['recipient_id'] as String?;
        final amount = (p['amount'] as num?)?.toInt() ?? 0;
        if (recipientId != null) {
          userVolume[recipientId] = (userVolume[recipientId] ?? 0) + amount;
          userCount[recipientId] = (userCount[recipientId] ?? 0) + 1;
        }
      }

      final sortedIds = userVolume.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topIds = sortedIds.take(5).map((e) => e.key).toList();
      final profileMap = <String, Map<String, dynamic>>{};

      if (topIds.isNotEmpty) {
        final profiles = await supabase
            .from('profiles')
            .select('id, full_name, avatar_url')
            .inFilter('id', topIds);
        for (final p in profiles) {
          profileMap[p['id'] as String] = p;
        }
      }

      final topUsers = <Map<String, dynamic>>[];
      for (var i = 0; i < sortedIds.length && i < 5; i++) {
        final entry = sortedIds[i];
        final profile = profileMap[entry.key];
        topUsers.add({
          'name': profile?['full_name'] ?? 'Unknown',
          'avatar_url': profile?['avatar_url'],
          'volume': entry.value,
          'count': userCount[entry.key] ?? 0,
        });
      }

      if (mounted) setState(() => _topUsers = topUsers);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to load top users: $e');
      }
    }
  }

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '₦$buf';
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final mm = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]}, $h:$mm $ampm';
    } catch (_) {
      return isoDate;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
      case 'disputed':
        return AppColors.error;
      default:
        return AppColors.textTertiaryOf(context);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Completed';
      case 'pending':
        return 'Pending Review';
      case 'rejected':
        return 'Flagged';
      case 'disputed':
        return 'Dispute';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  String _initial(String name) => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 4,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null && _transactions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondaryOf(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            color: AppColors.textInverse,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildTopStats(),
                    const SizedBox(height: 32),
                    _buildFilterTabs(),
                    const SizedBox(height: 20),
                    _buildSearchAndFilters(),
                    const SizedBox(height: 32),
                    _buildRiskAndReasonsSection(),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      'Recent P2P Transactions',
                      onSeeAll: () {},
                    ),
                    const SizedBox(height: 16),
                    _buildRecentP2PTransactions(),
                    const SizedBox(height: 32),
                    _buildTopUsersSection(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Quick Actions'),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTopStats() {
    final totalCount =
        _pendingCount +
        _disputedCount +
        _flaggedCount +
        _transactions.where((t) => t['status'] == 'approved').length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _P2PStatCard(
          title: 'Total P2P Volume',
          value: _formatAmount(_totalVolume),
          trend: '$totalCount transactions',
          trendPositive: true,
          color: AppColors.primary,
          icon: Icons.groups_rounded,
        ),
        _P2PStatCard(
          title: 'Successful Transactions',
          value: _formatAmount(_completedCount),
          trend: 'approved',
          trendPositive: true,
          color: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
        ),
        _P2PStatCard(
          title: 'Pending Verifications',
          value: _pendingCount.toString(),
          trend: 'awaiting review',
          trendPositive: false,
          color: AppColors.warning,
          icon: Icons.pending_actions_rounded,
        ),
        _P2PStatCard(
          title: 'Disputes & Flagged',
          value: (_disputedCount + _flaggedCount).toString(),
          trend: '$_disputedCount disputes, $_flaggedCount flagged',
          trendPositive: false,
          color: AppColors.error,
          icon: Icons.warning_amber_rounded,
          isNegative: true,
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabLabels.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = i);
                _loadTransactions();
              },
              child: _TabItem(
                label: _tabLabels[i],
                count: i == 1
                    ? _pendingCount.toString()
                    : i == 2
                    ? _disputedCount.toString()
                    : null,
                isSelected: _selectedTab == i,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
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
                SizedBox(width: 12),
                Text(
                  'Search by transaction ID, sender, receiver...',
                  style: TextStyle(
                    color: AppColors.textTertiaryOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _FilterButton(),
        const SizedBox(width: 12),
        _DateRangePicker(),
      ],
    );
  }

  Widget _buildRiskAndReasonsSection() {
    final totalRisk = _highRiskCount + _mediumRiskCount + _lowRiskCount;
    final riskFraction = totalRisk > 0 ? _highRiskCount / totalRisk : 0.0;

    final highPct = totalRisk > 0
        ? ((_highRiskCount / totalRisk) * 100).toStringAsFixed(1)
        : '0.0';
    final medPct = totalRisk > 0
        ? ((_mediumRiskCount / totalRisk) * 100).toStringAsFixed(1)
        : '0.0';
    final lowPct = totalRisk > 0
        ? ((_lowRiskCount / totalRisk) * 100).toStringAsFixed(1)
        : '0.0';

    return Row(
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
              children: [
                const _CardHeader(title: 'Risk Overview'),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: CircularProgressIndicator(
                        value: riskFraction,
                        strokeWidth: 12,
                        backgroundColor: AppColors.borderLightOf(
                          context,
                        ).withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.error,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          _highRiskCount.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        Text(
                          'High Risk',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _RiskLegend(
                  label: 'High Risk',
                  count: _highRiskCount.toString(),
                  percentage: '$highPct%',
                  color: AppColors.error,
                ),
                _RiskLegend(
                  label: 'Medium Risk',
                  count: _mediumRiskCount.toString(),
                  percentage: '$medPct%',
                  color: AppColors.warning,
                ),
                _RiskLegend(
                  label: 'Low Risk',
                  count: _lowRiskCount.toString(),
                  percentage: '$lowPct%',
                  color: AppColors.success,
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
              children: [
                const _CardHeader(title: 'Dispute Breakdown'),
                const SizedBox(height: 24),
                _DisputeBreakdownItem(
                  icon: Icons.replay_circle_filled_rounded,
                  label: 'Pending Review',
                  count: _pendingCount.toString(),
                  color: AppColors.warning,
                ),
                _DisputeBreakdownItem(
                  icon: Icons.error_outline_rounded,
                  label: 'Disputed',
                  count: _disputedCount.toString(),
                  color: AppColors.error,
                ),
                _DisputeBreakdownItem(
                  icon: Icons.flag_rounded,
                  label: 'Flagged / Rejected',
                  count: _flaggedCount.toString(),
                  color: AppColors.textTertiaryOf(context),
                ),
                _DisputeBreakdownItem(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Approved',
                  count: _completedCount.toString(),
                  color: AppColors.success,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentP2PTransactions() {
    if (_transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLightOf(context)),
        ),
        child: Center(
          child: Text(
            'No P2P transactions found',
            style: TextStyle(
              color: AppColors.textTertiaryOf(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _transactions.map((t) {
        final senderName = t['sender_name'] as String? ?? 'Unknown';
        final recipientName = t['recipient_name'] as String? ?? 'Unknown';
        final amount = (t['amount'] as num?)?.toInt() ?? 0;
        final status = t['status'] as String? ?? 'unknown';
        final createdAt = t['created_at'] as String?;
        final id = t['id'] as String? ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _P2PTransactionItem(
            senderName: senderName,
            senderInitial: _initial(senderName),
            receiverName: recipientName,
            receiverInitial: _initial(recipientName),
            amount: _formatAmount(amount),
            date: _formatDate(createdAt),
            id: id.length >= 8 ? id.substring(0, 8) : id,
            status: _statusLabel(status),
            statusColor: _statusColor(status),
            senderAvatar: t['sender_avatar'] as String?,
            receiverAvatar: t['recipient_avatar'] as String?,
            receiptUrl: t['receipt_url'] as String?,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopUsersSection() {
    return Row(
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
              children: [
                const _CardHeader(title: 'Top P2P Users (By Volume)'),
                const SizedBox(height: 24),
                if (_topUsers.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No data yet',
                      style: TextStyle(
                        color: AppColors.textTertiaryOf(context),
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  ..._topUsers.asMap().entries.expand((entry) {
                    final i = entry.key;
                    final u = entry.value;
                    final name = u['name'] as String? ?? 'Unknown';
                    return [
                      _TopUserItem(
                        rank: i + 1,
                        name: name,
                        amount: _formatAmount(u['volume'] as int),
                        txnCount: '${u['count']} Transactions',
                        initial: _initial(name),
                        avatarUrl: u['avatar_url'] as String?,
                      ),
                      if (i < _topUsers.length - 1)
                        Divider(height: 32, color: AppColors.dividerOf(context)),
                    ];
                  }),
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
              children: [
                const _CardHeader(title: 'Suspicious Activity Monitor'),
                const SizedBox(height: 24),
                _MonitorItem(
                  icon: Icons.person_add_disabled_rounded,
                  label: 'Multiple accounts activity',
                  count: _flaggedCount.toString(),
                  color: AppColors.error,
                ),
                Divider(height: 32, color: AppColors.dividerOf(context)),
                _MonitorItem(
                  icon: Icons.compare_arrows_rounded,
                  label: 'Rapid in & out transfers',
                  count: _mediumRiskCount.toString(),
                  color: AppColors.warning,
                ),
                Divider(height: 32, color: AppColors.dividerOf(context)),
                _MonitorItem(
                  icon: Icons.money_off_rounded,
                  label: 'Unusual transaction amount',
                  count: _highRiskCount.toString(),
                  color: AppColors.info,
                ),
                Divider(height: 32, color: AppColors.dividerOf(context)),
                _MonitorItem(
                  icon: Icons.balance_rounded,
                  label: 'Open disputes',
                  count: _disputedCount.toString(),
                  color: AppColors.primary,
                ),
                Divider(height: 32, color: AppColors.dividerOf(context)),
                _MonitorItem(
                  icon: Icons.pending_actions_rounded,
                  label: 'Awaiting verification',
                  count: _pendingCount.toString(),
                  color: AppColors.success,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.8,
      children: [
        _QuickAction(
          icon: Icons.remove_red_eye_outlined,
          label: 'Review Queue',
          color: AppColors.primary,
          onTap: () => context.go('/admin/reports'),
        ),
        _QuickAction(
          icon: Icons.balance_rounded,
          label: 'Resolve Disputes',
          color: AppColors.error,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Navigate to Disputes from the sidebar menu.'),
              ),
            );
          },
        ),
        _QuickAction(
          icon: Icons.person_off_outlined,
          label: 'Block User',
          color: AppColors.warning,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Select a user first to block them.'),
              ),
            );
          },
        ),
        _QuickAction(
          icon: Icons.bar_chart_rounded,
          label: 'Transaction Report',
          color: AppColors.info,
          onTap: () => context.go('/admin/reports'),
        ),
        _QuickAction(
          icon: Icons.security_rounded,
          label: 'Risk Settings',
          color: AppColors.success,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Risk settings panel is under development.'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimaryOf(context),
            letterSpacing: -0.5,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              'View All',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Private sub-widgets ─────

class _P2PStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool trendPositive;
  final Color color;
  final IconData icon;
  final bool isNegative;

  const _P2PStatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendPositive,
    required this.color,
    required this.icon,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiaryOf(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            trend,
            style: TextStyle(
              color: isNegative ? AppColors.error : AppColors.textSecondaryOf(context),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final String? count;
  final bool isSelected;
  const _TabItem({required this.label, this.count, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.infoLightOf(context) : AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.borderLightOf(context),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondaryOf(context),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count!,
                style: const TextStyle(
                  color: AppColors.textInverse,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune_rounded,
            color: AppColors.textSecondaryOf(context),
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'Filter',
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final start = now.subtract(const Duration(days: 7));
    final dateLabel =
        '${months[start.month - 1]} ${start.day} - ${months[now.month - 1]} ${now.day}, ${now.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: AppColors.textSecondaryOf(context),
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            dateLabel,
            style: TextStyle(
              color: AppColors.textPrimaryOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textTertiaryOf(context),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  const _CardHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }
}

class _RiskLegend extends StatelessWidget {
  final String label;
  final String count;
  final String percentage;
  final Color color;

  const _RiskLegend({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($percentage)',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textTertiaryOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisputeBreakdownItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;

  const _DisputeBreakdownItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _P2PTransactionItem extends StatelessWidget {
  final String senderName;
  final String senderInitial;
  final String receiverName;
  final String receiverInitial;
  final String amount;
  final String date;
  final String id;
  final String status;
  final Color statusColor;
  final String? senderAvatar;
  final String? receiverAvatar;
  final String? receiptUrl;

  const _P2PTransactionItem({
    required this.senderName,
    required this.senderInitial,
    required this.receiverName,
    required this.receiverInitial,
    required this.amount,
    required this.date,
    required this.id,
    required this.status,
    required this.statusColor,
    this.senderAvatar,
    this.receiverAvatar,
    this.receiptUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Row(
        children: [
          _UserStack(
            initial: senderInitial,
            label: 'Sender',
            name: senderName,
            avatarUrl: senderAvatar,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textTertiaryOf(context),
              size: 18,
            ),
          ),
          _UserStack(
            initial: receiverInitial,
            label: 'Receiver',
            name: receiverName,
            avatarUrl: receiverAvatar,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              Text(
                '$date • $id',
                style: TextStyle(
                  color: AppColors.textTertiaryOf(context),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          if (receiptUrl != null && receiptUrl!.isNotEmpty)
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.black,
                  insetPadding: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      Center(
                        child: InteractiveViewer(
                          child: Image.network(
                            receiptUrl!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLightOf(context)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  receiptUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.receipt_rounded,
                    color: AppColors.textTertiaryOf(context),
                    size: 20,
                  ),
                ),
              ),
            ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiaryOf(context),
          ),
        ],
      ),
    );
  }
}

class _UserStack extends StatelessWidget {
  final String initial;
  final String label;
  final String name;
  final String? avatarUrl;
  const _UserStack({
    required this.initial,
    required this.label,
    required this.name,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AdminAvatar(imageUrl: avatarUrl, name: name, radius: 18),
        const SizedBox(width: 10),
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
              label,
              style: TextStyle(
                color: AppColors.textTertiaryOf(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopUserItem extends StatelessWidget {
  final int rank;
  final String name;
  final String amount;
  final String txnCount;
  final String initial;
  final String? avatarUrl;

  const _TopUserItem({
    required this.rank,
    required this.name,
    required this.amount,
    required this.txnCount,
    required this.initial,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.borderLightOf(context),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              rank.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        AdminAvatar(imageUrl: avatarUrl, name: name, radius: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
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
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            Text(
              txnCount,
              style: TextStyle(
                color: AppColors.textTertiaryOf(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonitorItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;

  const _MonitorItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryOf(context),
              ),
          ),
        ),
        Text(
          count,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textTertiaryOf(context),
          size: 18,
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
