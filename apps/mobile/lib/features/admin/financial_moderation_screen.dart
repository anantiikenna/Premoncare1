import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_scaffold.dart';

class FinancialModerationScreen extends ConsumerWidget {
  const FinancialModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFF0F62FE);

    return AdminScaffold(
      selectedIndex: 4,
      body: SingleChildScrollView(
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
            _buildFinancialAlerts(primaryColor),
            const SizedBox(height: 32),
            _buildSectionHeader('Recent Transactions', onSeeAll: () {}),
            const SizedBox(height: 16),
            _buildTransactionsList(),
            const SizedBox(height: 32),
            _buildRevenueAnalysis(primaryColor),
            const SizedBox(height: 32),
            _buildDisputesAndPayouts(),
            const SizedBox(height: 32),
            _buildSectionHeader('Quick Actions'),
            const SizedBox(height: 16),
            _buildQuickActions(context, primaryColor),
            const SizedBox(height: 40),
          ],
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
      children: const [
        _FinanceStatCard(
          title: 'Total Revenue (This Month)',
          value: '₦28,540,600',
          trend: '+ 18.7%',
          trendPositive: true,
          icon: Icons.medical_services_outlined,
          color: Color(0xFF10B981),
        ),
        _FinanceStatCard(
          title: 'Total Payouts (This Month)',
          value: '₦16,320,450',
          trend: '+ 12.4%',
          trendPositive: true,
          icon: Icons.account_balance_wallet_outlined,
          color: Color(0xFF3B82F6),
        ),
        _FinanceStatCard(
          title: 'Pending Payouts',
          value: '₦3,245,000',
          trend: '32 transactions',
          trendPositive: true,
          icon: Icons.hourglass_empty_rounded,
          color: Color(0xFFF59E0B),
          isTransactionCount: true,
        ),
        _FinanceStatCard(
          title: 'Refunds (This Month)',
          value: '₦950,300',
          trend: '- 8.6%',
          trendPositive: false,
          icon: Icons.replay_rounded,
          color: Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabItem(label: 'All Transactions', isSelected: true),
          const SizedBox(width: 12),
          _TabItem(label: 'Payouts', isSelected: false),
          const SizedBox(width: 12),
          _TabItem(label: 'Refunds', isSelected: false),
          const SizedBox(width: 12),
          _TabItem(label: 'Disputes', isSelected: false),
        ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Search by name, transaction ID, or reference...',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFF64748B),
                size: 18,
              ),
              SizedBox(width: 12),
              Text(
                'Jun 8 - Jun 14, 2025',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialAlerts(Color primaryColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AlertCard(
            count: '3',
            title: 'Payment Disputes',
            sub: 'Require attention',
            btnLabel: 'Review Now',
            color: const Color(0xFFF59E0B),
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(width: 16),
          _AlertCard(
            count: '7',
            title: 'Failed Payouts',
            sub: 'Need resolution',
            btnLabel: 'View Now',
            color: const Color(0xFFEF4444),
            icon: Icons.error_outline_rounded,
          ),
          const SizedBox(width: 16),
          _AlertCard(
            count: '12',
            title: 'Refund Requests',
            sub: 'Pending review',
            btnLabel: 'View Now',
            color: const Color(0xFF3B82F6),
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Column(
      children: [
        _TransactionItem(
          name: 'Dr. Femi Adebayo',
          type: 'Consultation Payout',
          id: 'TXN-784512',
          date: '14 Jun, 10:30 AM',
          amount: '₦45,000',
          status: 'Completed',
          statusColor: const Color(0xFF10B981),
          initial: 'F',
        ),
        const SizedBox(height: 12),
        _TransactionItem(
          name: 'Mary Johnson',
          type: 'Consultation Payment',
          id: 'TXN-784511',
          date: '14 Jun, 09:15 AM',
          amount: '₦15,000',
          status: 'Completed',
          statusColor: const Color(0xFF10B981),
          initial: 'M',
        ),
        const SizedBox(height: 12),
        _TransactionItem(
          name: 'Ibrahim Umar',
          type: 'Consultation Payout',
          id: 'TXN-784510',
          date: '14 Jun, 08:45 AM',
          amount: '₦32,000',
          status: 'Pending',
          statusColor: const Color(0xFFF59E0B),
          initial: 'I',
        ),
        const SizedBox(height: 12),
        _TransactionItem(
          name: 'Adaora Nwosu',
          type: 'Refund to Patient',
          id: 'TXN-784509',
          date: '13 Jun, 04:20 PM',
          amount: '- ₦12,000',
          amountColor: const Color(0xFFEF4444),
          status: 'Refunded',
          statusColor: const Color(0xFFEF4444),
          initial: 'A',
        ),
        const SizedBox(height: 12),
        _TransactionItem(
          name: 'John Michael',
          type: 'Subscription Payment',
          id: 'TXN-784508',
          date: '13 Jun, 03:10 PM',
          amount: '₦25,000',
          status: 'Completed',
          statusColor: const Color(0xFF10B981),
          initial: 'J',
        ),
      ],
    );
  }

  Widget _buildRevenueAnalysis(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnalyticsHeader('Revenue Overview'),
                const SizedBox(height: 16),
                const Text(
                  '₦28,540,600',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Row(
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: Color(0xFF10B981),
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '18.7%',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'vs last week',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 120,
                  child: CustomPaint(painter: _LineChartPainter(primaryColor)),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jun 8',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      'Jun 9',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      'Jun 10',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      'Jun 11',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      'Jun 12',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      'Jun 13',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      'Jun 14',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
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
                        value: 0.7,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    const Column(
                      children: [
                        Text(
                          '₦28.5M',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _BreakdownItem(
                  label: 'Consultations',
                  value: '₦18.2M',
                  percentage: '63.8%',
                  color: primaryColor,
                ),
                _BreakdownItem(
                  label: 'Subscriptions',
                  value: '₦6.4M',
                  percentage: '22.4%',
                  color: const Color(0xFF10B981),
                ),
                _BreakdownItem(
                  label: 'Time Credit Sales',
                  value: '₦2.8M',
                  percentage: '9.8%',
                  color: const Color(0xFF8B5CF6),
                ),
                _BreakdownItem(
                  label: 'Other',
                  value: '₦1.1M',
                  percentage: '4.0%',
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
            color: Color(0xFF1E293B),
          ),
        ),
        Row(
          children: [
            const Text(
              'This Week',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: const Color(0xFF64748B).withValues(alpha: 0.5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisputesAndPayouts() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildListHeader('Recent Disputes'),
                const SizedBox(height: 20),
                _DisputeItem(
                  name: 'Mary Johnson',
                  sub: 'Payment not received',
                  id: 'DISP-2456',
                  time: '14 Jun, 11:30 AM',
                  status: 'Open',
                  color: const Color(0xFFF59E0B),
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DisputeItem(
                  name: 'Emeka Patrick',
                  sub: 'Consultation issue',
                  id: 'DISP-2455',
                  time: '13 Jun, 03:45 PM',
                  status: 'Open',
                  color: const Color(0xFFF59E0B),
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                _DisputeItem(
                  name: 'Chinedu Okeke',
                  sub: 'Incorrect charge',
                  id: 'DISP-2454',
                  time: '12 Jun, 02:10 PM',
                  status: 'Resolved',
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildListHeader('Upcoming Payouts'),
                const SizedBox(height: 20),
                const _PayoutItem(
                  name: 'Dr. Femi Adebayo',
                  txnCount: '2 Transactions',
                  date: 'Due: 15 Jun, 2025',
                  amount: '₦95,000',
                  initial: 'F',
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                const _PayoutItem(
                  name: 'Dr. Adaora Nwosu',
                  txnCount: '3 Transactions',
                  date: 'Due: 15 Jun, 2025',
                  amount: '₦68,000',
                  initial: 'A',
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                const _PayoutItem(
                  name: 'Dr. Ibrahim Umar',
                  txnCount: '2 Transactions',
                  date: 'Due: 15 Jun, 2025',
                  amount: '₦45,000',
                  initial: 'I',
                ),
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
            color: Color(0xFF1E293B),
          ),
        ),
        const Text(
          'View All',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F62FE),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, Color primaryColor) {
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
          color: const Color(0xFF10B981),
          onTap: () => _showApprovePayoutsDialog(context),
        ),
        _QuickAction(
          icon: Icons.replay_rounded,
          label: 'Review Refunds',
          color: const Color(0xFFEF4444),
        ),
        _QuickAction(
          icon: Icons.warning_amber_rounded,
          label: 'Resolve Disputes',
          color: const Color(0xFFF59E0B),
        ),
        _QuickAction(
          icon: Icons.bar_chart_rounded,
          label: 'Transaction Reports',
          color: primaryColor,
        ),
        _QuickAction(
          icon: Icons.settings_outlined,
          label: 'Payout Settings',
          color: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  void _showApprovePayoutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 12),
            Text('Approve Payouts?', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to approve all pending payouts? This action will process ₦3,245,000 across 32 transactions.',
          style: TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 13),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payouts approved successfully!'), backgroundColor: Color(0xFF10B981)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Approve All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              'View All',
              style: TextStyle(
                color: Color(0xFF0F62FE),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }


}

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
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
                  color: trendPositive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  size: 12,
                ),
              if (!isTransactionCount) const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  color: isTransactionCount
                      ? const Color(0xFF64748B)
                      : (trendPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444)),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              if (!isTransactionCount)
                const Text(
                  'vs last month',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
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
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF0F62FE) : const Color(0xFF64748B),
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
          SnackBar(content: Text('$label is being developed. Financial moderation features are rolling out gradually.')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
                      color: Color(0xFF1E293B),
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
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$btnLabel is being developed. Financial moderation features are rolling out gradually.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
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
    this.amountColor = const Color(0xFF1E293B),
    required this.status,
    required this.statusColor,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.12),
            child: Text(initial, style: const TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 16)),
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
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
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
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
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
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
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
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '($percentage)',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
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
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
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
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$id • $time',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
          child: Text(initial, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
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
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                txnCount,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
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
            color: Color(0xFF1E293B),
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
      size.width * 0.15,
      size.height * 0.7,
      size.width * 0.25,
      size.height * 0.75,
    );
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.85,
      size.width * 0.5,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.3,
      size.width * 0.8,
      size.height * 0.35,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.2,
      size.width,
      size.height * 0.1,
    );

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotPaintInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (double i = 0; i <= 1; i += 0.2) {
      // simplified dots
    }

    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), 4, dotPaint);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.4),
      2,
      dotPaintInner,
    );
    canvas.drawCircle(Offset(size.width, size.height * 0.1), 4, dotPaint);
    canvas.drawCircle(Offset(size.width, size.height * 0.1), 2, dotPaintInner);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
