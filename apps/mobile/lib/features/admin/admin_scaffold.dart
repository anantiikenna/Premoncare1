import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_locator.dart';
import '../../shared/widgets/global_user_avatar.dart';
import 'admin_dashboard.dart';
import 'user_management_panel.dart';
import 'doctor_verification_panel.dart';
import 'forum_moderation_panel.dart';

class AdminScaffold extends ConsumerStatefulWidget {
  final Widget? body;
  final int selectedIndex;

  const AdminScaffold({
    super.key,
    this.body,
    this.selectedIndex = 0,
  });

  @override
  ConsumerState<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends ConsumerState<AdminScaffold> {
  int _currentIndex = 0;

  bool get _isShell => widget.body == null;

  final List<Widget> _tabScreens = [
    const AdminDashboard(),
    const UserManagementPanel(),
    const DoctorVerificationPanel(),
    const ForumModerationPanel(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant AdminScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isShell && oldWidget.selectedIndex != widget.selectedIndex) {
      _currentIndex = widget.selectedIndex;
    }
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Section', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: Color(0xFF0F62FE)),
              title: const Text('Admin Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin profile settings are being developed. Your account is managed by the platform owner.')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF0F62FE)),
              title: const Text('Permissions / Role', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings-privacy');
              },
            ),
            ListTile(
              leading: const Icon(Icons.security_rounded, color: Color(0xFF0F62FE)),
              title: const Text('Security Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings-privacy');
              },
            ),
            ListTile(
              leading: const Icon(Icons.devices_rounded, color: Color(0xFF0F62FE)),
              title: const Text('Device Sessions', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/audit-timeline');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_center_rounded, color: Color(0xFF0F62FE)),
              title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact support: support@premoncare.com')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                await supabase.auth.signOut();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Operational Modules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              _buildMoreTile(context, Icons.analytics_outlined, 'Reports & Insights', '/admin/reports'),
              _buildMoreTile(context, Icons.monetization_on_outlined, 'P2P Monitoring', '/admin/p2p-monitoring'),
              _buildMoreTile(context, Icons.notifications_outlined, 'Notification Control', '/admin/notifications'),
              _buildMoreTile(context, Icons.person_add_alt_1_outlined, 'Doctor Subscriptions', '/admin/doctor-subscriptions'),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreTile(BuildContext context, IconData icon, String title, String? route) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F62FE).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF0F62FE)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () {
        Navigator.pop(context);
        if (route != null) context.push(route);
      },
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, String route, {bool isCurrent = false}) {
    return ListTile(
      leading: Icon(icon, color: isCurrent ? const Color(0xFF0F62FE) : const Color(0xFF64748B)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
          color: isCurrent ? const Color(0xFF0F62FE) : const Color(0xFF1E293B),
        ),
      ),
      selected: isCurrent,
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);
    final activeIndex = _isShell ? _currentIndex : widget.selectedIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B), size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Premon Care Admin',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 28),
            onPressed: () => context.push('/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: GestureDetector(
              onTap: () => _showProfileSheet(context),
              child: const GlobalUserAvatar(radius: 16),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F62FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Premon Care Admin', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
                        Text('System Controller', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(context, Icons.dashboard_outlined, 'Dashboard', '/admin-dashboard', isCurrent: activeIndex == 0),
                    _buildDrawerItem(context, Icons.people_outline, 'User Management', '/admin/user-management', isCurrent: activeIndex == 1),
                    _buildDrawerItem(context, Icons.verified_user_outlined, 'Doctor Verification', '/admin/doctor-verification', isCurrent: activeIndex == 2),
                    _buildDrawerItem(context, Icons.account_balance_wallet_outlined, 'Financial Moderation', '/admin/financial'),
                    _buildDrawerItem(context, Icons.monetization_on_outlined, 'P2P Monitoring', '/admin/p2p-monitoring'),
                    _buildDrawerItem(context, Icons.emergency_outlined, 'Emergency Queue', '/admin/emergency-queue'),
                    _buildDrawerItem(context, Icons.forum_outlined, 'Forum Moderation', '/admin/forum-moderation', isCurrent: activeIndex == 3),
                    _buildDrawerItem(context, Icons.analytics_outlined, 'Reports', '/admin/reports'),
                    _buildDrawerItem(context, Icons.history_outlined, 'Audit Timeline', '/admin/audit-timeline'),
                    _buildDrawerItem(context, Icons.card_membership_outlined, 'Subscription Plans', '/admin/subscription-control'),
                    _buildDrawerItem(context, Icons.gavel_outlined, 'Dispute Resolution', '/admin/disputes'),
                    _buildDrawerItem(context, Icons.settings_outlined, 'Platform Settings', '/settings-privacy'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isShell
          ? IndexedStack(
              index: _currentIndex,
              children: _tabScreens,
            )
          : widget.body!,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFF1F5F9))),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home_rounded, 'Dashboard', isSelected: activeIndex == 0, activeColor: primaryColor, onTap: () {
                if (_isShell) {
                  setState(() => _currentIndex = 0);
                } else {
                  context.go('/admin-dashboard');
                }
              }),
              _buildNavItem(context, Icons.people_alt_rounded, 'Users', isSelected: activeIndex == 1, activeColor: primaryColor, onTap: () {
                if (_isShell) {
                  setState(() => _currentIndex = 1);
                } else {
                  context.go('/admin/user-management');
                }
              }),
              _buildNavItem(context, Icons.medical_services_rounded, 'Doctors', isSelected: activeIndex == 2, activeColor: primaryColor, onTap: () {
                if (_isShell) {
                  setState(() => _currentIndex = 2);
                } else {
                  context.go('/admin/doctor-verification');
                }
              }),
              _buildNavItem(context, Icons.forum_rounded, 'Forum', isSelected: activeIndex == 3, activeColor: primaryColor, onTap: () {
                if (_isShell) {
                  setState(() => _currentIndex = 3);
                } else {
                  context.go('/admin/forum-moderation');
                }
              }),
              _buildNavItem(context, Icons.more_horiz_rounded, 'More', isSelected: activeIndex == 4, activeColor: primaryColor, onTap: () => _showMoreSheet(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, {required bool isSelected, required Color activeColor, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? activeColor : const Color(0xFF94A3B8), size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : const Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
