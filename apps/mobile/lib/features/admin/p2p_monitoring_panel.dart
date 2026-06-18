import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_scaffold.dart';

class P2PMonitoringPanel extends ConsumerWidget {
  const P2PMonitoringPanel({super.key});

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
            _buildTopStats(),
            const SizedBox(height: 32),
            _buildFilterTabs(),
            const SizedBox(height: 20),
            _buildSearchAndFilters(),
            const SizedBox(height: 32),
            _buildRiskAndReasonsSection(primaryColor),
            const SizedBox(height: 32),
            _buildSectionHeader('Recent P2P Transactions', onSeeAll: () {}),
            const SizedBox(height: 16),
            _buildRecentP2PTransactions(),
            const SizedBox(height: 32),
            _buildUsersAndMonitorSection(primaryColor),
            const SizedBox(height: 32),
            _buildSectionHeader('Quick Actions'),
            const SizedBox(height: 16),
            _buildQuickActions(primaryColor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }



  Widget _buildTopStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: const [
        _P2PStatCard(
          title: 'Total P2P Transactions',
          value: '4,632',
          trend: '+ 12.6%',
          trendPositive: true,
          color: Color(0xFF3B82F6),
          icon: Icons.groups_rounded,
        ),
        _P2PStatCard(
          title: 'Successful Transactions',
          value: '4,128',
          trend: '+ 11.3%',
          trendPositive: true,
          color: Color(0xFF10B981),
          icon: Icons.check_circle_outline_rounded,
        ),
        _P2PStatCard(
          title: 'Flagged Transactions',
          value: '128',
          trend: '+ 8.7%',
          trendPositive: false,
          color: Color(0xFFF59E0B),
          icon: Icons.warning_amber_rounded,
          isNegative: true,
        ),
        _P2PStatCard(
          title: 'Disputes',
          value: '36',
          trend: '- 5.2%',
          trendPositive: false,
          color: Color(0xFFEF4444),
          icon: Icons.error_outline_rounded,
          isNegative: true,
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
          _TabItem(label: 'Pending Review', count: '128', isSelected: false),
          const SizedBox(width: 12),
          _TabItem(label: 'Disputes', count: '36', isSelected: false),
          const SizedBox(width: 12),
          _TabItem(label: 'Resolved', isSelected: false),
          const SizedBox(width: 12),
          _TabItem(label: 'Blocked Users', isSelected: false),
        ],
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                SizedBox(width: 12),
                Text(
                  'Search by transaction ID, sender, receiver or reference...',
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
        _FilterButton(),
        const SizedBox(width: 12),
        _DateRangePicker(),
      ],
    );
  }

  Widget _buildRiskAndReasonsSection(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                const _CardHeader(title: 'Risk Overview (This Week)'),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: CircularProgressIndicator(
                        value: 0.6,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const Column(
                      children: [
                        Text(
                          '128',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Flagged',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _RiskLegend(
                  label: 'High Risk',
                  count: '28',
                  percentage: '21.9%',
                  color: const Color(0xFFEF4444),
                ),
                _RiskLegend(
                  label: 'Medium Risk',
                  count: '66',
                  percentage: '51.6%',
                  color: const Color(0xFFF59E0B),
                ),
                _RiskLegend(
                  label: 'Low Risk',
                  count: '34',
                  percentage: '26.5%',
                  color: const Color(0xFF10B981),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Column(
              children: [
                _CardHeader(title: 'Flagged Reasons', hasSeeAll: true),
                SizedBox(height: 24),
                _FlaggedReasonItem(
                  icon: Icons.replay_circle_filled_rounded,
                  label: 'Suspicious Amount',
                  count: '52',
                  percentage: '40.6%',
                  color: Color(0xFFEF4444),
                ),
                _FlaggedReasonItem(
                  icon: Icons.credit_card_off_rounded,
                  label: 'Multiple Failed Payments',
                  count: '28',
                  percentage: '21.9%',
                  color: Color(0xFFF59E0B),
                ),
                _FlaggedReasonItem(
                  icon: Icons.monitor_heart_rounded,
                  label: 'Unusual Activity',
                  count: '20',
                  percentage: '15.6%',
                  color: Color(0xFF8B5CF6),
                ),
                _FlaggedReasonItem(
                  icon: Icons.info_outline_rounded,
                  label: 'User Reported',
                  count: '28',
                  percentage: '21.9%',
                  color: Color(0xFF3B82F6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentP2PTransactions() {
    return Column(
      children: [
        _P2PTransactionItem(
          senderName: 'Mary Johnson',
          senderInitial: 'M',
          receiverName: 'John Michael',
          receiverInitial: 'J',
          amount: '₦25,000',
          date: '14 Jun, 10:30 AM',
          id: 'TXN-785412',
          status: 'Completed',
          statusColor: const Color(0xFF10B981),
        ),
        const SizedBox(height: 12),
        _P2PTransactionItem(
          senderName: 'Ibrahim Umar',
          senderInitial: 'I',
          receiverName: 'Adaora Nwosu',
          receiverInitial: 'A',
          amount: '₦18,500',
          date: '14 Jun, 09:15 AM',
          id: 'TXN-785411',
          status: 'Completed',
          statusColor: const Color(0xFF10B981),
        ),
        const SizedBox(height: 12),
        _P2PTransactionItem(
          senderName: 'Chinelo Okeke',
          senderInitial: 'C',
          receiverName: 'Femi Adebayo',
          receiverInitial: 'F',
          amount: '₦47,000',
          date: '14 Jun, 08:45 AM',
          id: 'TXN-785410',
          status: 'Flagged',
          statusColor: const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 12),
        _P2PTransactionItem(
          senderName: 'Tunde Bello',
          senderInitial: 'T',
          receiverName: 'Mary Johnson',
          receiverInitial: 'M',
          amount: '₦12,000',
          date: '14 Jun, 07:30 AM',
          id: 'TXN-785409',
          status: 'Pending Review',
          statusColor: const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 12),
        _P2PTransactionItem(
          senderName: 'Blessing Udo',
          senderInitial: 'B',
          receiverName: 'Ibrahim Umar',
          receiverInitial: 'I',
          amount: '₦30,000',
          date: '13 Jun, 11:20 PM',
          id: 'TXN-785408',
          status: 'Dispute',
          statusColor: const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildUsersAndMonitorSection(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Column(
              children: [
                _CardHeader(
                  title: 'Top P2P Users (By Volume)',
                  hasDropdown: true,
                ),
                SizedBox(height: 24),
                _TopUserItem(
                  rank: 1,
                  name: 'Mary Johnson',
                  amount: '₦450,000',
                  txnCount: '24 Transactions',
                  initial: 'M',
                ),
                Divider(height: 32, color: Color(0xFFF1F5F9)),
                _TopUserItem(
                  rank: 2,
                  name: 'Ibrahim Umar',
                  amount: '₦380,500',
                  txnCount: '21 Transactions',
                  initial: 'I',
                ),
                Divider(height: 32, color: Color(0xFFF1F5F9)),
                _TopUserItem(
                  rank: 3,
                  name: 'Adaora Nwosu',
                  amount: '₦312,000',
                  txnCount: '18 Transactions',
                  initial: 'A',
                ),
                Divider(height: 32, color: Color(0xFFF1F5F9)),
                _TopUserItem(
                  rank: 4,
                  name: 'John Michael',
                  amount: '₦275,000',
                  txnCount: '16 Transactions',
                  initial: 'J',
                ),
                Divider(height: 32, color: Color(0xFFF1F5F9)),
                _TopUserItem(
                  rank: 5,
                  name: 'Chinelo Okeke',
                  amount: '₦240,000',
                  txnCount: '14 Transactions',
                  initial: 'C',
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Column(
              children: [
                _CardHeader(
                  title: 'Suspicious Activity Monitor',
                  hasSeeAll: true,
                ),
                SizedBox(height: 24),
                _MonitorItem(
                  icon: Icons.person_add_disabled_rounded,
                  label: 'Multiple accounts activity',
                  count: '18',
                  color: Color(0xFFEF4444),
                ),
                Divider(height: 32, color: Color(0xFFF1F5F9)),
                _MonitorItem(
                  icon: Icons.compare_arrows_rounded,
                  label: 'Rapid in & out transfers',
                  count: '22',
                  color: Color(0xFFF59E0B),
                ),
                Divider(height: 32, color: Color(0xFFF1F5F9)),
                _MonitorItem(
                  icon: Icons.money_off_rounded,
                  label: 'Unusual transaction amount',
                  count: '16',
                  color: Color(0xFF8B5CF6),
                ),
                Divider(height: 32, color: Color(0xFFF1F5F9)),
                _MonitorItem(
                  icon: Icons.devices_rounded,
                  label: 'New device login & transfer',
                  count: '12',
                  color: Color(0xFF3B82F6),
                ),
                Divider(height: 32, color: Color(0xFFF1F5F9)),
                _MonitorItem(
                  icon: Icons.location_off_rounded,
                  label: 'IP location mismatch',
                  count: '8',
                  color: Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(Color primaryColor) {
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
          color: primaryColor,
        ),
        _QuickAction(
          icon: Icons.balance_rounded,
          label: 'Resolve Disputes',
          color: const Color(0xFFEF4444),
        ),
        _QuickAction(
          icon: Icons.person_off_outlined,
          label: 'Block User',
          color: const Color(0xFFF59E0B),
        ),
        _QuickAction(
          icon: Icons.bar_chart_rounded,
          label: 'Transaction Report',
          color: const Color(0xFF8B5CF6),
        ),
        _QuickAction(
          icon: Icons.security_rounded,
          label: 'Risk Settings',
          color: const Color(0xFF10B981),
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
                  fontSize: 22,
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
              Icon(
                isNegative
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isNegative
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  color: isNegative
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'vs last week',
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
  final String? count;
  final bool isSelected;
  const _TabItem({required this.label, this.count, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF0F62FE)
                  : const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count!,
                style: const TextStyle(
                  color: Colors.white,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: const Row(
        children: [
          Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 20),
          SizedBox(width: 8),
          Text(
            'Filter',
            style: TextStyle(
              color: Color(0xFF64748B),
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
    return Container(
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
          SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final bool hasSeeAll;
  final bool hasDropdown;
  const _CardHeader({
    required this.title,
    this.hasSeeAll = false,
    this.hasDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
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
        if (hasSeeAll)
          const Text(
            'View All',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F62FE),
            ),
          ),
        if (hasDropdown)
          Row(
            children: [
              const Text(
                'This Week',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF64748B).withValues(alpha: 0.5),
                size: 16,
              ),
            ],
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Text(
            count,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 8),
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
    );
  }
}

class _FlaggedReasonItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final String percentage;
  final Color color;

  const _FlaggedReasonItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.percentage,
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count,
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
          _UserStack(initial: senderInitial, label: 'Sender', name: senderName),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFFCBD5E1),
              size: 18,
            ),
          ),
          _UserStack(initial: receiverInitial, label: 'Receiver', name: receiverName),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '$date • $id',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
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
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}

class _UserStack extends StatelessWidget {
  final String initial;
  final String label;
  final String name;
  const _UserStack({
    required this.initial,
    required this.label,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.1),
          child: Text(initial, style: const TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Column(
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
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
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

  const _TopUserItem({
    required this.rank,
    required this.name,
    required this.amount,
    required this.txnCount,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              rank.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.1),
          child: Text(initial, style: const TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(width: 12),
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
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              txnCount,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFCBD5E1),
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

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
