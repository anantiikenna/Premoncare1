import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'This Week';

  final List<String> _filters = ['Today', 'This Week', 'This Month', 'Unread only'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Stay updated with your health journey',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read'), backgroundColor: Color(0xFF10B981)),
              );
            },
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF1E293B), size: 18),
            onPressed: () {
              setState(() {
                _selectedFilter = _selectedFilter == 'Unread only' ? 'This Week' : 'Unread only';
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Category Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            labelColor: primaryColor,
            unselectedLabelColor: const Color(0xFF94A3B8),
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            dividerColor: Colors.transparent,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: [
              _buildTab('All', 28),
              _buildTab('Unread', 8),
              _buildTab('Appointments', 9),
              _buildTab('Payments', 6),
              _buildTab('Emergency', 3),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search + Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search notifications...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 16),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      icon: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.expand_more, size: 14, color: Color(0xFF1E293B)),
                      ),
                      style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFilter = newValue!;
                        });
                      },
                      items: _filters.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 8),
                              Text(value),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Notifications List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const Text(
                  'Priority',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 12),
                
                // Emergency Alert Card
                _buildEmergencyCard(),
                
                const SizedBox(height: 24),
                const Text(
                  'Today',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 12),
                
                _buildNotificationCard(
                  icon: Icons.calendar_today,
                  iconBg: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                  iconColor: const Color(0xFF0F62FE),
                  title: 'Appointment Confirmed',
                  message: 'Your consultation with Dr. Adaora Nwosu is scheduled for 3:00 PM today.',
                  time: '2m ago',
                  badge: 'Unread',
                  badgeColor: const Color(0xFF0F62FE),
                  footer: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      const Text('Today, 10:15 AM', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                
                _buildNotificationCard(
                  icon: Icons.account_balance_wallet,
                  iconBg: const Color(0xFF10B981).withValues(alpha: 0.1),
                  iconColor: const Color(0xFF10B981),
                  title: 'Payment Verified',
                  message: 'Your payment of ₦8,000 has been successfully verified.',
                  time: '15m ago',
                  badge: 'Success',
                  badgeColor: const Color(0xFF10B981),
                  action: _buildActionBtn('View Receipt', () => context.push('/appointments')),
                  footer: const Row(
                    children: [
                      Icon(Icons.tag, size: 12, color: Color(0xFF94A3B8)),
                      SizedBox(width: 4),
                      Text('Transaction ID: TXN-8394721', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                
                _buildNotificationCard(
                  icon: Icons.person_add,
                  iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Verification Approved',
                  message: 'Your doctor profile has been verified successfully. You can now start receiving patients.',
                  time: '1h ago',
                  badge: 'Success',
                  badgeColor: const Color(0xFF10B981),
                ),
                
                _buildNotificationCard(
                  icon: Icons.warning_amber,
                  iconBg: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  iconColor: const Color(0xFFEF4444),
                  title: 'Missed Consultation',
                  message: 'You missed your consultation with Dr. David Paul scheduled at 9:00 AM.',
                  time: '2h ago',
                  badge: 'Attention',
                  badgeColor: const Color(0xFFF59E0B),
                  action: _buildActionBtn('Reschedule', () => context.push('/appointments'), isOutline: true, color: const Color(0xFFEF4444)),
                  footer: const Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Color(0xFFEF4444)),
                      SizedBox(width: 4),
                      Text('Today, 9:00 AM', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                _buildNotificationCard(
                  icon: Icons.description,
                  iconBg: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Lab Report Available',
                  message: 'Your lab report from 12 May 2025 is now available.',
                  time: '3h ago',
                  badge: 'New',
                  badgeColor: const Color(0xFF8B5CF6),
                  action: _buildActionBtn('View Report', () => context.push('/vault'), isOutline: true, color: const Color(0xFF8B5CF6)),
                ),

                _buildNotificationCard(
                  icon: Icons.notifications,
                  iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Appointment Reminder',
                  message: 'Reminder: Your consultation with Dr. Chinedu Okeke is tomorrow at 11:30 AM.',
                  time: '1d ago',
                  badge: 'Reminder',
                  badgeColor: const Color(0xFF3B82F6),
                ),

                const SizedBox(height: 32),
                // Privacy Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F62FE).withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0F62FE).withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF10B981), size: 24),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your notifications are securely encrypted and only visible to you.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/settings-privacy'),
                        child: const Row(
                          children: [
                            Text('Learn more', style: TextStyle(color: Color(0xFF0F62FE), fontSize: 11, fontWeight: FontWeight.bold)),
                            Icon(Icons.chevron_right, size: 12, color: Color(0xFF0F62FE)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        children: [
          Text(label),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.warning, color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Emergency Consultation Available',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFB91C1C)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'URGENT',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Dr. Ibrahim Umar is now available for emergency consultation.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    const Text('2m ago', style: TextStyle(fontSize: 10, color: Color(0xFF991B1B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFEE2E2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Dismiss', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => context.push('/doctor-search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Join Now', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required String badge,
    required Color badgeColor,
    Widget? action,
    Widget? footer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500, height: 1.4),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 8),
                  footer,
                ],
                if (action != null) ...[
                  const SizedBox(height: 12),
                  action,
                ],
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, VoidCallback onPressed, {bool isOutline = true, Color color = const Color(0xFF0F62FE)}) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: isOutline
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            ),
    );
  }
}
