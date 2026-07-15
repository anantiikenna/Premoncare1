import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import 'admin_scaffold.dart';

class FinancialModerationScreen extends ConsumerStatefulWidget {
  const FinancialModerationScreen({super.key});

  @override
  ConsumerState<FinancialModerationScreen> createState() =>
      _FinancialModerationScreenState();
}

class _FinancialModerationScreenState
    extends ConsumerState<FinancialModerationScreen> {
  int _selectedTab = 0;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _disputes = [];
  int _totalRevenue = 0;
  int _totalPayouts = 0;
  int _pendingPayouts = 0;
  int _pendingPayoutCount = 0;
  int _refunds = 0;
  int _disputedCount = 0;
  int _refundRequestCount = 0;

  static const _tabLabels = [
    'All Transactions',
    'Pending',
    'Approved',
    'Refunded',
    'Disputed',
  ];

  static const _tabStatuses = <String?>[
    null,
    'pending',
    'approved',
    'refunded',
    'disputed',
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
    await Future.wait([_loadStats(), _loadTransactions(), _loadDisputes()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadStats() async {
    try {
      final payments = await supabase.from('payments').select('amount, status');

      int revenue = 0;
      int payouts = 0;
      int pending = 0;
      int pendingCount = 0;
      int refunds = 0;
      int refundCount = 0;

      for (final p in payments) {
        final amount = (p['amount'] as num?)?.toInt() ?? 0;
        final status = p['status'] as String? ?? '';
        switch (status) {
          case 'approved':
            revenue += amount;
            payouts += amount;
            break;
          case 'pending':
            pending += amount;
            pendingCount++;
            break;
          case 'refunded':
            refunds += amount;
            refundCount++;
            break;
        }
      }

      final disputes =
          await supabase.from('disputes').select('id, status');
      final openDisputes = disputes
          .where((d) =>
              (d['status'] == 'open') || (d['status'] == 'in_review'))
          .length;

      if (mounted) {
        setState(() {
          _totalRevenue = revenue;
          _totalPayouts = payouts;
          _pendingPayouts = pending;
          _pendingPayoutCount = pendingCount;
          _refunds = refunds;
          _disputedCount = openDisputes;
          _refundRequestCount = refundCount;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to load stats: $e');
      }
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final status = _tabStatuses[_selectedTab];
      var query = supabase.from('payments').select('''
            id, amount, status, created_at, method, receipt_url,
            user_id, recipient_id
          ''');

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
            .select('id, full_name, email, role')
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
        };
      }).toList();

      if (mounted) setState(() => _transactions = enriched);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to load transactions: $e');
      }
    }
  }

  Future<void> _loadDisputes() async {
    try {
      final data = await supabase
          .from('disputes')
          .select('''
            id, transaction_id, title, description, status,
            risk_level, category, amount, created_at,
            user_id, patient_id, doctor_id
          ''')
          .order('created_at', ascending: false)
          .limit(10);

      final userIds = <String>{};
      for (final d in data) {
        final uid = d['user_id'] as String?;
        if (uid != null) userIds.add(uid);
      }

      final profileMap = <String, String>{};
      if (userIds.isNotEmpty) {
        final profiles = await supabase
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', userIds.toList());
        for (final p in profiles) {
          profileMap[p['id'] as String] = p['full_name'] ?? 'Unknown';
        }
      }

      final enriched = data.map((d) {
        return {
          ...d,
          'user_name': profileMap[d['user_id']] ?? 'Unknown',
        };
      }).toList();

      if (mounted) setState(() => _disputes = enriched);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to load disputes: $e');
      }
    }
  }

  String _formatAmount(num amount) {
    final s = amount.toInt().toString();
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
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
      case 'refunded':
      case 'rejected':
        return AppColors.error;
      case 'disputed':
        return AppColors.warning;
      case 'open':
        return AppColors.warning;
      case 'in_review':
        return AppColors.info;
      case 'resolved':
      case 'closed':
        return AppColors.success;
      default:
        return AppColors.slate400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 4,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null && _transactions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
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
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Retry',
                                style: TextStyle(
                                    color: AppColors.textInverse,
                                    fontWeight: FontWeight.bold)),
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
                        _buildFinancialStats(),
                        const SizedBox(height: 32),
                        _buildFilterTabs(),
                        const SizedBox(height: 20),
                        _buildSearchAndFilters(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Financial Alerts', onSeeAll: () {}),
                        const SizedBox(height: 16),
                        _buildFinancialAlerts(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Recent Transactions', onSeeAll: () {}),
                        const SizedBox(height: 16),
                        _buildTransactionsList(),
                        const SizedBox(height: 32),
                        _buildRevenueAnalysis(),
                        const SizedBox(height: 32),
                        _buildDisputesAndPayouts(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Quick Actions'),
                        const SizedBox(height: 16),
                        _buildQuickActions(context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildFinancialStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _FinanceStatCard(
          title: 'Total Revenue',
          value: _formatAmount(_totalRevenue),
          trend: '${_transactions.length} txns',
          trendPositive: true,
          icon: Icons.medical_services_outlined,
          color: AppColors.success,
        ),
        _FinanceStatCard(
          title: 'Total Payouts',
          value: _formatAmount(_totalPayouts),
          trend: '${_transactions.where((t) => t['status'] == 'approved').length} txns',
          trendPositive: true,
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.primary,
        ),
        _FinanceStatCard(
          title: 'Pending Payouts',
          value: _formatAmount(_pendingPayouts),
          trend: '$_pendingPayoutCount transactions',
          trendPositive: true,
          icon: Icons.hourglass_empty_rounded,
          color: AppColors.warning,
          isTransactionCount: true,
        ),
        _FinanceStatCard(
          title: 'Refunds',
          value: _formatAmount(_refunds),
          trend: '$_refundRequestCount requests',
          trendPositive: false,
          icon: Icons.replay_rounded,
          color: AppColors.error,
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
                isSelected: _selectedTab == i,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLightOf(context)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: AppColors.textTertiary, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Search by name, transaction ID...',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _IconButton(icon: Icons.filter_list_rounded, label: 'Filter'),
            const SizedBox(width: 12),
            _IconButton(icon: Icons.file_download_outlined, label: 'Export'),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialAlerts() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AlertCard(
            count: '$_disputedCount',
            title: 'Payment Disputes',
            sub: 'Require attention',
            btnLabel: 'Review Now',
            color: AppColors.warning,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(width: 16),
          _AlertCard(
            count: '$_pendingPayoutCount',
            title: 'Pending Payouts',
            sub: 'Awaiting approval',
            btnLabel: 'View Now',
            color: AppColors.error,
            icon: Icons.error_outline_rounded,
          ),
          const SizedBox(width: 16),
          _AlertCard(
            count: '$_refundRequestCount',
            title: 'Refund Requests',
            sub: 'Pending review',
            btnLabel: 'View Now',
            color: AppColors.primary,
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLightOf(context)),
        ),
        child: const Center(
          child: Text(
            'No transactions found',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _transactions.map((t) {
        final amount = (t['amount'] as num?)?.toInt() ?? 0;
        final status = t['status'] as String? ?? 'unknown';
        final isRefund = status == 'refunded';
        final name = isRefund
            ? (t['sender_name'] as String? ?? 'Unknown')
            : (t['recipient_name'] as String? ?? 'Unknown');
        final initial =
            name.isNotEmpty ? name[0].toUpperCase() : '?';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TransactionItem(
            name: name,
            type: _transactionType(status, t['method'] as String?),
            id: (t['id'] as String? ?? '').substring(0, 8),
            date: _formatDate(t['created_at'] as String?),
            amount: '${isRefund ? "- " : ""}${_formatAmount(amount)}',
            amountColor: isRefund ? AppColors.error : AppColors.textPrimary,
            status: _capitalizeStatus(status),
            statusColor: _statusColor(status),
            initial: initial,
          ),
        );
      }).toList(),
    );
  }

  String _transactionType(String status, String? method) {
    switch (status) {
      case 'refunded':
        return 'Refund';
      case 'pending':
        return 'Awaiting Approval';
      case 'disputed':
        return 'Disputed Payment';
      default:
        return method != null
            ? '${_capitalizeStatus(method)} Payment'
            : 'Consultation Payment';
    }
  }

  String _capitalizeStatus(String s) =>
      s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');

  Widget _buildRevenueAnalysis() {
    final total = _totalRevenue > 0 ? _totalRevenue : 1;

    final approved = _transactions
        .where((t) => t['status'] == 'approved')
        .fold<int>(0, (sum, t) => sum + ((t['amount'] as num?)?.toInt() ?? 0));
    final pending = _transactions
        .where((t) => t['status'] == 'pending')
        .fold<int>(0, (sum, t) => sum + ((t['amount'] as num?)?.toInt() ?? 0));
    final other = total - approved - pending;
    final otherPositive = other > 0 ? other : 0;

    final approvedPct =
        total > 0 ? ((approved / total) * 100).toStringAsFixed(1) : '0.0';
    final pendingPct =
        total > 0 ? ((pending / total) * 100).toStringAsFixed(1) : '0.0';
    final otherPct =
        total > 0 ? ((otherPositive / total) * 100).toStringAsFixed(1) : '0.0';

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLightOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnalyticsHeader('Revenue Overview'),
                const SizedBox(height: 16),
                Text(
                  _formatAmount(_totalRevenue),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: CustomPaint(
                      painter: _LineChartPainter(AppColors.primary)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _weekLabels(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLightOf(context)),
            ),
            child: Column(
              children: [
                _buildAnalyticsHeader('Revenue Breakdown'),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(
                        value: approved / (total > 0 ? total : 1),
                        strokeWidth: 10,
                        backgroundColor:
                            AppColors.borderLightOf(context),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          _formatAmount(_totalRevenue),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _BreakdownItem(
                  label: 'Approved',
                  value: _formatAmount(approved),
                  percentage: '$approvedPct%',
                  color: AppColors.primary,
                ),
                _BreakdownItem(
                  label: 'Pending',
                  value: _formatAmount(pending),
                  percentage: '$pendingPct%',
                  color: AppColors.warning,
                ),
                _BreakdownItem(
                  label: 'Other',
                  value: _formatAmount(otherPositive),
                  percentage: '$otherPct%',
                  color: AppColors.slate500,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _weekLabels() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return Text(
        '${months[d.month - 1]} ${d.day}',
        style: const TextStyle(
            fontSize: 10, color: AppColors.textTertiary),
      );
    });
  }

  Widget _buildAnalyticsHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Row(
          children: [
            const Text(
              'This Week',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisputesAndPayouts() {
    final pendingPayments = _transactions
        .where((t) => t['status'] == 'pending')
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLightOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildListHeader('Recent Disputes'),
                const SizedBox(height: 20),
                if (_disputes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No disputes found',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  ..._disputes.take(3).expand((d) => [
                        _DisputeItem(
                          name: d['user_name'] as String? ?? 'Unknown',
                          sub: d['title'] as String? ??
                              d['description'] as String? ??
                              'No description',
                          id: (d['id'] as String? ?? '').substring(0, 8),
                          time: _formatDate(d['created_at'] as String?),
                          status: _capitalizeStatus(
                              d['status'] as String? ?? 'open'),
                          color: _statusColor(d['status'] as String? ?? 'open'),
                        ),
                        if (d != _disputes.last)
                          const Divider(
                              height: 24, color: AppColors.divider),
                      ]),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLightOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildListHeader('Pending Payouts'),
                const SizedBox(height: 20),
                if (pendingPayments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No pending payouts',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  ...pendingPayments.take(3).expand((p) {
                    final amount = (p['amount'] as num?)?.toInt() ?? 0;
                    final name =
                        p['recipient_name'] as String? ?? 'Unknown';
                    final initial =
                        name.isNotEmpty ? name[0].toUpperCase() : '?';
                    return [
                      _PayoutItem(
                        name: name,
                        txnCount: p['method'] as String? ?? 'Payment',
                        date: _formatDate(p['created_at'] as String?),
                        amount: _formatAmount(amount),
                        initial: initial,
                      ),
                      if (p != pendingPayments.last)
                        const Divider(
                            height: 24, color: AppColors.divider),
                    ];
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const Text(
          'View All',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.8,
      children: [
        _QuickAction(
          icon: Icons.check_circle_outline_rounded,
          label: 'Approve Payouts',
          color: AppColors.success,
          onTap: () => _showApprovePayoutsDialog(context),
        ),
        _QuickAction(
          icon: Icons.replay_rounded,
          label: 'Review Refunds',
          color: AppColors.error,
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Review Refunds'),
                content: const Text('Refund review is under development.'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
              ),
            );
          },
        ),
        _QuickAction(
          icon: Icons.warning_amber_rounded,
          label: 'Resolve Disputes',
          color: AppColors.warning,
          onTap: () => context.push('/admin/disputes'),
        ),
        _QuickAction(
          icon: Icons.bar_chart_rounded,
          label: 'Transaction Reports',
          color: AppColors.primary,
          onTap: () => context.push('/admin/reports'),
        ),
        _QuickAction(
          icon: Icons.settings_outlined,
          label: 'Payout Settings',
          color: AppColors.info,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payout settings are under development.')),
            );
          },
        ),
      ],
    );
  }

  void _showApprovePayoutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            SizedBox(width: 12),
            Text('Approve Payouts?',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to approve all pending payouts? This will process ${_formatAmount(_pendingPayouts)} across $_pendingPayoutCount transactions.',
          style: const TextStyle(
              color: AppColors.textSecondary, height: 1.5, fontSize: 13),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await supabase
                    .from('payments')
                    .update({'status': 'approved'})
                    .eq('status', 'pending');
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Payouts approved successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Approve All',
                style: TextStyle(
                    color: AppColors.textInverse, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
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

class _FinanceStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool trendPositive;
  final IconData icon;
  final Color color;
  final bool isTransactionCount;

  const _FinanceStatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendPositive,
    required this.icon,
    required this.color,
    this.isTransactionCount = false,
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (!isTransactionCount)
                Icon(
                  trendPositive
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color:
                      trendPositive ? AppColors.success : AppColors.error,
                  size: 12,
                ),
              if (!isTransactionCount) const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  color: isTransactionCount
                      ? AppColors.textSecondary
                      : (trendPositive
                          ? AppColors.success
                          : AppColors.error),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              if (!isTransactionCount)
                const Text(
                  'vs last month',
                  style: TextStyle(
                    color: AppColors.slate300,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _TabItem({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.infoLight : AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.borderLightOf(context),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
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
          SnackBar(content: Text('$label is being developed.')),
        );
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLightOf(context)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String count;
  final String title;
  final String sub;
  final String btnLabel;
  final Color color;
  final IconData icon;

  const _AlertCard({
    required this.count,
    required this.title,
    required this.sub,
    required this.btnLabel,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$btnLabel coming soon.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceOf(context),
                foregroundColor: color,
                elevation: 0,
                side: BorderSide(color: color.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                btnLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String name;
  final String type;
  final String id;
  final String date;
  final String amount;
  final Color amountColor;
  final String status;
  final Color statusColor;
  final String initial;

  const _TransactionItem({
    required this.name,
    required this.type,
    required this.id,
    required this.date,
    required this.amount,
    this.amountColor = AppColors.textPrimary,
    required this.status,
    required this.statusColor,
    required this.initial,
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
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(initial,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    color: AppColors.slate300,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
                  fontSize: 15,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.slate300),
        ],
      ),
    );
  }
}

class _BreakdownItem extends StatelessWidget {
  final String label;
  final String value;
  final String percentage;
  final Color color;

  const _BreakdownItem({
    required this.label,
    required this.value,
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '($percentage)',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DisputeItem extends StatelessWidget {
  final String name;
  final String sub;
  final String id;
  final String time;
  final String status;
  final Color color;

  const _DisputeItem({
    required this.name,
    required this.sub,
    required this.id,
    required this.time,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$id \u2022 $time',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PayoutItem extends StatelessWidget {
  final String name;
  final String txnCount;
  final String date;
  final String amount;
  final String initial;

  const _PayoutItem({
    required this.name,
    required this.txnCount,
    required this.date,
    required this.amount,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.success.withValues(alpha: 0.15),
          child: Text(initial,
              style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                txnCount,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
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

class _LineChartPainter extends CustomPainter {
  final Color color;
  _LineChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
        size.width * 0.15, size.height * 0.7, size.width * 0.25, size.height * 0.75);
    path.quadraticBezierTo(
        size.width * 0.4, size.height * 0.85, size.width * 0.5, size.height * 0.4);
    path.quadraticBezierTo(
        size.width * 0.65, size.height * 0.3, size.width * 0.8, size.height * 0.35);
    path.quadraticBezierTo(
        size.width * 0.9, size.height * 0.2, size.width, size.height * 0.1);

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotPaintInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), 2, dotPaintInner);
    canvas.drawCircle(Offset(size.width, size.height * 0.1), 4, dotPaint);
    canvas.drawCircle(Offset(size.width, size.height * 0.1), 2, dotPaintInner);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
