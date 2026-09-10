import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import 'admin_scaffold.dart';
import 'admin_providers.dart';
import 'admin_shared_widgets.dart';

final _channelConfigsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final response = await Supabase.instance.client
      .from('notification_channels_config')
      .select()
      .order('id');
  return List<Map<String, dynamic>>.from(response);
});

final _recentNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final response = await Supabase.instance.client
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  },
);

final _notificationStatsProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final client = Supabase.instance.client;

  final totalResponse = await client
      .from('notifications')
      .count(CountOption.exact);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayResponse = await client
      .from('notifications')
      .count(CountOption.exact)
      .gte('created_at', todayStart.toIso8601String());

  final readResponse = await client
      .from('notifications')
      .count(CountOption.exact)
      .eq('is_read', true);

  return {
    'total': totalResponse,
    'today': todayResponse,
    'read': readResponse,
    'unread': totalResponse - readResponse,
  };
});

class NotificationControlPanel extends ConsumerStatefulWidget {
  const NotificationControlPanel({super.key});

  @override
  ConsumerState<NotificationControlPanel> createState() =>
      _NotificationControlPanelState();
}

class _NotificationControlPanelState
    extends ConsumerState<NotificationControlPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(_channelConfigsProvider);
      ref.invalidate(_recentNotificationsProvider);
      ref.invalidate(_notificationStatsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 4,
      body: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showSendNotificationDialog(),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          icon: const Icon(Icons.send_rounded, size: 20),
          label: const Text(
            'Send Notification',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildStatsGrid(),
              const SizedBox(height: 32),
              _buildNavigationTabs(),
              const SizedBox(height: 32),
              _buildSectionHeader(
                'Notification Channels',
                subtitle: 'Enable or disable notification channels',
              ),
              const SizedBox(height: 16),
              _buildChannelsList(),
              const SizedBox(height: 32),
              _buildSectionHeader('Recent Notifications'),
              const SizedBox(height: 16),
              _buildRecentNotifications(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String targetRole = 'all';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Send Notification',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Notification\ title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceAltOf(context),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    hintText: 'Notification\ message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceAltOf(context),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: targetRole,
                  decoration: InputDecoration(
                    labelText: 'Target Audience',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceAltOf(context),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text\('All\ Users'\)),
                    DropdownMenuItem(
                      value: 'patient',
                      child: Text\('Patients\ Only'\),
                    ),
                    DropdownMenuItem(
                      value: 'doctor',
                      child: Text\('Doctors\ Only'\),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => targetRole = v);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondaryOf(ctx),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (titleController.text.isEmpty ||
                          messageController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields'),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final adminService = ref.read(adminServiceProvider);
                        await adminService.sendSystemNotification(
                          title: titleController.text.trim(),
                          message: messageController.text.trim(),
                          targetRole: targetRole,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        ref.invalidate(_recentNotificationsProvider);
                        ref.invalidate(_notificationStatsProvider);
                        if (context.mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Notification sent successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (context.mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to send: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textInverse,
                      ),
                    )
                  : const Text(
                      'Send',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final statsAsync = ref.watch(_notificationStatsProvider);

    return statsAsync.when(
      data: (stats) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.4,
        children: [
          _NotifyStatCard(
            title: 'Total Sent',
            value: '${stats['total'] ?? 0}',
            color: AppColors.info,
            icon: Icons.send_rounded,
          ),
          _NotifyStatCard(
            title: 'Today',
            value: '${stats['today'] ?? 0}',
            color: AppColors.success,
            icon: Icons.today_rounded,
          ),
          _NotifyStatCard(
            title: 'Read',
            value: '${stats['read'] ?? 0}',
            color: AppColors.primary,
            icon: Icons.mark_email_read_rounded,
          ),
          _NotifyStatCard(
            title: 'Unread',
            value: '${stats['unread'] ?? 0}',
            color: AppColors.error,
            icon: Icons.mark_email_unread_rounded,
          ),
        ],
      ),
      loading: () => const Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => AdminErrorState(
        message: 'Failed to load stats: $e',
        onRetry: () => ref.invalidate(_notificationStatsProvider),
      ),
    );
  }

  Widget _buildNavigationTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabItem(label: 'Channels', isSelected: true),
          const SizedBox(width: 12),
          _TabItem(label: 'Templates', isSelected: false),
          const SizedBox(width: 12),
          _TabItem(label: 'Scheduled', isSelected: false),
          const SizedBox(width: 12),
          _TabItem(label: AppLocalizations.of(context)!.historyLabel, isSelected: false),
        ],
      ),
    );
  }

  Widget _buildChannelsList() {
    final channelsAsync = ref.watch(_channelConfigsProvider);

    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.borderLightOf(context)),
            ),
            child: Center(
              child: Text(
                'No notification channels configured',
                style: TextStyle(
                  color: AppColors.textTertiaryOf(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.borderLightOf(context)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < channels.length; i++) ...[
                _ChannelTile(
                  channelId: channels[i]['id'] as String,
                  label: _formatChannelLabel(channels[i]['id'] as String),
                  sub: _getChannelDescription(channels[i]['id'] as String),
                  color: _getChannelColor(channels[i]['id'] as String),
                  icon: _getChannelIcon(channels[i]['id'] as String),
                  isEnabled: channels[i]['is_enabled'] as bool? ?? false,
                  onToggle: (value) =>
                      _toggleChannel(channels[i]['id'] as String, value),
                ),
                if (i < channels.length - 1)
                  Divider(height: 32, color: AppColors.dividerOf(context)),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => AdminErrorState(
        message: 'Failed to load channels: $e',
        onRetry: () => ref.invalidate(_channelConfigsProvider),
      ),
    );
  }

  Future<void> _toggleChannel(String channelId, bool value) async {
    try {
      final adminService = ref.read(adminServiceProvider);
      await adminService.updateChannelConfig(channelId, value);
      ref.invalidate(_channelConfigsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Channel ${_formatChannelLabel(channelId)} ${value ? "enabled" : "disabled"}',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ref.invalidate(_channelConfigsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update channel: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildRecentNotifications() {
    final notificationsAsync = ref.watch(_recentNotificationsProvider);

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.borderLightOf(context)),
            ),
            child: Center(
              child: Text(
                'No recent notifications',
                style: TextStyle(
                  color: AppColors.textTertiaryOf(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < notifications.length; i++) ...[
              _buildNotificationTile(notifications[i]),
              if (i < notifications.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => AdminErrorState(
        message: 'Failed to load notifications: $e',
        onRetry: () => ref.invalidate(_recentNotificationsProvider),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    final createdAt = DateTime.tryParse(
      notification['created_at'] as String? ?? '',
    );
    final dateStr = createdAt != null
        ? '${createdAt.day.toString().padLeft(2, '0')} ${_monthAbbr(createdAt.month)}, ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '';
    final type = notification['type'] as String? ?? 'system';
    final isRead = notification['is_read'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getNotificationTypeColor(type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getNotificationTypeIcon(type),
              color: _getNotificationTypeColor(type),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] as String? ?? 'Untitled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification['message'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
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
                type.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: AppColors.textTertiaryOf(context),
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  color: AppColors.textTertiaryOf(context),
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
                  color: (isRead ? AppColors.success : AppColors.info)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isRead ? 'Read' : 'Sent',
                  style: TextStyle(
                    color: isRead ? AppColors.success : AppColors.info,
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

  String _monthAbbr(int month) {
    const months = [
      '',
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
    return months[month];
  }

  String _formatChannelLabel(String id) {
    switch (id) {
      case 'in_app':
        return 'In-App Notifications';
      case 'email':
        return 'Email Notifications';
      case 'sms':
        return 'SMS Notifications';
      case 'push':
        return 'Push Notifications';
      case 'telegram':
        return 'Telegram Notifications';
      case 'whatsapp':
        return 'WhatsApp Notifications';
      default:
        return id.replaceFirst('_', ' ').toUpperCase();
    }
  }

  String _getChannelDescription(String id) {
    switch (id) {
      case 'in_app':
        return 'Send notifications within the app';
      case 'email':
        return 'Send notifications via email';
      case 'sms':
        return 'Send notifications via SMS';
      case 'push':
        return 'Send push notifications to mobile devices';
      case 'telegram':
        return 'Send notifications to Telegram channel';
      case 'whatsapp':
        return 'Send notifications via WhatsApp';
      default:
        return 'Notification channel configuration';
    }
  }

  Color _getChannelColor(String id) {
    switch (id) {
      case 'in_app':
        return AppColors.info;
      case 'email':
        return AppColors.success;
      case 'sms':
        return AppColors.primary;
      case 'push':
        return AppColors.warning;
      case 'telegram':
        return AppColors.error;
      case 'whatsapp':
        return AppColors.success;
      default:
        return AppColors.textSecondaryOf(context);
    }
  }

  IconData _getChannelIcon(String id) {
    switch (id) {
      case 'in_app':
        return Icons.notifications_none_rounded;
      case 'email':
        return Icons.email_outlined;
      case 'sms':
        return Icons.chat_bubble_outline_rounded;
      case 'push':
        return Icons.phone_android_rounded;
      case 'telegram':
        return Icons.send_rounded;
      case 'whatsapp':
        return Icons.chat_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case 'appointment':
        return AppColors.primary;
      case 'payment':
        return AppColors.warning;
      case 'message':
        return AppColors.info;
      case 'emergency':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today_rounded;
      case 'payment':
        return Icons.payments_outlined;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'emergency':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
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
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
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
  final IconData icon;
  final Color color;

  const _NotifyStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.borderLightOf(context),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? AppColors.primary
              : AppColors.textSecondaryOf(context),
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final String channelId;
  final String label;
  final String sub;
  final Color color;
  final IconData icon;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;

  const _ChannelTile({
    required this.channelId,
    required this.label,
    required this.sub,
    required this.color,
    required this.icon,
    required this.isEnabled,
    required this.onToggle,
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
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  color: AppColors.textTertiaryOf(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: isEnabled,
          onChanged: onToggle,
          activeThumbColor: AppColors.success,
          activeTrackColor: AppColors.success.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}
