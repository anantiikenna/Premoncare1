import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import 'admin_scaffold.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _selectedRange = 'This Month';
  final List<String> _ranges = [
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
  ];

  bool _isLoading = true;
  String? _error;

  int _totalUsers = 0;
  int _totalDoctors = 0;
  int _totalAppointments = 0;
  double _totalRevenue = 0;

  double _usersGrowthPct = 0;
  double _doctorsGrowthPct = 0;
  double _appointmentsGrowthPct = 0;
  double _revenueGrowthPct = 0;

  int _completedAppointments = 0;
  int _cancelledAppointments = 0;
  int _rescheduledAppointments = 0;

  List<_DoctorStat> _topDoctors = [];

  int _forumPostsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  ({DateTime start, DateTime end, DateTime prevStart, DateTime prevEnd})
  _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_selectedRange) {
      case 'Today':
        return (
          start: today,
          end: today.add(const Duration(days: 1)),
          prevStart: today.subtract(const Duration(days: 1)),
          prevEnd: today,
        );
      case 'This Week':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (
          start: weekStart,
          end: weekStart.add(const Duration(days: 7)),
          prevStart: weekStart.subtract(const Duration(days: 7)),
          prevEnd: weekStart,
        );
      case 'This Quarter':
        final quarter = ((now.month - 1) ~/ 3);
        final quarterStart = DateTime(now.year, quarter * 3 + 1, 1);
        final quarterEnd = DateTime(now.year, quarter * 3 + 4, 1);
        final prevQuarterStart = DateTime(now.year, quarter * 3 - 2, 1);
        return (
          start: quarterStart,
          end: quarterEnd,
          prevStart: prevQuarterStart,
          prevEnd: quarterStart,
        );
      case 'This Year':
        return (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year + 1, 1, 1),
          prevStart: DateTime(now.year - 1, 1, 1),
          prevEnd: DateTime(now.year, 1, 1),
        );
      case 'This Month':
      default:
        final monthStart = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        final prevMonthStart = DateTime(now.year, now.month - 1, 1);
        return (
          start: monthStart,
          end: nextMonth,
          prevStart: prevMonthStart,
          prevEnd: monthStart,
        );
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final range = _getDateRange();

      final results = await Future.wait([
        supabase
            .from('profiles')
            .select('id')
            .gte('created_at', range.start.toIso8601String())
            .lt('created_at', range.end.toIso8601String()),
        supabase
            .from('profiles')
            .select('id')
            .gte('created_at', range.prevStart.toIso8601String())
            .lt('created_at', range.prevEnd.toIso8601String()),
        supabase
            .from('profiles')
            .select('id')
            .eq('role', 'doctor')
            .gte('created_at', range.start.toIso8601String())
            .lt('created_at', range.end.toIso8601String()),
        supabase
            .from('profiles')
            .select('id')
            .eq('role', 'doctor')
            .gte('created_at', range.prevStart.toIso8601String())
            .lt('created_at', range.prevEnd.toIso8601String()),
        supabase
            .from('appointments')
            .select('id, status, total_amount')
            .gte('created_at', range.start.toIso8601String())
            .lt('created_at', range.end.toIso8601String()),
        supabase
            .from('appointments')
            .select('id, total_amount')
            .gte('created_at', range.prevStart.toIso8601String())
            .lt('created_at', range.prevEnd.toIso8601String()),
        supabase
            .from('payments')
            .select('amount')
            .eq('status', 'completed')
            .gte('created_at', range.start.toIso8601String())
            .lt('created_at', range.end.toIso8601String()),
        supabase
            .from('payments')
            .select('amount')
            .eq('status', 'completed')
            .gte('created_at', range.prevStart.toIso8601String())
            .lt('created_at', range.prevEnd.toIso8601String()),
        supabase
            .from('appointments')
            .select('id, doctor_id')
            .gte('created_at', range.start.toIso8601String())
            .lt('created_at', range.end.toIso8601String()),
        supabase
            .from('forum_posts')
            .select('id')
            .gte('created_at', range.start.toIso8601String())
            .lt('created_at', range.end.toIso8601String()),
      ]);

      final currentUsers = (results[0] as List).length;
      final prevUsers = (results[1] as List).length;
      final currentDoctors = (results[2] as List).length;
      final prevDoctors = (results[3] as List).length;
      final appointments = results[4] as List;
      final prevAppointments = results[5] as List;
      final payments = results[6] as List;
      final prevPayments = results[7] as List;
      final doctorAppointments = results[8] as List;
      final forumPosts = (results[9] as List).length;

      final totalCurrentAppointments = appointments.length;
      final totalPrevAppointments = prevAppointments.length;
      final completed = appointments
          .where((a) => a['status'] == 'completed')
          .length;
      final cancelled = appointments
          .where((a) => a['status'] == 'cancelled')
          .length;
      final rescheduled = appointments
          .where((a) => a['status'] == 'rescheduled')
          .length;

      final currentRevenue = payments.fold<double>(
        0,
        (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0),
      );
      final prevRevenue = prevPayments.fold<double>(
        0,
        (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0),
      );

      final Map<String, int> doctorCountMap = {};
      for (final appt in doctorAppointments) {
        final docId = appt['doctor_id'] as String?;
        if (docId != null) {
          doctorCountMap[docId] = (doctorCountMap[docId] ?? 0) + 1;
        }
      }

      final sortedDoctorIds = doctorCountMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topIds = sortedDoctorIds.take(10).map((e) => e.key).toList();

      List<_DoctorStat> topDoctors = [];
      if (topIds.isNotEmpty) {
        final profilesData = await supabase
            .from('profiles')
            .select('id, full_name, avatar_url, role')
            .inFilter('id', topIds);

        final profileMap = <String, Map<String, dynamic>>{};
        for (final p in profilesData) {
          profileMap[p['id']] = p;
        }

        topDoctors = topIds.map((id) {
          final count = doctorCountMap[id]!;
          final profile = profileMap[id];
          final name = profile?['full_name'] as String? ?? 'Unknown Doctor';
          return _DoctorStat(id: id, name: name, appointmentCount: count);
        }).toList();
      }

      _usersGrowthPct = _calcGrowth(currentUsers, prevUsers);
      _doctorsGrowthPct = _calcGrowth(currentDoctors, prevDoctors);
      _appointmentsGrowthPct = _calcGrowth(
        totalCurrentAppointments,
        totalPrevAppointments,
      );
      _revenueGrowthPct = _calcGrowth(currentRevenue, prevRevenue);

      setState(() {
        _totalUsers = currentUsers;
        _totalDoctors = currentDoctors;
        _totalAppointments = totalCurrentAppointments;
        _totalRevenue = currentRevenue;
        _completedAppointments = completed;
        _cancelledAppointments = cancelled;
        _rescheduledAppointments = rescheduled;
        _topDoctors = topDoctors;
        _forumPostsCount = forumPosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double _calcGrowth(num current, num previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous * 100);
  }

  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return '₦${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '₦${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '₦${(value / 1000).toStringAsFixed(1)}K';
    }
    return '₦${value.toStringAsFixed(0)}';
  }

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      final str = value.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
        buffer.write(str[i]);
      }
      return buffer.toString();
    }
    return value.toString();
  }

  String _previousPeriodLabel() {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    switch (_selectedRange) {
      case 'Today':
        return 'Yesterday';
      case 'This Week':
        return 'Last Week';
      case 'This Quarter':
        return 'Last Quarter';
      case 'This Year':
        return 'Last Year';
      case 'This Month':
      default:
        final month = DateTime.now().month;
        final prev = month == 1 ? 12 : month - 1;
        return months[prev];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 4,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeaderRow(),
                  const SizedBox(height: 24),
                  _buildFilterRow(),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    _buildLoadingState()
                  else if (_error != null)
                    _buildErrorState()
                  else ...[
                    _buildKpiGrid(),
                    const SizedBox(height: 32),
                    _buildAppointmentsOverviewChart(),
                    const SizedBox(height: 32),
                    _buildTopDoctors(),
                    const SizedBox(height: 32),
                    _buildActivitySummary(),
                    const SizedBox(height: 32),
                    _buildReportsShortcuts(),
                    const SizedBox(height: 32),
                    _buildFooterAlert(),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading reports...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.errorLightOf(context)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _error ?? 'Unknown error',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiaryOf(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports & Insights Center',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryOf(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track performance, usage and key metrics in real-time',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Row(
            children: [
              Icon(Icons.ios_share_rounded, size: 16, color: AppColors.textSecondaryOf(context)),
              const SizedBox(width: 6),
              Text(
                'Export Report',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.textSecondaryOf(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          ..._ranges.map((range) {
            final isSelected = _selectedRange == range;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedRange = range);
                _loadData();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderLightOf(context),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  range,
                  style: TextStyle(
                    color: isSelected ? AppColors.textInverse : AppColors.textSecondaryOf(context),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLightOf(context)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textSecondaryOf(context),
                ),
                const SizedBox(width: 6),
                Text(
                  'Custom Range',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        _buildKpiCard(
          'Total Users',
          _formatNumber(_totalUsers),
          _usersGrowthPct,
          Icons.group_outlined,
          AppColors.success,
        ),
        _buildKpiCard(
          'Active Doctors',
          _formatNumber(_totalDoctors),
          _doctorsGrowthPct,
          Icons.medical_services_outlined,
          AppColors.info,
        ),
        _buildKpiCard(
          'Total Appointments',
          _formatNumber(_totalAppointments),
          _appointmentsGrowthPct,
          Icons.calendar_month_outlined,
          AppColors.primary,
        ),
        _buildKpiCard(
          'Total Revenue',
          _formatCurrency(_totalRevenue),
          _revenueGrowthPct,
          Icons.account_balance_wallet_outlined,
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    double growthPct,
    IconData icon,
    Color color,
  ) {
    final isPositive = growthPct >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightOf(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isPositive
                    ? AppColors.success
                    : AppColors.error,
                size: 12,
              ),
              const SizedBox(width: 2),
              Text(
                '${growthPct.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isPositive
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'vs ${_previousPeriodLabel()}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiaryOf(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsOverviewChart() {
    final total =
        _completedAppointments +
        _cancelledAppointments +
        _rescheduledAppointments;
    final completedPct = total > 0
        ? (_completedAppointments / total * 100)
        : 0.0;
    final cancelledPct = total > 0
        ? (_cancelledAppointments / total * 100)
        : 0.0;
    final rescheduledPct = total > 0
        ? (_rescheduledAppointments / total * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Appointments Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.borderOf(context),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (total == 0)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'No appointments in this period',
                  style: TextStyle(fontSize: 13, color: AppColors.textTertiaryOf(context)),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                _buildLegendDot(
                  AppColors.info,
                  'Completed ($_completedAppointments)',
                ),
                const SizedBox(width: 16),
                _buildLegendDot(
                  AppColors.error,
                  'Cancelled ($_cancelledAppointments)',
                ),
                const SizedBox(width: 16),
                _buildLegendDot(
                  AppColors.success,
                  'Rescheduled ($_rescheduledAppointments)',
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: Column(
                children: [
                  _buildBarSegment(
                    'Completed',
                    completedPct,
                    _completedAppointments,
                    AppColors.info,
                  ),
                  const SizedBox(height: 12),
                  _buildBarSegment(
                    'Cancelled',
                    cancelledPct,
                    _cancelledAppointments,
                    AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  _buildBarSegment(
                    'Rescheduled',
                    rescheduledPct,
                    _rescheduledAppointments,
                    AppColors.success,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarSegment(String label, double pct, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
            Text(
              '$count (${pct.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTopDoctors() {
    return Container(
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
              Text(
                'Top Performing Doctors',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_topDoctors.isEmpty)
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'No doctor appointments in this period',
                  style: TextStyle(fontSize: 13, color: AppColors.textTertiaryOf(context)),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Doctor',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiaryOf(context),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Appointments',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiaryOf(context),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_topDoctors.length, (index) {
              final doctor = _topDoctors[index];
              final initial = doctor.name.isNotEmpty
                  ? doctor.name[0].toUpperCase()
                  : '?';
              return Column(
                children: [
                  _buildDoctorRow(
                    doctor.name,
                    initial,
                    doctor.appointmentCount,
                    index,
                  ),
                  if (index < _topDoctors.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: AppColors.borderLightOf(context)),
                    ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDoctorRow(
    String name,
    String initial,
    int appointments,
    int rank,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimaryOf(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Rank #${rank + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Text(
                appointments.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              Text(
                'appointments',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiaryOf(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildActivitySummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActivityCard(
                  'Forum Posts',
                  _formatNumber(_forumPostsCount),
                  Icons.forum_outlined,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActivityCard(
                  'Active Doctors',
                  _formatNumber(_totalDoctors),
                  Icons.medical_services_outlined,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActivityCard(
                  'Completed',
                  '${_totalAppointments > 0 ? (_completedAppointments / _totalAppointments * 100).toStringAsFixed(0) : 0}%',
                  Icons.check_circle_outline,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsShortcuts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports Shortcuts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _buildShortcutCard(
                'User Analytics',
                'Detailed user insights',
                Icons.bar_chart_rounded,
                AppColors.success,
              ),
              _buildShortcutCard(
                'Doctor Performance',
                'Track doctor metrics',
                Icons.group_outlined,
                AppColors.info,
              ),
              _buildShortcutCard(
                'Financial Reports',
                'Revenue & transactions',
                Icons.account_balance_wallet_outlined,
                AppColors.warning,
              ),
              _buildShortcutCard(
                'Appointment Reports',
                'Booking & trends',
                Icons.calendar_today_outlined,
                AppColors.primary,
              ),
              _buildShortcutCard(
                'System Reports',
                'System & audit logs',
                Icons.settings_system_daydream_outlined,
                AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoLightOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security_rounded,
            color: AppColors.info,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'All reports are updated in real-time and data is securely encrypted.',
              style: TextStyle(
                color: AppColors.textPrimaryOf(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          Row(
            children: [
              Text(
                'Learn more',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoctorStat {
  final String id;
  final String name;
  final int appointmentCount;

  const _DoctorStat({
    required this.id,
    required this.name,
    required this.appointmentCount,
  });
}
