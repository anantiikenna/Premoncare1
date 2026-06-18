import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_locator.dart';
import '../../shared/widgets/global_user_avatar.dart';
import 'doctor_dashboard.dart';
import 'doctor_appointments_screen.dart';
import '../messaging/chat_list_screen.dart';
import '../forum/forum_list_screen.dart';
import '../patient/profile_screen.dart';

class DoctorMainLayout extends ConsumerStatefulWidget {
  const DoctorMainLayout({super.key});

  @override
  ConsumerState<DoctorMainLayout> createState() => _DoctorMainLayoutState();
}

class _DoctorMainLayoutState extends ConsumerState<DoctorMainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DoctorDashboard(),
    const DoctorAppointmentsScreen(),
    const ChatListScreen(),
    const ForumListScreen(),
    const ProfileScreen(),
  ];

  void _showDoctorProfileMenu(BuildContext context) {
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
            const Text('Doctor Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF0F62FE)),
              title: const Text('Doctor Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified_user_outlined, color: Color(0xFF0F62FE)),
              title: const Text('Verification Status', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                context.push('/verify-practitioner');
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_membership_outlined, color: Color(0xFF0F62FE)),
              title: const Text('Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                context.push('/doctor/subscription');
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule_outlined, color: Color(0xFF0F62FE)),
              title: const Text('Availability', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                context.push('/doctor/schedule');
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up_rounded, color: Color(0xFF0F62FE)),
              title: const Text('Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                context.push('/doctor/earnings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Color(0xFF0F62FE)),
              title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings-privacy');
              },
            ),
            const Divider(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('D', style: TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Premon', style: TextStyle(color: Color(0xFF0F62FE), fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Care', style: TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('DOCTOR', style: TextStyle(color: Color(0xFF0F62FE), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B)),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _showDoctorProfileMenu(context),
            child: const GlobalUserAvatar(radius: 16),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Dashboard',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavBarItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today_rounded,
                  label: 'Appointments',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavBarItem(
                  icon: Icons.group_outlined,
                  activeIcon: Icons.group_rounded,
                  label: 'Patients',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavBarItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Community',
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavBarItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFF0F62FE) : const Color(0xFF94A3B8);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

