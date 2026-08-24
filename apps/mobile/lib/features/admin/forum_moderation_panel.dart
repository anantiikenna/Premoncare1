import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import 'admin_avatar.dart';
import 'admin_scaffold.dart';
import 'admin_shared_widgets.dart';

class ForumModerationPanel extends ConsumerStatefulWidget {
  const ForumModerationPanel({super.key});

  @override
  ConsumerState<ForumModerationPanel> createState() =>
      _ForumModerationPanelState();
}

class _ForumModerationPanelState extends ConsumerState<ForumModerationPanel> {
  bool _loading = true;
  String? _error;

  int _pendingReportsCount = 0;
  int _totalPostsCount = 0;
  int _flaggedPostsCount = 0;
  int _activeCategoriesCount = 0;

  List<Map<String, dynamic>> _pendingReports = [];
  List<Map<String, dynamic>> _recentActions = [];

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.wait([
      _fetchStats(),
      _fetchPendingReports(),
      _fetchRecentActions(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchStats() async {
    try {
      final client = Supabase.instance.client;

      final reportsRes = await client
          .from('forum_reports')
          .select('id')
          .eq('status', 'pending')
          .count();

      final postsRes = await client.from('forum_posts').select('id').count();

      final flaggedRes = await client
          .from('forum_posts')
          .select('id')
          .eq('status', 'pending')
          .count();

      final categoriesRes = await client
          .from('forum_categories')
          .select('id')
          .eq('is_active', true)
          .count();

      if (mounted) {
        setState(() {
          _pendingReportsCount = reportsRes.count;
          _totalPostsCount = postsRes.count;
          _flaggedPostsCount = flaggedRes.count;
          _activeCategoriesCount = categoriesRes.count;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load stats: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _fetchPendingReports() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('forum_reports')
          .select('''
            id, created_at, reason, status,
            post:forum_posts(id, title),
            reporter:profiles!forum_reports_reporter_id_fkey(full_name, avatar_url)
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _pendingReports = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reports: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _fetchRecentActions() async {
    try {
      final client = Supabase.instance.client;
      final reviewed = await client
          .from('forum_reports')
          .select('''
            id, created_at, reason, status, resolved_at,
            post:forum_posts(id, title),
            reporter:profiles!forum_reports_reporter_id_fkey(full_name),
            resolver:profiles!forum_reports_resolved_by_fkey(full_name)
          ''')
          .eq('status', 'reviewed')
          .order('resolved_at', ascending: false)
          .limit(10);

      final actionTaken = await client
          .from('forum_reports')
          .select('''
            id, created_at, reason, status, resolved_at,
            post:forum_posts(id, title),
            reporter:profiles!forum_reports_reporter_id_fkey(full_name),
            resolver:profiles!forum_reports_resolved_by_fkey(full_name)
          ''')
          .eq('status', 'action_taken')
          .order('resolved_at', ascending: false)
          .limit(10);

      final dismissed = await client
          .from('forum_reports')
          .select('''
            id, created_at, reason, status, resolved_at,
            post:forum_posts(id, title),
            reporter:profiles!forum_reports_reporter_id_fkey(full_name),
            resolver:profiles!forum_reports_resolved_by_fkey(full_name)
          ''')
          .eq('status', 'dismissed')
          .order('resolved_at', ascending: false)
          .limit(10);

      final all = [...reviewed, ...actionTaken, ...dismissed];
      all.sort((a, b) {
        final aDate = a['resolved_at'] as String? ?? '';
        final bDate = b['resolved_at'] as String? ?? '';
        return bDate.compareTo(aDate);
      });

      if (mounted) {
        setState(() {
          _recentActions = all.take(10).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load actions: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _dismissReport(String reportId) async {
    try {
      final client = Supabase.instance.client;
      await client
          .from('forum_reports')
          .update({
            'status': 'dismissed',
            'resolved_at': DateTime.now().toIso8601String(),
            'resolved_by': client.auth.currentUser?.id,
          })
          .eq('id', reportId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report dismissed'),
            backgroundColor: AppColors.success,
          ),
        );
        _refreshAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _takeAction(String reportId, String postId) async {
    try {
      final client = Supabase.instance.client;

      await client
          .from('forum_posts')
          .update({'status': 'rejected'})
          .eq('id', postId);

      await client
          .from('forum_reports')
          .update({
            'status': 'action_taken',
            'resolved_at': DateTime.now().toIso8601String(),
            'resolved_by': client.auth.currentUser?.id,
          })
          .eq('id', reportId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post removed and report resolved'),
            backgroundColor: AppColors.success,
          ),
        );
        _refreshAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 3,
      body: _error != null && !_loading
          ? AdminErrorState(message: _error!, onRetry: _refreshAll)
          : RefreshIndicator(
              onRefresh: _refreshAll,
              color: AppColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildRecentReports()),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildQuickActions()),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildRecentModerationActions(),
                    const SizedBox(height: 32),
                    _buildBottomBanner(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forum Moderation Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryOf(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Overview of forum activities, reports, and moderation actions.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiaryOf(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLightOf(context)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textTertiaryOf(context),
              ),
              const SizedBox(width: 8),
              Text(
                'All Time',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pending Reports',
            _pendingReportsCount.toString(),
            'Require review',
            Icons.flag_outlined,
            AppColors.error,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Flagged Posts',
            _flaggedPostsCount.toString(),
            'Awaiting moderation',
            Icons.gpp_maybe_outlined,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Posts',
            _totalPostsCount.toString(),
            'All time',
            Icons.chat_bubble_outline,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Active Categories',
            _activeCategoriesCount.toString(),
            'Forum sections',
            Icons.folder_outlined,
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightOf(context)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryOf(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReports() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Reports',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              Text(
                '${_pendingReports.length} items',
                style: TextStyle(
                  color: AppColors.textTertiaryOf(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading && _pendingReports.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_pendingReports.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.successLightOf(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'No pending reports',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._pendingReports.map((report) => _buildReportRow(report)),
        ],
      ),
    );
  }

  Widget _buildReportRow(Map<String, dynamic> report) {
    final post = report['post'] as Map<String, dynamic>?;
    final reporter = report['reporter'] as Map<String, dynamic>?;
    final reason = report['reason'] ?? 'No reason provided';
    final postTitle = post != null
        ? (post['title'] ?? 'Untitled Post')
        : 'Post deleted';
    final reporterName = reporter != null
        ? (reporter['full_name'] ?? 'Anonymous')
        : 'Unknown';
    final createdAt = report['created_at'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLightOf(context)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.errorLightOf(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.errorLightOf(context),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_outlined,
              color: AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'In post: "$postTitle"',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    AdminAvatar(
                      imageUrl: reporter?['avatar_url'] as String?,
                      name: reporterName,
                      radius: 10,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reported by $reporterName • ${_timeAgo(createdAt)}',
                      style: TextStyle(
                        color: AppColors.textTertiaryOf(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppColors.textTertiaryOf(context),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'dismiss') _dismissReport(report['id']);
              if (value == 'remove' && post != null)
                _takeAction(report['id'], post['id']);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Remove Post',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'dismiss',
                child: Row(
                  children: [
                    Icon(
                      Icons.close_outlined,
                      color: AppColors.textSecondaryOf(context),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Dismiss Report',
                      style: TextStyle(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActionItem(
            'Manage Categories',
            Icons.folder_outlined,
            AppColors.primary,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Category management coming soon'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
          ),
          _buildQuickActionItem(
            'Forum Settings',
            Icons.settings_outlined,
            AppColors.textTertiaryOf(context),
            () {
              context.push('/settings-privacy');
            },
          ),
          _buildQuickActionItem(
            'View Flagged Posts',
            Icons.gpp_maybe_outlined,
            AppColors.warning,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Flagged posts view coming soon'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
          ),
          _buildQuickActionItem(
            'User Moderation',
            Icons.person_outline,
            AppColors.info,
            () {
              context.push('/admin/user-management');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLightOf(context)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textTertiaryOf(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentModerationActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Moderation Actions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading && _recentActions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_recentActions.isEmpty)
            const AdminEmptyState(
              icon: Icons.history_rounded,
              title: 'No recent actions',
              subtitle: 'Moderation actions will appear here',
            )
          else
            ..._recentActions.map((action) => _buildActionRow(action)),
        ],
      ),
    );
  }

  Widget _buildActionRow(Map<String, dynamic> action) {
    final post = action['post'] as Map<String, dynamic>?;
    final resolver = action['resolver'] as Map<String, dynamic>?;
    final status = action['status'] ?? 'reviewed';
    final reason = action['reason'] ?? '';
    final postTitle = post != null
        ? (post['title'] ?? 'Untitled')
        : 'Post deleted';
    final resolverName = resolver != null
        ? (resolver['full_name'] ?? 'Admin')
        : 'System';
    final resolvedAt = action['resolved_at'] as String?;

    final isActionTaken = status == 'action_taken';
    final isDismissed = status == 'dismissed';
    final color = isActionTaken
        ? AppColors.error
        : (isDismissed ? AppColors.textTertiaryOf(context) : AppColors.info);
    final badge = isActionTaken
        ? 'Removed'
        : (isDismissed ? 'Dismissed' : 'Reviewed');
    final icon = isActionTaken
        ? Icons.delete_outline
        : (isDismissed ? Icons.close_outlined : Icons.check_circle_outline);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLightOf(context)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActionTaken
                      ? 'Post removed'
                      : (isDismissed ? 'Report dismissed' : 'Report reviewed'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'In post: "$postTitle"',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 12,
                  ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Reason: $reason',
                    style: TextStyle(
                      color: AppColors.textTertiaryOf(context),
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'By $resolverName • ${_timeAgo(resolvedAt)}',
                  style: TextStyle(
                    color: AppColors.textTertiaryOf(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user,
              color: AppColors.textInverse,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep the community safe and trustworthy.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your moderation helps maintain a healthy environment for everyone.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
