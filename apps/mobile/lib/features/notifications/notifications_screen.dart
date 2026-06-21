import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_locator.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';

final notificationsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .map((data) => List<Map<String, dynamic>>.from(data));
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTab = 'All';

  static const _tabs = ['All', 'Clinical', 'Appointments', 'Payment', 'Emergency'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabs[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterNotifications(List<Map<String, dynamic>> notifications) {
    if (_selectedTab == 'All') return notifications;

    final typeMap = {
      'Clinical': 'prescription',
      'Appointments': 'appointment',
      'Payment': 'payment',
      'Emergency': 'system',
    };

    final type = typeMap[_selectedTab];
    if (type == null) return notifications;
    return notifications.where((n) => n['type'] == type).toList();
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'appointment': return Icons.calendar_today_rounded;
      case 'payment': return Icons.account_balance_wallet_rounded;
      case 'prescription': return Icons.medical_services_rounded;
      case 'message': return Icons.chat_bubble_rounded;
      case 'system': return Icons.warning_amber_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColor(String? type, BuildContext context) {
    switch (type) {
      case 'appointment': return AppColors.primary;
      case 'payment': return AppColors.success;
      case 'prescription': return AppColors.primary;
      case 'message': return AppColors.info;
      case 'system': return AppColors.error;
      default: return AppColors.textSecondaryOf(context);
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimaryOf(context)),
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications', style: AppTypography.h3),
                notificationsAsync.when(
                  loading: () => Text('Loading...', style: TextStyle(fontSize: 11, color: AppColors.textTertiaryOf(context))),
                  error: (_, _) => const Text('Error', style: TextStyle(fontSize: 11, color: AppColors.error)),
                  data: (notifs) => Text(
                    '${notifs.where((n) => n['is_read'] == false).length} unread',
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiaryOf(context), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final user = supabase.auth.currentUser;
              if (user == null) return;
              await supabase
                  .from('notifications')
                  .update({'is_read': true})
                  .eq('user_id', user.id)
                  .eq('is_read', false);
            },
            child: Text('Mark all read', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiaryOf(context),
          labelStyle: AppTypography.labelMedium,
          indicatorColor: AppColors.primary,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load notifications', style: AppTypography.bodyMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          final filtered = _filterNotifications(notifications);

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded, color: AppColors.textTertiaryOf(context), size: 56),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: AppTypography.h4),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see appointment, payment and clinical updates here.',
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final notif = filtered[index];
              final isRead = notif['is_read'] == true;
              final type = notif['type'] as String?;
              final color = _getColor(type, context);
              final icon = _getIcon(type);

              return GestureDetector(
                onTap: () async {
                  if (!isRead) {
                    await supabase
                        .from('notifications')
                        .update({'is_read': true})
                        .eq('id', notif['id']);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead ? AppColors.surfaceOf(context) : color.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead ? AppColors.borderOf(context) : color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notif['title'] ?? 'Notification',
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w900,
                                      fontSize: 14,
                                      color: AppColors.textPrimaryOf(context),
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif['message'] ?? '',
                              style: AppTypography.bodySmall.copyWith(height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _timeAgo(notif['created_at']),
                              style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiaryOf(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
