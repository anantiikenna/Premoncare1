import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);

    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF0F62FE)),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildWelcomeHeader(),
                const SizedBox(height: 24),
                _buildStatsGrid(),
                const SizedBox(height: 32),
                _buildSectionHeader('Priority Alerts', onSeeAll: () => context.push('/admin/doctor-verification')),
                const SizedBox(height: 16),
                _buildPriorityAlerts(context, primaryColor),
                const SizedBox(height: 32),
                _buildSectionHeader('Analytics Overview'),
                const SizedBox(height: 16),
                _buildAnalyticsSection(primaryColor),
                const SizedBox(height: 32),
                _buildSectionHeader('Recent Doctor Applications', onSeeAll: () => context.push('/admin/doctor-verification')),
                const SizedBox(height: 16),
                _buildDoctorApplications(context),
                const SizedBox(height: 32),
                _buildSectionHeader('Recent Transactions', onSeeAll: () => context.push('/admin/financial')),
                const SizedBox(height: 16),
                _buildTransactions(),
                const SizedBox(height: 32),
                _buildSectionHeader('Quick Actions'),
                const SizedBox(height: 16),
                _buildQuickActions(context, primaryColor),
                const SizedBox(height: 40),
              ],
            ),
          );
  }

  Widget _buildWelcomeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Welcome back, Admin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                SizedBox(width: 8),
                Text('👋', style: TextStyle(fontSize: 24)),
              ],
            ),
            SizedBox(height: 4),
            Text('System activity is running smoothly.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
              SizedBox(width: 8),
              Text('All systems operational', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
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
              iconBgColor: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF3B82F6),
            ),
            _StatCard(
              title: 'Verified Doctors',
              value: '${stats['verifiedDoctors']}',
              icon: Icons.medical_services_outlined,
              iconBgColor: const Color(0xFFECFDF5),
              iconColor: const Color(0xFF10B981),
            ),
            _StatCard(
              title: 'Appointments Today',
              value: '${stats['todayAppointments']}',
              icon: Icons.calendar_today_outlined,
              iconBgColor: const Color(0xFFF5F3FF),
              iconColor: const Color(0xFF8B5CF6),
            ),
            _StatCard(
              title: 'Total Revenue',
              value: formattedRevenue,
              icon: Icons.currency_exchange_rounded,
              iconBgColor: const Color(0xFFFFF7ED),
              iconColor: const Color(0xFFF59E0B),
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
        children: List.generate(4, (_) => const _StatCard(
          title: '',
          value: '...',
          icon: Icons.hourglass_empty_rounded,
          iconBgColor: Color(0xFFF1F5F9),
          iconColor: Color(0xFF94A3B8),
        )),
      ),
      error: (_, _) => const Center(child: Text('Failed to load stats')),
    );
  }

  Widget _buildPriorityAlerts(BuildContext context, Color primaryColor) {
    final verificationsAsync = ref.watch(pendingVerificationsProvider);
    final disputesAsync = ref.watch(pendingDisputesProvider);

    final verificationsCount = verificationsAsync.whenOrNull(data: (v) => v) ?? 0;
    final disputesCount = disputesAsync.whenOrNull(data: (v) => v) ?? 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AlertCard(
            count: '$verificationsCount',
            title: 'Pending Doctor Verifications',
            btnLabel: 'Review',
            color: const Color(0xFFF59E0B),
            icon: Icons.warning_amber_rounded,
            onTap: () => context.push('/admin/doctor-verification'),
          ),
          const SizedBox(width: 16),
          _AlertCard(
            count: '$disputesCount',
            title: 'Payment Disputes',
            btnLabel: 'Resolve',
            color: const Color(0xFFEF4444),
            icon: Icons.error_outline_rounded,
            onTap: () => context.push('/admin/disputes'),
          ),
          const SizedBox(width: 16),
          _AlertCard(
            count: '—',
            title: 'Emergency Queue',
            btnLabel: 'Open Queue',
            color: const Color(0xFF3B82F6),
            icon: Icons.access_time_rounded,
            onTap: () => context.push('/admin/emergency-queue'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Revenue Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        SizedBox(height: 4),
                        Text('₦28,540,600', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981), size: 12),
                          SizedBox(width: 4),
                          Text('18.7%', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Placeholder for Chart
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CustomPaint(painter: _LineChartPainter(primaryColor)),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Jun 8', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    Text('Jun 10', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    Text('Jun 12', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    Text('Jun 14', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                const Text('Appointments Overview', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(
                        value: 0.7,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    const Column(
                      children: [
                        Text('432', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                        Text('Total', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildAnalyticsLegend('Completed', '58%', primaryColor),
                _buildAnalyticsLegend('Upcoming', '28%', const Color(0xFF22D3EE)),
                _buildAnalyticsLegend('Cancelled', '9%', const Color(0xFFF59E0B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsLegend(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDoctorApplications(BuildContext context) {
    final appsAsync = ref.watch(recentDoctorApplicationsProvider);
    return appsAsync.when(
      data: (apps) {
        if (apps.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No pending applications', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
          );
        }
        return Column(
          children: apps.map((app) {
            final name = app['full_name'] as String? ?? 'Unknown';
            final specialty = app['specialty'] as String? ?? 'General';
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
            final createdAt = app['created_at'] as String?;
            final timeAgo = createdAt != null ? _timeAgo(DateTime.parse(createdAt)) : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ApplicationTile(
                name: name,
                specialty: specialty,
                time: timeAgo,
                initial: initial,
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No recent transactions', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
          );
        }
        return Column(
          children: txs.map((tx) {
            final amount = (tx['amount'] as num?) ?? 0;
            final status = tx['status'] as String? ?? 'pending';
            final createdAt = tx['created_at'] as String?;
            final timeAgo = createdAt != null ? _timeAgo(DateTime.parse(createdAt)) : '';
            final isCompleted = status == 'approved';
            final isRefunded = status == 'rejected';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TransactionTile(
                name: 'Transaction',
                sub: 'Payment ${status.toUpperCase()}',
                amount: '₦${amount.toStringAsFixed(0)}',
                date: timeAgo,
                status: isCompleted ? 'Completed' : isRefunded ? 'Refunded' : 'Pending',
                statusColor: isCompleted
                    ? const Color(0xFF10B981)
                    : isRefunded
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
                icon: isCompleted
                    ? Icons.payments_outlined
                    : isRefunded
                        ? Icons.replay_circle_filled_rounded
                        : Icons.pending_outlined,
                iconBg: isCompleted
                    ? const Color(0xFFECFDF5)
                    : isRefunded
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFFFF7ED),
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
      childAspectRatio: 1.1,
      children: [
        _QuickActionItem(icon: Icons.verified_user_rounded, label: 'Verify Doctors', color: primaryColor, onTap: () => context.push('/admin/doctor-verification')),
        _QuickActionItem(icon: Icons.groups_rounded, label: 'Manage Users', color: const Color(0xFF8B5CF6), onTap: () => context.push('/admin/user-management')),
        _QuickActionItem(icon: Icons.campaign_rounded, label: 'Broadcast Notice', color: const Color(0xFF10B981), onTap: () => context.push('/admin/notifications')),
        _QuickActionItem(icon: Icons.description_rounded, label: 'Audit Logs', color: const Color(0xFFF59E0B), onTap: () => context.push('/admin/audit-timeline')),
        _QuickActionItem(icon: Icons.account_balance_wallet_rounded, label: 'Payments', color: const Color(0xFF22D3EE), onTap: () => context.push('/admin/financial')),
        _QuickActionItem(icon: Icons.gavel_rounded, label: 'Disputes', color: const Color(0xFFEF4444), onTap: () => context.push('/admin/disputes')),
        _QuickActionItem(icon: Icons.forum_rounded, label: 'Forum Mod', color: const Color(0xFFE879F9), onTap: () => context.push('/admin/forum-moderation')),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('View All', style: TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.w700, fontSize: 13)),
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

  const _StatCard({required this.title, required this.value, required this.icon, required this.iconBgColor, required this.iconColor});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 20)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String count;
  final String title;
  final String btnLabel;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _AlertCard({required this.count, required this.title, required this.btnLabel, required this.color, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
                elevation: 0,
                side: BorderSide(color: color.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(btnLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
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
  final VoidCallback onReview;

  const _ApplicationTile({required this.name, required this.specialty, required this.time, required this.initial, required this.onReview});

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
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.1),
            child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F62FE))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text('$specialty • Submitted $time', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => context.push('/admin/doctor-verification'),
                style: TextButton.styleFrom(backgroundColor: const Color(0xFFECFDF5), foregroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onReview,
                style: TextButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), foregroundColor: const Color(0xFF64748B), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Review', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
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

  const _TransactionTile({required this.name, required this.sub, required this.amount, required this.date, required this.status, required this.statusColor, required this.icon, required this.iconBg});

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
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: statusColor, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionItem({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final Color color;
  _LineChartPainter(this.color);

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
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.6, size.width * 0.3, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.9, size.width * 0.6, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.3, size.width, size.height * 0.1);

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw dots
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    final dotPaintInner = Paint()..color = Colors.white..style = PaintingStyle.fill;
    
    _drawDot(canvas, Offset(size.width * 0.3, size.height * 0.7), dotPaint, dotPaintInner);
    _drawDot(canvas, Offset(size.width * 0.6, size.height * 0.4), dotPaint, dotPaintInner);
    _drawDot(canvas, Offset(size.width, size.height * 0.1), dotPaint, dotPaintInner);
  }

  void _drawDot(Canvas canvas, Offset offset, Paint outer, Paint inner) {
    canvas.drawCircle(offset, 5, outer);
    canvas.drawCircle(offset, 3, inner);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
