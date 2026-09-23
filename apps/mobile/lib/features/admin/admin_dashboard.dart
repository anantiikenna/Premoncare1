import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import 'admin_avatar.dart';
import 'admin_charts_widget.dart';
import 'admin_shared_widgets.dart';
import 'admin_scaffold.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);

    return AdminScaffold(
      selectedIndex: 0,
      body: statsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [SizedBox(height: 24), AdminStatsSkeleton()]),
        ),
        error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.errorLoadingDashboard(e))),
        data: (stats) => Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: _MeshCircle(
              color: AppColors.primary.withValues(alpha: 0.08),
              size: 500,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _MeshCircle(
              color: AppColors.info.withValues(alpha: 0.04),
              size: 300,
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminStatsProvider);
              ref.invalidate(pendingVerificationsProvider);
              ref.invalidate(pendingDisputesProvider);
              ref.invalidate(recentDoctorApplicationsProvider);
              ref.invalidate(recentTransactionsProvider);
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildHeroKPI(stats),
                  const SizedBox(height: 28),
                  _buildStatsGrid(),
                  const SizedBox(height: 32),
                  _buildSectionHeader(AppLocalizations.of(context)!.priorityAlerts),
                  const SizedBox(height: 16),
                  _buildPriorityAlerts(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader(AppLocalizations.of(context)!.analyticsOverview),
                  const SizedBox(height: 16),
                  _buildAnalyticsSection(AppColors.primary),
                  const SizedBox(height: 32),
                  const AdminChartsWidget(),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.recentDoctorApplications,
                    onSeeAll: () => context.push('/admin/doctor-verification'),
                  ),
                  const SizedBox(height: 16),
                  _buildDoctorApplications(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.recentTransactions,
                    onSeeAll: () => context.push('/admin/financial'),
                  ),
                  const SizedBox(height: 16),
                  _buildTransactions(),
                  const SizedBox(height: 32),
                  _buildSectionHeader(AppLocalizations.of(context)!.quickActions),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildHeroKPI(Map<String, dynamic> stats) {
    final revenue = stats['totalRevenue'] as num;
    final formattedRevenue = revenue >= 1000000
        ? '₦${(revenue / 1000000).toStringAsFixed(1)}M'
        : revenue >= 1000
        ? '₦${(revenue / 1000).toStringAsFixed(1)}K'
        : '₦${revenue.toStringAsFixed(0)}';
    final todayAppts = stats['todayAppointments'] as int? ?? 0;
    final verifiedDoctors = stats['verifiedDoctors'] as int? ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.info,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
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
                    child: const Icon(
                      Icons.shield_rounded,
                      color: AppColors.textInverse,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, color: AppColors.textInverse, size: 6),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.systemsOnline,
                          style: const TextStyle(
                            color: AppColors.textInverse,
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
              const SizedBox(height: 24),
              Text(
                formattedRevenue,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textInverse,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.totalPlatformRevenue,
                style: TextStyle(
                  color: AppColors.textInverse.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _heroChip(
                    Icons.calendar_today_rounded,
                    AppLocalizations.of(context)!.appointmentsTodayCount(todayAppts),
                  ),
                  const SizedBox(width: 12),
                  _heroChip(
                    Icons.medical_services_rounded,
                    AppLocalizations.of(context)!.verifiedDoctorsCount(verifiedDoctors),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textInverse, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textInverse,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.5,
          children: [
            AdminStatCard(
              title: AppLocalizations.of(context)!.totalUsers,
              value: '${stats['totalUsers']}',
              icon: Icons.people_outline_rounded,
              color: AppColors.info,
            ),
            AdminStatCard(
              title: AppLocalizations.of(context)!.verifiedDoctors,
              value: '${stats['verifiedDoctors']}',
              icon: Icons.medical_services_outlined,
              color: AppColors.success,
            ),
            AdminStatCard(
              title: AppLocalizations.of(context)!.appointmentsToday,
              value: '${stats['todayAppointments']}',
              icon: Icons.calendar_today_outlined,
              color: AppColors.primary,
            ),
            AdminStatCard(
              title: AppLocalizations.of(context)!.totalRevenue,
              value: formattedRevenue,
              icon: Icons.currency_exchange_rounded,
              color: AppColors.warning,
            ),
          ],
        );
      },
      loading: () => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.5,
        children: List.generate(
          4,
          (_) => AdminStatCard(
            title: '',
            value: '...',
            icon: Icons.hourglass_empty_rounded,
            color: AppColors.textTertiaryOf(context),
          ),
        ),
      ),
      error: (_, _) => Center(child: Text(AppLocalizations.of(context)!.failedToLoadStats)),
    );
  }

  Widget _buildPriorityAlerts(BuildContext context) {
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
            title: AppLocalizations.of(context)!.doctorVerifications,
            subtitle: AppLocalizations.of(context)!.pendingReview,
            btnLabel: AppLocalizations.of(context)!.reviewNow,
            color: AppColors.warning,
            icon: Icons.verified_user_rounded,
            hasUrgency: verificationsCount > 0,
            onTap: () => context.push('/admin/doctor-verification'),
          ),
          const SizedBox(width: 14),
          _AlertCard(
            count: '$disputesCount',
            title: AppLocalizations.of(context)!.paymentDisputes,
            subtitle: AppLocalizations.of(context)!.needsResolution,
            btnLabel: AppLocalizations.of(context)!.resolveNow,
            color: AppColors.error,
            icon: Icons.gavel_rounded,
            hasUrgency: disputesCount > 0,
            onTap: () => context.push('/admin/disputes'),
          ),
          const SizedBox(width: 14),
          _AlertCard(
            count: '—',
            title: AppLocalizations.of(context)!.emergencyQueueLabel,
            subtitle: AppLocalizations.of(context)!.liveMonitoring,
            btnLabel: AppLocalizations.of(context)!.openQueue,
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
        final cancelledAppointments =
            stats['cancelledAppointments'] as int? ?? 0;
        final todayAppointments = stats['todayAppointments'] as int? ?? 0;
        final completionRate = totalAppointments > 0
            ? (completedAppointments / totalAppointments)
            : 0.0;
        final completedPct = totalAppointments > 0
            ? ((completedAppointments / totalAppointments) * 100).round()
            : 0;
        final cancelledPct = totalAppointments > 0
            ? ((cancelledAppointments / totalAppointments) * 100).round()
            : 0;
        final upcomingPct = (100 - completedPct - cancelledPct).clamp(0, 100);

        return Row(
          children: [
            Expanded(
              flex: 4,
              child: _buildAnalyticsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.revenueOverview,
                      style: AppTypography.labelMediumOf(context),
                    ),
                    const SizedBox(height: 6),
                    Text(formattedRevenue, style: AppTypography.h3Of(context)),
                    const SizedBox(height: 20),
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
                        Text(AppLocalizations.of(context)!.todayLabel, style: AppTypography.captionOf(context)),
                        Text(
                          AppLocalizations.of(context)!.appointmentsCount(todayAppointments),
                          style: AppTypography.captionOf(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: _buildAnalyticsCard(
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.appointmentsLabel,
                      textAlign: TextAlign.center,
                      style: AppTypography.labelMediumOf(context),
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
                              style: AppTypography.h3Of(context),
                            ),
                            Text(
                              AppLocalizations.of(context)!.totalLabel,
                              style: AppTypography.captionOf(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildAnalyticsLegend(
                      AppLocalizations.of(context)!.completedStatusLabel,
                      '$completedPct%',
                      primaryColor,
                    ),
                    _buildAnalyticsLegend(
                      AppLocalizations.of(context)!.upcomingTab,
                      '$upcomingPct%',
                      AppColors.info,
                    ),
                    _buildAnalyticsLegend(
                      AppLocalizations.of(context)!.cancelledLabel,
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
          const SizedBox(width: 14),
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

  Widget _buildAnalyticsCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
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
              style: AppTypography.bodySmallOf(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value, style: AppTypography.labelMediumOf(context)),
        ],
      ),
    );
  }

  Widget _buildDoctorApplications(BuildContext context) {
    final appsAsync = ref.watch(recentDoctorApplicationsProvider);
    return appsAsync.when(
      data: (apps) {
        if (apps.isEmpty) {
          return AdminEmptyState(
            icon: Icons.person_off_outlined,
            title: AppLocalizations.of(context)!.noPendingApplications,
            subtitle: AppLocalizations.of(context)!.allApplicationsReviewed,
          );
        }
        return Column(
          children: apps.map((app) {
            final name = app['full_name'] as String? ?? 'Unknown';
            final specialty = app['specialty'] as String? ?? 'General';
            final createdAt = app['created_at'] as String?;
            final timeAgo = createdAt != null
                ? _timeAgo(DateTime.parse(createdAt))
                : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ApplicationTile(
                doctorId: app['id'] as String? ?? '',
                name: name,
                specialty: specialty,
                time: timeAgo,
                avatarUrl: app['avatar_url'] as String?,
                onReview: () => context.push(
                  '/admin/doctor-verification?doctorId=${app['id']}',
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, _) =>
          AdminErrorState(message: AppLocalizations.of(context)!.failedToLoadApplications),
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
          return AdminEmptyState(
            icon: Icons.receipt_long_outlined,
            title: AppLocalizations.of(context)!.noRecentTransactions,
            subtitle:
                AppLocalizations.of(context)!.transactionsWillAppear,
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
                amount: '₦${amount.toStringAsFixed(0)}',
                sub: AppLocalizations.of(context)!.paymentStatus(status.toUpperCase()),
                date: timeAgo,
                status: isCompleted
                    ? AppLocalizations.of(context)!.completedStatusLabel
                    : isRefunded
                    ? AppLocalizations.of(context)!.refundedLabel
                    : AppLocalizations.of(context)!.pendingLabel,
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
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, _) =>
          AdminErrorState(message: AppLocalizations.of(context)!.failedToLoadTransactions),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.22,
      children: [
        _QuickActionItem(
          icon: Icons.verified_user_rounded,
          label: AppLocalizations.of(context)!.verifyDoctors,
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin/doctor-verification'),
        ),
        _QuickActionItem(
          icon: Icons.groups_rounded,
          label: AppLocalizations.of(context)!.manageUsers,
          gradient: LinearGradient(
            colors: [AppColors.info, AppColors.info.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin/user-management'),
        ),
        _QuickActionItem(
          icon: Icons.campaign_rounded,
          label: AppLocalizations.of(context)!.broadcast,
          gradient: LinearGradient(
            colors: [
              AppColors.success,
              AppColors.success.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin/notifications'),
        ),
        _QuickActionItem(
          icon: Icons.description_rounded,
          label: AppLocalizations.of(context)!.auditLogs,
          gradient: LinearGradient(
            colors: [
              AppColors.warning,
              AppColors.warning.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin/audit-timeline'),
        ),
        _QuickActionItem(
          icon: Icons.account_balance_wallet_rounded,
           label: AppLocalizations.of(context)!.payments,
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin/financial'),
        ),
        _QuickActionItem(
          icon: Icons.gavel_rounded,
          label: AppLocalizations.of(context)!.disputesLabel,
          gradient: LinearGradient(
            colors: [AppColors.error, AppColors.error.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => context.push('/admin/disputes'),
        ),
        _QuickActionItem(
          icon: Icons.forum_rounded,
          label: AppLocalizations.of(context)!.forumMod,
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
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.textSecondaryOf(context),
            letterSpacing: 1.5,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              AppLocalizations.of(context)!.viewAll,
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

class _AlertCardState extends State<_AlertCard>
    with SingleTickerProviderStateMixin {
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
        borderRadius: BorderRadius.circular(24),
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
                        color: widget.color.withValues(
                          alpha: _pulseAnimation.value,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(
                              alpha: _pulseAnimation.value * 0.5,
                            ),
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
          Text(widget.subtitle, style: AppTypography.captionOf(context)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: widget.onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: AppColors.textInverse,
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
  final String doctorId;
  final String name;
  final String specialty;
  final String time;
  final String? avatarUrl;
  final VoidCallback onReview;

  const _ApplicationTile({
    required this.doctorId,
    required this.name,
    required this.specialty,
    required this.time,
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
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$specialty \u2022 $time',
                  style: AppTypography.captionOf(context),
                ),
              ],
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => context.push('/admin/doctor-verification?doctorId=$doctorId'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.successLightOf(context),
                  foregroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.approveLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: onReview,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.borderLightOf(context),
                  foregroundColor: AppColors.textSecondaryOf(context),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.reviewLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
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
  final String amount;
  final String sub;
  final String date;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconBg;

  const _TransactionTile({
    required this.amount,
    required this.sub,
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
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
                  amount,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$sub \u2022 $date',
                  style: AppTypography.captionOf(context),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
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
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiaryOf(context),
          ),
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
              child: Icon(icon, color: AppColors.textInverse, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textInverse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeshCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _MeshCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)],
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
