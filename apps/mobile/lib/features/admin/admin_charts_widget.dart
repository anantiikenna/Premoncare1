import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/supabase_locator.dart';
import '../../shared/widgets/glass_card.dart';

class AdminChartsWidget extends ConsumerStatefulWidget {
  const AdminChartsWidget({super.key});

  @override
  ConsumerState<AdminChartsWidget> createState() => _AdminChartsWidgetState();
}

class _AdminChartsWidgetState extends ConsumerState<AdminChartsWidget> {
  bool _isLoading = true;
  Timer? _refreshTimer;
  RealtimeChannel? _realtimeChannel;

  List<_DayCount> _completedTrend = [];
  List<_DayCount> _cancelledTrend = [];
  List<_RevenueDay> _revenueTrend = [];
  Map<String, int> _statusBreakdown = {};
  int _totalAppointments = 0;
  int _totalRevenue = 0;
  int _totalStatusCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchData(),
    );
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final since = thirtyDaysAgo.toIso8601String();

    final results = await Future.wait([
      supabase
          .from('appointments')
          .select('status, created_at')
          .gte('created_at', since),
      supabase
          .from('payments')
          .select('amount, created_at, status')
          .eq('status', 'approved')
          .gte('created_at', since),
    ]);

    final appointments = results[0] as List<dynamic>;
    final payments = results[1] as List<dynamic>;

    final completedByDay = <String, int>{};
    final cancelledByDay = <String, int>{};
    final statusCounts = <String, int>{};

    for (final appt in appointments) {
      final status = appt['status'] as String? ?? '';
      final createdAt =
          DateTime.tryParse(appt['created_at'] as String? ?? '') ?? now;
      final dayKey = DateFormat('MM-dd').format(createdAt);

      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      if (status == 'completed') {
        completedByDay[dayKey] = (completedByDay[dayKey] ?? 0) + 1;
      } else if (status == 'cancelled') {
        cancelledByDay[dayKey] = (cancelledByDay[dayKey] ?? 0) + 1;
      }
    }

    final revenueByDay = <String, int>{};
    int totalRev = 0;

    for (final pay in payments) {
      final amount = (pay['amount'] as num?)?.toInt() ?? 0;
      final createdAt =
          DateTime.tryParse(pay['created_at'] as String? ?? '') ?? now;
      final dayKey = DateFormat('MM-dd').format(createdAt);
      revenueByDay[dayKey] = (revenueByDay[dayKey] ?? 0) + amount;
      totalRev += amount;
    }

    final days = List.generate(30, (i) {
      final d = thirtyDaysAgo.add(Duration(days: i));
      return DateFormat('MM-dd').format(d);
    });

    final completedTrend = days
        .map((d) => _DayCount(d, completedByDay[d] ?? 0))
        .toList();
    final cancelledTrend = days
        .map((d) => _DayCount(d, cancelledByDay[d] ?? 0))
        .toList();
    final revenueTrend = days
        .map((d) => _RevenueDay(d, revenueByDay[d] ?? 0))
        .toList();

    if (!mounted) return;
    setState(() {
      _completedTrend = completedTrend;
      _cancelledTrend = cancelledTrend;
      _revenueTrend = revenueTrend;
      _statusBreakdown = statusCounts;
      _totalAppointments = appointments.length;
      _totalRevenue = totalRev;
      _totalStatusCount = appointments.length;
      _isLoading = false;
    });
  }

  void _subscribeToRealtime() {
    _realtimeChannel = supabase
        .channel('admin-charts-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          callback: (_) => _fetchData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (_) => _fetchData(),
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Column(
      children: [
        _buildAppointmentsChart(context),
        const SizedBox(height: 20),
        _buildRevenueChart(context),
        const SizedBox(height: 20),
        _buildStatusPieChart(context),
      ],
    );
  }

  Widget _buildChartCard({
    required BuildContext context,
    required String title,
    required int totalCount,
    required Widget chart,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.h4Of(context)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalCount',
                  style: AppTypography.labelMediumOf(
                    context,
                  ).copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 220, child: chart),
        ],
      ),
    );
  }

  Widget _buildAppointmentsChart(BuildContext context) {
    return _buildChartCard(
      context: context,
      title: 'Appointments Over Time',
      totalCount: _totalAppointments,
      chart: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.borderOf(context).withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value != value.roundToDouble())
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      value.toInt().toString(),
                      style: AppTypography.captionOf(context),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _completedTrend.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _completedTrend[idx].day,
                      style: AppTypography.captionOf(context),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (_completedTrend.length - 1).toDouble(),
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: _completedTrend
                  .asMap()
                  .entries
                  .map(
                    (e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()),
                  )
                  .toList(),
              isCurved: true,
              color: AppColors.success,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.success.withValues(alpha: 0.1),
              ),
            ),
            LineChartBarData(
              spots: _cancelledTrend
                  .asMap()
                  .entries
                  .map(
                    (e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()),
                  )
                  .toList(),
              isCurved: true,
              color: AppColors.error,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.error.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.textPrimaryOf(context),
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      '${s.y.toInt()}',
                      AppTypography.bodySmallOf(
                        context,
                      ).copyWith(color: Colors.white),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    final maxVal = _revenueTrend.fold<int>(
      0,
      (prev, e) => e.amount > prev ? e.amount : prev,
    );

    return _buildChartCard(
      context: context,
      title: 'Revenue Trends',
      totalCount: _totalRevenue,
      chart: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0
                ? (maxVal / 4).ceilToDouble().clamp(1, double.infinity)
                : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.borderOf(context).withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: maxVal > 0
                    ? (maxVal / 4).ceilToDouble().clamp(1, double.infinity)
                    : 1,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      _formatCurrency(value.toInt()),
                      style: AppTypography.captionOf(context),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _revenueTrend.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _revenueTrend[idx].day,
                      style: AppTypography.captionOf(context),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _revenueTrend
              .asMap()
              .entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.amount.toDouble(),
                      color: AppColors.primary,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.textPrimaryOf(context),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  _formatCurrency(rod.toY.toInt()),
                  AppTypography.bodySmall.copyWith(color: Colors.white),
                );
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildStatusPieChart(BuildContext context) {
    final colors = {
      'completed': AppColors.success,
      'pending': AppColors.warning,
      'cancelled': AppColors.error,
      'ongoing': AppColors.info,
      'emergency': AppColors.pink,
      'emergency_request': AppColors.pink,
      'emergency_accepted': AppColors.pink,
      'emergency_declined': AppColors.error,
    };

    final sections = _statusBreakdown.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final pieSections = sections.asMap().entries.map((entry) {
      final status = entry.value.key;
      final count = entry.value.value;
      final color = colors[status] ?? AppColors.textTertiaryOf(context);
      final pct = _totalStatusCount > 0
          ? (count / _totalStatusCount * 100).toStringAsFixed(1)
          : '0';

      return PieChartSectionData(
        value: count.toDouble(),
        title: '$pct%',
        color: color,
        radius: 90,
        titleStyle: AppTypography.labelSmallOf(context).copyWith(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      );
    }).toList();

    return _buildChartCard(
      context: context,
      title: 'Appointment Status',
      totalCount: _totalStatusCount,
      chart: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: pieSections.isEmpty
                    ? [
                        PieChartSectionData(
                          value: 1,
                          title: 'No Data',
                          color: AppColors.borderLightOf(context),
                          radius: 90,
                          titleStyle: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiaryOf(context),
                          ),
                        ),
                      ]
                    : pieSections,
              ),
              duration: const Duration(milliseconds: 600),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sections.map((entry) {
              final color =
                  colors[entry.key] ?? AppColors.textTertiaryOf(context);
              final label = entry.key.replaceAll('_', ' ');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$label (${entry.value})',
                      style: AppTypography.captionOf(context),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toString();
  }
}

class _DayCount {
  final String day;
  final int count;
  const _DayCount(this.day, this.count);
}

class _RevenueDay {
  final String day;
  final int amount;
  const _RevenueDay(this.day, this.amount);
}
