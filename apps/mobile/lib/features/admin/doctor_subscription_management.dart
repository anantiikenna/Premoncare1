import 'package:flutter/material.dart';
import 'admin_scaffold.dart';

class DoctorSubscriptionManagement extends StatelessWidget {
  const DoctorSubscriptionManagement({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);

    return AdminScaffold(
      selectedIndex: 4,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMetricsGrid(primaryColor),
            const SizedBox(height: 24),
            _buildFilterTabs(primaryColor),
            const SizedBox(height: 16),
            _buildSearchAndFilters(),
            const SizedBox(height: 24),
            _buildSubscriptionTable(context),
            const SizedBox(height: 24),
            _buildBulkActions(),
            const SizedBox(height: 32),
            _buildAnalyticsSection(context, primaryColor),
            const SizedBox(height: 32),
            _buildLowerGrids(primaryColor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }



  Widget _buildMetricsGrid(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _MetricCard(label: 'Total Subscribers', value: '1,286', trend: '+ 12.4%', trendColor: Colors.green, icon: Icons.people_outline_rounded, iconColor: primaryColor),
            _MetricCard(label: 'Active', value: '986', trend: '76.7%', trendColor: Colors.green, icon: Icons.check_circle_outline_rounded, iconColor: Colors.orange),
            _MetricCard(label: 'Expiring Soon', value: '128', trend: 'Next 7 days', trendColor: Colors.orange, icon: Icons.timer_outlined, iconColor: Colors.red),
            _MetricCard(label: 'Expired', value: '98', trend: 'Requires attention', trendColor: Colors.red, icon: Icons.history_rounded, iconColor: Colors.purple),
            _MetricCard(label: 'Overdue', value: '74', trend: 'Payment overdue', trendColor: Colors.red, icon: Icons.account_balance_wallet_outlined, iconColor: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(Color primaryColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _TabButton(label: 'All (1,286)', isSelected: true, activeColor: primaryColor),
          _TabButton(label: 'Active (986)', isSelected: false, activeColor: primaryColor),
          _TabButton(label: 'Expiring Soon (128)', isSelected: false, activeColor: primaryColor),
          _TabButton(label: 'Expired (98)', isSelected: false, activeColor: primaryColor),
          _TabButton(label: 'Overdue (74)', isSelected: false, activeColor: primaryColor),
          _TabButton(label: 'Suspended (26)', isSelected: false, activeColor: primaryColor),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                  SizedBox(width: 12),
                  Text('Search doctor by name, email or plan...', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600)),
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

  Widget _buildSubscriptionTable(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        children: [
          _buildTableHeader(),
          _SubscriptionRow(name: 'Dr. Adaora Nwosu', plan: 'Premium 6 Months', amount: '₦130,000', status: 'Active', expiry: 'Expires in 23 days', lastPay: '₦130,000', payDate: '21 Jan 2025', payStatus: 'Paid', initial: 'A'),
          _SubscriptionRow(name: 'Dr. Ibrahim Umar', plan: 'Premium Monthly', amount: '₦25,000', status: 'Expiring Soon', expiry: 'Expires in 3 days', lastPay: '₦25,000', payDate: '25 Apr 2025', payStatus: 'Paid', initial: 'I'),
          _SubscriptionRow(name: 'Dr. Chinelo Okeke', plan: 'Premium 3 Months', amount: '₦70,000', status: 'Expired', expiry: 'Expired 5 days ago', lastPay: '₦70,000', payDate: '19 Feb 2025', payStatus: 'Failed', initial: 'C'),
          _SubscriptionRow(name: 'Dr. David Paul', plan: 'Premium Annual', amount: '₦240,000', status: 'Overdue', expiry: 'Payment overdue', lastPay: '₦240,000', payDate: '15 Apr 2025', payStatus: 'Overdue', initial: 'D'),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Doctor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
          Expanded(flex: 2, child: Text('Plan & Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
          Expanded(flex: 2, child: Text('Status & Expiry', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
          Expanded(flex: 2, child: Text('Last Payment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
          Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildBulkActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('0 Selected', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
              Text('Select doctors to perform bulk actions', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          _BulkActionButton(icon: Icons.send_rounded, label: 'Send Reminder', color: Color(0xFF0F62FE)),
          const SizedBox(width: 8),
          _BulkActionButton(icon: Icons.calendar_today_rounded, label: 'Extend Subscription', color: Color(0xFF0F62FE)),
          const SizedBox(width: 8),
          _BulkActionButton(icon: Icons.block_rounded, label: 'Suspend', color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          _BulkActionButton(icon: Icons.file_download_outlined, label: 'Export', color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Subscription Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _CircularChart(value: 0.76, label: '1,286', subLabel: 'Total', color: primaryColor),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          children: [
                            _LegendItem(label: 'Active', value: '(986)', percentage: '76.7%', color: primaryColor),
                            _LegendItem(label: 'Expiring Soon', value: '(128)', percentage: '10.0%', color: Colors.orange),
                            _LegendItem(label: 'Expired', value: '(98)', percentage: '7.6%', color: Colors.red),
                            _LegendItem(label: 'Overdue', value: '(74)', percentage: '5.7%', color: Colors.purple),
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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Expiring Soon (Next 7 Days)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Full list coming soon')),
                          );
                        },
                        child: const Text('View All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SmallDoctorItem(name: 'Dr. Ibrahim Umar', sub: 'Expires in 3 days', date: '25 May 2025'),
                  _SmallDoctorItem(name: 'Dr. Chinelo Okeke', sub: 'Expires in 5 days', date: '27 May 2025'),
                  _SmallDoctorItem(name: 'Dr. Mary Johnson', sub: 'Expires in 6 days', date: '29 May 2025'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowerGrids(Color primaryColor) {
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
                _ProgressRow(label: 'Active', value: '986', percentage: '76.7%', color: primaryColor),
                _ProgressRow(label: 'Expiring Soon', value: '128', percentage: '10.0%', color: Colors.orange),
                _ProgressRow(label: 'Expired', value: '98', percentage: '7.6%', color: Colors.red),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _SectionHeader('Plan Distribution'),
                const SizedBox(height: 16),
                _ProgressRow(label: 'Premium Annual', value: '286', percentage: '22.2%', color: Colors.blue),
                _ProgressRow(label: 'Premium 6 Months', value: '342', percentage: '26.6%', color: primaryColor),
                _ProgressRow(label: 'Premium 3 Months', value: '288', percentage: '22.4%', color: Colors.orange),
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
                _QuickActionTile(icon: Icons.warning_amber_rounded, label: 'Overdue Payments', color: Colors.red),
                _QuickActionTile(icon: Icons.bar_chart_rounded, label: 'Subscription Reports', color: primaryColor),
                _QuickActionTile(icon: Icons.verified_user_rounded, label: 'Payment Verification', color: Colors.green),
                _QuickActionTile(icon: Icons.notifications_active_rounded, label: 'Notification Settings', color: Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }


}

// Sub-widgets
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final Color trendColor;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({required this.label, required this.value, required this.trend, required this.trendColor, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 16)),
              const Spacer(),
              Text(trend, style: TextStyle(color: trendColor, fontSize: 9, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  const _TabButton({required this.label, required this.isSelected, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? activeColor : const Color(0xFFF1F5F9))),
      child: Text(label, style: TextStyle(color: isSelected ? activeColor : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _IconButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label coming soon')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Icon(icon, color: const Color(0xFF64748B), size: 20),
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
  final String payStatus;
  final String initial;

  const _SubscriptionRow({required this.name, required this.plan, required this.amount, required this.status, required this.expiry, required this.lastPay, required this.payDate, required this.payStatus, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.15),
                  child: Text(initial, style: const TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                    const Text('ID: DOC-2847', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
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
                Text(plan, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                Text(amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
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
                Text(expiry, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lastPay, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                Text(payDate, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.more_vert_rounded, color: Color(0xFFCBD5E1)),
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
      case 'active': color = const Color(0xFF10B981); break;
      case 'expiring soon': color = Colors.orange; break;
      case 'expired': color = Colors.red; break;
      case 'overdue': color = Colors.purple; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _BulkActionButton({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _CircularChart extends StatelessWidget {
  final double value;
  final String label;
  final String subLabel;
  final Color color;
  const _CircularChart({required this.value, required this.label, required this.subLabel, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(height: 80, width: 80, child: CircularProgressIndicator(value: value, strokeWidth: 8, backgroundColor: Colors.grey.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(color))),
        Column(mainAxisSize: MainAxisSize.min, children: [Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)), Text(subLabel, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700))]),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final String value;
  final String percentage;
  final Color color;
  const _LegendItem({required this.label, required this.value, required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
          const SizedBox(width: 12),
          Text(percentage, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _SmallDoctorItem extends StatelessWidget {
  final String name;
  final String sub;
  final String date;
  const _SmallDoctorItem({required this.name, required this.sub, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFF0F62FE),
            child: Text('D', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E293B))),
                Text(sub, style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Text(date, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
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
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        const Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFFCBD5E1)),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final String percentage;
  final Color color;
  const _ProgressRow({required this.label, required this.value, required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              Text('$value ($percentage)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: 0.7, backgroundColor: Colors.grey.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 4),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickActionTile({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}


