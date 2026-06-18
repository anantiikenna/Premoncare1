import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_scaffold.dart';

class NotificationControlPanel extends ConsumerWidget {
  const NotificationControlPanel({super.key});

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
            _buildStatsGrid(),
            const SizedBox(height: 32),
            _buildNavigationTabs(primaryColor),
            const SizedBox(height: 32),
            _buildSectionHeader(
              'Notification Channels',
              subtitle: 'Enable or disable notification channels',
            ),
            const SizedBox(height: 16),
            _buildChannelsList(primaryColor),
            const SizedBox(height: 32),
            _buildSectionHeader('Recent Notifications', onSeeAll: () {}),
            const SizedBox(height: 16),
            _buildRecentNotifications(),
            const SizedBox(height: 32),
            _buildSectionHeader('Send New Notification'),
            const SizedBox(height: 16),
            _buildAudienceSelectors(primaryColor),
            const SizedBox(height: 32),
            _buildSectionHeader('Quick Templates', onSeeAll: () {}),
            const SizedBox(height: 16),
            _buildQuickTemplates(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }



  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: const [
        _NotifyStatCard(
          title: 'Notifications Sent',
          value: '12,845',
          trend: '+ 18.6%',
          trendPositive: true,
          color: Color(0xFF3B82F6),
          icon: Icons.send_rounded,
        ),
        _NotifyStatCard(
          title: 'Users Reached',
          value: '98,560',
          trend: '+ 22.4%',
          trendPositive: true,
          color: Color(0xFF10B981),
          icon: Icons.people_rounded,
        ),
        _NotifyStatCard(
          title: 'Delivery Rate',
          value: '99.2%',
          trend: '+ 2.1%',
          trendPositive: true,
          color: Color(0xFF8B5CF6),
          icon: Icons.notifications_active_rounded,
        ),
        _NotifyStatCard(
          title: 'Failed / Bounced',
          value: '124',
          trend: '- 8.7%',
          trendPositive: false,
          color: Color(0xFFEF4444),
          icon: Icons.cancel_rounded,
          isNegative: true,
        ),
      ],
    );
  }

  Widget _buildNavigationTabs(Color primaryColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabItem(
            label: 'Channels',
            isSelected: true,
            primaryColor: primaryColor,
          ),
          const SizedBox(width: 12),
          _TabItem(
            label: 'Templates',
            isSelected: false,
            primaryColor: primaryColor,
          ),
          const SizedBox(width: 12),
          _TabItem(
            label: 'Scheduled',
            isSelected: false,
            primaryColor: primaryColor,
          ),
          const SizedBox(width: 12),
          _TabItem(
            label: 'History',
            isSelected: false,
            primaryColor: primaryColor,
          ),
          const SizedBox(width: 12),
          _TabItem(
            label: 'Settings',
            isSelected: false,
            primaryColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsList(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          _ChannelTile(
            icon: Icons.notifications_none_rounded,
            label: 'In-App Notifications',
            sub: 'Send notifications within the app',
            color: const Color(0xFF3B82F6),
            isActive: true,
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _ChannelTile(
            icon: Icons.email_outlined,
            label: 'Email Notifications',
            sub: 'Send notifications via email',
            color: const Color(0xFF10B981),
            isActive: true,
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _ChannelTile(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'SMS Notifications',
            sub: 'Send notifications via SMS',
            color: const Color(0xFF8B5CF6),
            isActive: true,
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _ChannelTile(
            icon: Icons.phone_android_rounded,
            label: 'Push Notifications',
            sub: 'Send push notifications to mobile devices',
            color: const Color(0xFFF59E0B),
            isActive: true,
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _ChannelTile(
            icon: Icons.send_rounded,
            label: 'Telegram Notifications',
            sub: 'Send notifications to Telegram channel',
            color: const Color(0xFFEF4444),
            isActive: false,
          ),
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          _ChannelTile(
            icon: Icons.chat_rounded,
            label: 'WhatsApp Notifications',
            sub: 'Send notifications via WhatsApp',
            color: const Color(0xFF10B981),
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotifications() {
    return Column(
      children: const [
        _RecentNotifyTile(
          icon: Icons.notifications_active_rounded,
          title: 'Emergency Alert: System Maintenance',
          sub: 'System maintenance scheduled for 12:00 AM',
          audience: 'All Users',
          date: '14 Jun, 10:30 AM',
          status: 'Sent',
          statusColor: Color(0xFF10B981),
          iconBg: Color(0xFFEFF6FF),
          iconColor: Color(0xFF3B82F6),
        ),
        SizedBox(height: 12),
        _RecentNotifyTile(
          icon: Icons.campaign_rounded,
          title: 'New Feature Announcement',
          sub: 'Check out our new Tele-consultation feature',
          audience: 'Doctors',
          date: '14 Jun, 09:15 AM',
          status: 'Sent',
          statusColor: Color(0xFF10B981),
          iconBg: Color(0xFFECFDF5),
          iconColor: Color(0xFF10B981),
        ),
        SizedBox(height: 12),
        _RecentNotifyTile(
          icon: Icons.calendar_today_rounded,
          title: 'Appointment Reminder',
          sub: 'Reminder for upcoming appointment',
          audience: 'Patients',
          date: '14 Jun, 08:45 AM',
          status: 'Scheduled',
          statusColor: Color(0xFF3B82F6),
          iconBg: Color(0xFFF5F3FF),
          iconColor: Color(0xFF8B5CF6),
        ),
        SizedBox(height: 12),
        _RecentNotifyTile(
          icon: Icons.payments_outlined,
          title: 'Payment Successful',
          sub: 'Your payment of ₦25,000 was successful',
          audience: 'Patients',
          date: '14 Jun, 08:22 AM',
          status: 'Sent',
          statusColor: Color(0xFF10B981),
          iconBg: Color(0xFFFFF7ED),
          iconColor: Color(0xFFF59E0B),
        ),
        SizedBox(height: 12),
        _RecentNotifyTile(
          icon: Icons.warning_amber_rounded,
          title: 'Security Alert',
          sub: 'Unusual login detected on your account',
          audience: 'Specific Users',
          date: '13 Jun, 11:50 PM',
          status: 'Failed',
          statusColor: Color(0xFFEF4444),
          iconBg: Color(0xFFFEF2F2),
          iconColor: Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildAudienceSelectors(Color primaryColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AudienceItem(
            icon: Icons.groups_rounded,
            label: 'Send to All Users',
            sub: 'Broadcast to everyone',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 16),
          _AudienceItem(
            icon: Icons.medical_services_rounded,
            label: 'Send to Doctors',
            sub: 'Notify all doctors',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 16),
          _AudienceItem(
            icon: Icons.person_rounded,
            label: 'Send to Patients',
            sub: 'Notify all patients',
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(width: 16),
          _AudienceItem(
            icon: Icons.track_changes_rounded,
            label: 'Custom Audience',
            sub: 'Select specific users',
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTemplates() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          _TemplateItem(
            icon: Icons.build_rounded,
            label: 'Maintenance Alert',
            color: Color(0xFF3B82F6),
          ),
          SizedBox(width: 12),
          _TemplateItem(
            icon: Icons.star_rounded,
            label: 'New Feature',
            color: Color(0xFF10B981),
          ),
          SizedBox(width: 12),
          _TemplateItem(
            icon: Icons.payments_rounded,
            label: 'Payment Reminder',
            color: Color(0xFFF59E0B),
          ),
          SizedBox(width: 12),
          _TemplateItem(
            icon: Icons.calendar_month_rounded,
            label: 'Appointment Reminder',
            color: Color(0xFF8B5CF6),
          ),
          SizedBox(width: 12),
          _TemplateItem(
            icon: Icons.security_rounded,
            label: 'Security Alert',
            color: Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? subtitle,
    VoidCallback? onSeeAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }


}

class _NotifyStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool trendPositive;
  final IconData icon;
  final Color color;
  final bool isNegative;

  const _NotifyStatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendPositive,
    required this.icon,
    required this.color,
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
  final Color primaryColor;
  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.5)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? primaryColor : const Color(0xFF64748B),
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final bool isActive;

  const _ChannelTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: isActive,
          onChanged: (v) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Preference updated')),
            );
          },
          activeThumbColor: const Color(0xFF10B981),
          activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.2),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuration coming soon')),
            );
          },
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            foregroundColor: const Color(0xFF64748B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Configure',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _RecentNotifyTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final String audience;
  final String date;
  final String status;
  final Color statusColor;
  final Color iconBg;
  final Color iconColor;

  const _RecentNotifyTile({
    required this.icon,
    required this.title,
    required this.sub,
    required this.audience,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.iconBg,
    required this.iconColor,
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                audience,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudienceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  const _AudienceItem({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TemplateItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
