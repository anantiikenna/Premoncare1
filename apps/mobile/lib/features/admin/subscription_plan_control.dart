import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import 'admin_scaffold.dart';

class SubscriptionPlanControl extends ConsumerStatefulWidget {
  const SubscriptionPlanControl({super.key});

  @override
  ConsumerState<SubscriptionPlanControl> createState() =>
      _SubscriptionPlanControlState();
}

class _SubscriptionPlanControlState
    extends ConsumerState<SubscriptionPlanControl> {
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _plans = [];
  Map<String, int> _subscriberCounts = {};
  int _totalActiveSubs = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await Future.wait([_loadPlans(), _loadSubscriberCounts()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadPlans() async {
    try {
      final data = await supabase
          .from('subscription_plans')
          .select('*')
          .order('price', ascending: true);
      if (mounted) setState(() => _plans = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load plans: $e');
    }
  }

  Future<void> _loadSubscriberCounts() async {
    try {
      final subs = await supabase
          .from('doctor_subscriptions')
          .select('plan_id, status');

      final counts = <String, int>{};
      int activeCount = 0;
      for (final s in subs) {
        final status = s['status'] as String?;
        final planId = s['plan_id'] as String?;
        if (planId == null) continue;
        if (status == 'active' || status == 'expiring_soon') {
          counts[planId] = (counts[planId] ?? 0) + 1;
          activeCount++;
        }
      }
      if (mounted) {
        setState(() {
          _subscriberCounts = counts;
          _totalActiveSubs = activeCount;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to load subscriber counts: $e');
      }
    }
  }

  Future<void> _togglePlanActive(String planId, bool currentActive) async {
    final newActive = !currentActive;
    try {
      await supabase
          .from('subscription_plans')
          .update({'is_active': newActive}).eq('id', planId);
      await _loadPlans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newActive ? 'Plan activated' : 'Plan deactivated'),
            backgroundColor: newActive ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update plan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatPrice(num price) {
    if (price == 0) return 'Free';
    final s = price.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '₦$buf';
  }

  String _formatPriceWithPeriod(num price, int months) {
    if (price == 0) return 'Free';
    final base = _formatPrice(price);
    if (months == 1) return '$base/mo';
    if (months == 12) return '$base/yr';
    return '$base/$months mo';
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 4,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null && _plans.isEmpty
                ? _buildErrorState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildStatsRow(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('ACTIVE SUBSCRIPTION PLANS'),
                        const SizedBox(height: 16),
                        ..._buildActivePlanCards(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('INACTIVE PLANS'),
                        const SizedBox(height: 16),
                        ..._buildInactivePlanCards(),
                        const SizedBox(height: 40),
                        _buildInfoBanner(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Retry',
                  style: TextStyle(
                      color: AppColors.textInverse, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLAN ARCHITECTURE',
            style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        SizedBox(height: 8),
        Text('Manage Service Tiers',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildStatsRow() {
    final activePlans = _plans.where((p) => p['is_active'] == true).length;
    return Row(
      children: [
        Expanded(
          child: _SmallStatCard(
            label: 'Active Plans',
            value: activePlans.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SmallStatCard(
            label: 'Active Subs',
            value: _totalActiveSubs.toString(),
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2));
  }

  List<Widget> _buildActivePlanCards() {
    final activePlans = _plans.where((p) => p['is_active'] == true).toList();
    if (activePlans.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLightOf(context)),
          ),
          child: const Center(
            child: Text(
              'No active plans',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ];
    }
    return activePlans.map((plan) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPlanCard(plan),
        )).toList();
  }

  List<Widget> _buildInactivePlanCards() {
    final inactivePlans =
        _plans.where((p) => p['is_active'] != true).toList();
    if (inactivePlans.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLightOf(context)),
          ),
          child: const Center(
            child: Text(
              'All plans are active',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ];
    }
    return inactivePlans.map((plan) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPlanCard(plan),
        )).toList();
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final name = (plan['name'] as String? ?? 'UNKNOWN').toUpperCase();
    final price = (plan['price'] as num?) ?? 0;
    final duration = (plan['duration_months'] as int?) ?? 1;
    final isActive = plan['is_active'] == true;
    final planId = plan['id'] as String;
    final subscribers = _subscriberCounts[planId] ?? 0;

    final color = isActive ? AppColors.primary : AppColors.slate400;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.borderLightOf(context),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.layers_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      _formatPriceWithPeriod(price, duration),
                      style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (val) => _togglePlanActive(planId, isActive),
                activeThumbColor: AppColors.success,
                activeTrackColor:
                    AppColors.success.withValues(alpha: 0.2),
                inactiveThumbColor: AppColors.slate300,
                inactiveTrackColor:
                    AppColors.slate300.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderLight),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded,
                      size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 8),
                  Text('$subscribers active users',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              TextButton(
                onPressed: () {
                  _showPlanDetails(plan);
                },
                child: const Row(
                  children: [
                    Text('View Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPlanDetails(Map<String, dynamic> plan) {
    final name = plan['name'] as String? ?? 'Unknown';
    final description = plan['description'] as String? ?? 'No description';
    final price = (plan['price'] as num?) ?? 0;
    final duration = (plan['duration_months'] as int?) ?? 1;
    final features = (plan['features'] as List<dynamic>?) ?? [];
    final planId = plan['id'] as String;
    final subscribers = _subscriberCounts[planId] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, controller) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(name.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(description,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _DetailChip(
                    label: _formatPriceWithPeriod(price, duration),
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _DetailChip(
                    label: '$subscribers users',
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (features.isNotEmpty) ...[
                const Text('Features',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                ...features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              f.toString(),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 24),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Plan creation and feature editing are managed in the Supabase database. Toggle switches above update the plan\'s active status in real-time.',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SmallStatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
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
          Text(label,
              style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5)),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DetailChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}
