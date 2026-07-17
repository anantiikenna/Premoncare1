import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/app_colors.dart';
import 'admin_avatar.dart';
import 'admin_charts_widget.dart';
import 'admin_shared_widgets.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SizedBox(height: 24),
            AdminStatsSkeleton(),
          ],
        ),
      ),
      error: (e, _) => Center(child: Text('Failed to load dashboard: $e')),
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 32),
            _buildSectionHeader(
              'Priority Alerts',
              onSeeAll: () => context.push('/admin/doctor-verification'),
            ),
            const SizedBox(height: 16),
            _buildPriorityAlerts(context, AppColors.primary),
            const SizedBox(height: 32),
            _buildSectionHeader('Analytics Overview'),
            const SizedBox(height: 16),
            _buildAnalyticsSection(AppColors.primary),
            const SizedBox(height: 32),
            const AdminChartsWidget(),
            const SizedBox(height: 32),
            _buildSectionHeader(
              'Recent Doctor Applications',
              onSeeAll: () => context.push('/admin/doctor-verification'),
            ),
            const SizedBox(height: 16),
            _buildDoctorApplications(context),
            const SizedBox(height: 32),
            _buildSectionHeader(
              'Recent Transactions',
              onSeeAll: () => context.push('/admin/financial'),
            ),
            const SizedBox(height: 16),
            _buildTransactions(),
            const SizedBox(height: 32),
            _buildSectionHeader('Quick Actions'),
            const SizedBox(height: 16),
            _buildQuickActions(context, AppColors.primary),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 6),
                    SizedBox(width: 6),
                    Text(
                      'Systems Online',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '$greeting, Admin',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Platform operations are running smoothly.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final statsAsync = ref.watch(adminStatsProvider);
    return statsAsync.when(
      data: (stats) {
        final revenue = stats['totalRevenue'] as num;
        final formattedRevenue = revenue >= 1000000
            ? '₦${(revenue / 1000000).toStringAsFixed(1)}M'
            : revenue >= 1000
            ? '₦${(revenue / 1000).toStringAsFixed(1)}K'
            : '₦${revenue.toStringAsFixed(0)}';
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _StatCard(
              title: 'Total Users',
              value: '${stats['totalUsers']}',
              icon: Icons.people_outline_rounded,
              iconBgColor: AppColors.infoLightOf(context),
              iconColor: AppColors.info,
              trend: '+12%',
              isTrendUp: true,
            ),
            _StatCard(
              title: 'Verified Doctors',
              value: '${stats['verifiedDoctors']}',
              icon: Icons.medical_services_outlined,
              iconBgColor: AppColors.successLightOf(context),
              iconColor: AppColors.success,
              trend: '+5%',
              isTrendUp: true,
            ),
            _StatCard(
              title: 'Appointments Today',
              value: '${stats['todayAppointments']}',
              icon: Icons.calendar_today_outlined,
              iconBgColor: AppColors.primary.withValues(alpha: 0.1),
              iconColor: AppColors.primary,
              trend: stats['todayAppointments'] > 0 ? '+${stats['todayAppointments']}' : '0',
              isTrendUp: true,
            ),
            _StatCard(
              title: 'Total Revenue',
              value: formattedRevenue,
              icon: Icons.currency_exchange_rounded,
              iconBgColor: AppColors.warningLightOf(context),
              iconColor: AppColors.warning,
              trend: '+18%',
              isTrendUp: true,
            ),
          ],
        );
      },
      loading: () => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.4,
        children: List.generate(
          4,
          (_) => const _StatCard(
            title: '',
            value: '...',
            icon: Icons.hourglass_empty_rounded,
            iconBgColor: AppColors.borderLight,
            iconColor: AppColors.textTertiary,
          ),
        ),
      ),
      error: (_, _) => const Center(child: Text('Failed to load stats')),
    );
  }

  Widget _buildPriorityAlerts(BuildContext context, Color primaryColor) {
    final verificationsAsync = ref.watch(pendingVerificationsProvider);
    final disputesAsync = ref.watch(pendingDisputesProvider);

    final verificationsCount =
        verificationsAsync.whenOrNull(data: (v) => v) ?? 0;
    final disputesCount = disputesAsync.whenOrNull(data: (v) => v) ?? 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AlertCard(
            count: '$verificationsCount',
            title: 'Doctor Verifications',
            subtitle: 'Pending review',
            btnLabel: 'Review Now',
            color: AppColors.warning,
            icon: Icons.verified_user_rounded,
            hasUrgency: verificationsCount > 0,
            onTap: () => context.push('/admin/doctor-verification'),
          ),
          const SizedBox(width: 14),
          _AlertCard(
            count: '$disputesCount',
            title: 'Payment Disputes',
            subtitle: 'Needs resolution',
            btnLabel: 'Resolve Now',
            color: AppColors.error,
            icon: Icons.gavel_rounded,
            hasUrgency: disputesCount > 0,
            onTap: () => context.push('/admin/disputes'),
          ),
          const SizedBox(width: 14),
          _AlertCard(
            count: '—',
            title: 'Emergency Queue',
            subtitle: 'Live monitoring',
            btnLabel: 'Open Queue',
            color: AppColors.info,
            icon: Icons.emergency_rounded,
            hasUrgency: false,
            onTap: () => context.push('/admin/emergency-queue'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(Color primaryColor) {
    final statsAsync = ref.watch(adminStatsProvider);
    return statsAsync.when(
      data: (stats) {
        final revenue = stats['totalRevenue'] as num;
        final formattedRevenue = revenue >= 1000000
            ? '₦${(revenue / 1000000).toStringAsFixed(1)}M'
            : revenue >= 1000
            ? '₦${(revenue / 1000).toStringAsFixed(1)}K'
            : '₦${revenue.toStringAsFixed(0)}';
        final totalAppointments = stats['totalAppointments'] as int? ?? 0;
        final completedAppointments =
            stats['completedAppointments'] as int? ?? 0;
        final todayAppointments = stats['todayAppointments'] as int? ?? 0;
        final completionRate = totalAppointments > 0
            ? (completedAppointments / totalAppointments)
            : 0.0;
        final completedPct = totalAppointments > 0
            ? ((completedAppointments / totalAppointments) * 100).round()
            : 0;
        final upcomingPct = totalAppointments > 0
            ? (((totalAppointments - completedAppointments) * 0.7) /
                      totalAppointments *
                      100)
                  .round()
            : 0;
        final cancelledPct = (100 - completedPct - upcomingPct).clamp(0, 100);

        return Row(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderLightOf(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Revenue Overview',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedRevenue,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _LineChartPainter(primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiaryOf(context),
                          ),
                        ),
                        Text(
                          '$todayAppointments appointments',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiaryOf(context),
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
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderLightOf(context)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Appointments Overview',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: CircularProgressIndicator(
                            value: completionRate.clamp(0.0, 1.0),
                            strokeWidth: 10,
                            backgroundColor: AppColors.borderLightOf(context),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '$totalAppointments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textTertiaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildAnalyticsLegend(
                      'Completed',
                      '$completedPct%',
                      primaryColor,
                    ),
                    _buildAnalyticsLegend(
                      'Upcoming',
                      '$upcomingPct%',
                      AppColors.info,
                    ),
                    _buildAnalyticsLegend(
                      'Cancelled',
                      '$cancelledPct%',
                      AppColors.warning,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildAnalyticsLegend(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryOf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textPrimaryOf(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorApplications(BuildContext context) {
    final appsAsync = ref.watch(recentDoctorApplicationsProvider);
    return appsAsync.when(
      data: (apps) {
        if (apps.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No pending applications',
                style: TextStyle(color: AppColors.textTertiaryOf(context)),
              ),
            ),
          );
        }
        return Column(
          children: apps.map((app) {
            final name = app['full_name'] as String? ?? 'Unknown';
            final specialty = app['specialty'] as String? ?? 'General';
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
            final createdAt = app['created_at'] as String?;
            final timeAgo = createdAt != null
                ? _timeAgo(DateTime.parse(createdAt))
                : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ApplicationTile(
                name: name,
                specialty: specialty,
                time: timeAgo,
                initial: initial,
                avatarUrl: app['avatar_url'] as String?,
                onReview: () => context.push('/admin/doctor-verification'),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Failed to load applications')),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildTransactions() {
    final txAsync = ref.watch(recentTransactionsProvider);
    return txAsync.when(
      data: (txs) {
        if (txs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No recent transactions',
                style: TextStyle(color: AppColors.textTertiaryOf(context)),
              ),
            ),
          );
        }
        return Column(
          children: txs.map((tx) {
            final amount = (tx['amount'] as num?) ?? 0;
            final status = tx['status'] as String? ?? 'pending';
            final createdAt = tx['created_at'] as String?;
            final timeAgo = createdAt != null
                ? _timeAgo(DateTime.parse(createdAt))
                : '';
            final isCompleted = status == 'approved';
            final isRefunded = status == 'rejected';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TransactionTile(
                name: 'Transaction',
                sub: 'Payment ${status.toUpperCase()}',
                amount: '₦${amount.toStringAsFixed(0)}',
                date: timeAgo,
                status: isCompleted
                    ? 'Completed'
                    : isRefunded
                    ? 'Refunded'
                    : 'Pending',
                statusColor: isCompleted
                    ? AppColors.success
                    : isRefunded
                    ? AppColors.error
                    : AppColors.warning,
                icon: isCompleted
                    ? Icons.payments_outlined
                    : isRefunded
                    ? Icons.replay_circle_filled_rounded
                    : Icons.pending_outlined,
                iconBg: isCompleted
                    ? AppColors.successLightOf(context)
                    : isRefunded
                    ? AppColors.errorLightOf(context)
                    : AppColors.warningLightOf(context),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Failed to load transactions')),
    );
  }

  Widget _buildQuickActions(BuildContext context, Color primaryColor) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        _QuickActionItem(
          icon: Icons.verified_user_rounded,
          label: 'Verify Doctors',
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin/doctor-verification'),
        ),
        _QuickActionItem(
          icon: Icons.groups_rounded,
          label: 'Manage Users',
          gradient: LinearGradient(
            colors: [AppColors.info, AppColors.info.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin/user-management'),
        ),
        _QuickActionItem(
          icon: Icons.campaign_rounded,
          label: 'Broadcast',
          gradient: LinearGradient(
            colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin/notifications'),
        ),
        _QuickActionItem(
          icon: Icons.description_rounded,
          label: 'Audit Logs',
          gradient: LinearGradient(
            colors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin/audit-timeline'),
        ),
        _QuickActionItem(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Payments',
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin/financial'),
        ),
        _QuickActionItem(
          icon: Icons.gavel_rounded,
          label: 'Disputes',
          gradient: LinearGradient(
            colors: [AppColors.error, AppColors.error.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin/disputes'),
        ),
        _QuickActionItem(
          icon: Icons.forum_rounded,
          label: 'Forum Mod',
          gradient: LinearGradient(
            colors: [AppColors.info, AppColors.info.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin/forum-moderation'),
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
            child: Text(
              'View All',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String? trend;
  final bool isTrendUp;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    this.trend,
    this.isTrendUp = true,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isTrendUp
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTrendUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 10,
                        color: isTrendUp ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isTrendUp ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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
                  fontSize: 11,
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

class _AlertCard extends StatefulWidget {
  final String count;
  final String title;
  final String subtitle;
  final String btnLabel;
  final Color color;
  final IconData icon;
  final bool hasUrgency;
  final VoidCallback? onTap;

  const _AlertCard({
    required this.count,
    required this.title,
    required this.subtitle,
    required this.btnLabel,
    required this.color,
    required this.icon,
    this.hasUrgency = false,
    this.onTap,
  });

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              if (widget.hasUrgency) ...[
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: _pulseAnimation.value),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: _pulseAnimation.value * 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const Spacer(),
              Text(
                widget.count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: widget.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiaryOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: widget.onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.btnLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  final String name;
  final String specialty;
  final String time;
  final String initial;
  final String? avatarUrl;
  final VoidCallback onReview;

  const _ApplicationTile({
    required this.name,
    required this.specialty,
    required this.time,
    required this.initial,
    this.avatarUrl,
    required this.onReview,
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
      child: Row(
        children: [
          AdminAvatar(imageUrl: avatarUrl, name: name, radius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$specialty • Submitted $time',
                  style: TextStyle(
                    color: AppColors.textTertiaryOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => context.push('/admin/doctor-verification'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.successLightOf(context),
                  foregroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Approve',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onReview,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.borderLightOf(context),
                  foregroundColor: AppColors.textSecondaryOf(context),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Review',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String name;
  final String sub;
  final String amount;
  final String date;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconBg;

  const _TransactionTile({
    required this.name,
    required this.sub,
    required this.amount,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.iconBg,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.textPrimaryOf(context),
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
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback? onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final Color color;
  final Color dotInnerColor;
  _LineChartPainter(this.color) : dotInnerColor = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.6,
      size.width * 0.3,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.9,
      size.width * 0.6,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.3,
      size.width,
      size.height * 0.1,
    );

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotPaintInner = Paint()
      ..color = dotInnerColor
      ..style = PaintingStyle.fill;

    _drawDot(
      canvas,
      Offset(size.width * 0.3, size.height * 0.7),
      dotPaint,
      dotPaintInner,
    );
    _drawDot(
      canvas,
      Offset(size.width * 0.6, size.height * 0.4),
      dotPaint,
      dotPaintInner,
    );
    _drawDot(
      canvas,
      Offset(size.width, size.height * 0.1),
      dotPaint,
      dotPaintInner,
    );
  }

  void _drawDot(Canvas canvas, Offset offset, Paint outer, Paint inner) {
    canvas.drawCircle(offset, 5, outer);
    canvas.drawCircle(offset, 3, inner);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
