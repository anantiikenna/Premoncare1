import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import '../../core/app_colors.dart';
import 'admin_avatar.dart';
import 'admin_scaffold.dart';
import 'admin_shared_widgets.dart';

class DisputeResolutionScreen extends ConsumerStatefulWidget {
  const DisputeResolutionScreen({super.key});

  @override
  ConsumerState<DisputeResolutionScreen> createState() =>
      _DisputeResolutionScreenState();
}

class _DisputeResolutionScreenState
    extends ConsumerState<DisputeResolutionScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>> _disputes = [];
  List<Map<String, dynamic>> _filteredDisputes = [];
  Map<String, dynamic>? _selectedDispute;
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';

  int _openCount = 0;
  int _inReviewCount = 0;
  int _resolvedCount = 0;
  int _highRiskCount = 0;

  final filters = [
    'All',
    'Payment',
    'Consultation',
    'Refund',
    'Fraud',
    'Behavior',
    'Other',
  ];

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
    await Future.wait([_loadStats(), _loadDisputes()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadStats() async {
    try {
      final openRes = await _client
          .from('disputes')
          .select('id')
          .eq('status', 'open');
      final inReviewRes = await _client
          .from('disputes')
          .select('id')
          .eq('status', 'under_review');
      final resolvedRes = await _client
          .from('disputes')
          .select('id')
          .eq('status', 'resolved');
      final highRiskRes = await _client
          .from('disputes')
          .select('id')
          .eq('risk_level', 'high');

      if (mounted) {
        setState(() {
          _openCount = openRes.length;
          _inReviewCount = inReviewRes.length;
          _resolvedCount = resolvedRes.length;
          _highRiskCount = highRiskRes.length;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading dispute stats: $e');
      if (mounted && _error == null) setState(() => _error = e.toString());
    }
  }

  Future<void> _loadDisputes() async {
    try {
      final data = await _client
          .from('disputes')
          .select('''
            *,
            patient_profile:profiles!disputes_patient_id_fkey(full_name, email, avatar_url),
            doctor_profile:profiles!disputes_doctor_id_fkey(full_name, email, avatar_url)
          ''')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _disputes = List<Map<String, dynamic>>.from(data);
          _applyFilter();
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading disputes: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _disputes = [];
          _filteredDisputes = [];
        });
      }
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      _filteredDisputes = List.from(_disputes);
    } else {
      final category = _selectedFilter.toLowerCase();
      _filteredDisputes = _disputes
          .where((d) => d['category'] == category)
          .toList();
    }
  }

  String _formatDate(DateTime dateTime) {
    const months = [
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
    final h = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} • $h:$min $ampm';
  }

  String _timeAgo(DateTime dateTime) {
    const months = [
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
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  Future<void> _resolveDispute(
    String disputeId,
    String status, {
    String? notes,
  }) async {
    try {
      await _client
          .from('disputes')
          .update({
            'status': status,
            'resolution_notes': notes,
            'resolved_at': DateTime.now().toIso8601String(),
            'resolved_by': _client.auth.currentUser?.id,
          })
          .eq('id', disputeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dispute ${status == 'resolved' ? 'resolved' : 'dismissed'} successfully.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _selectedDispute = null);
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update dispute: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.warning;
      case 'under_review':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      case 'dismissed':
        return AppColors.textTertiaryOf(context);
      default:
        return AppColors.textTertiaryOf(context);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'under_review':
        return 'In Review';
      case 'resolved':
        return 'Resolved';
      case 'dismissed':
        return 'Closed';
      default:
        return status;
    }
  }

  Color _categoryIconColor(String category) {
    switch (category) {
      case 'payment':
        return AppColors.warning;
      case 'consultation':
        return AppColors.info;
      case 'refund':
        return AppColors.success;
      case 'fraud':
        return AppColors.error;
      case 'behavior':
        return AppColors.pink;
      default:
        return AppColors.textTertiaryOf(context);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'payment':
        return Icons.account_balance_wallet;
      case 'consultation':
        return Icons.videocam;
      case 'refund':
        return Icons.refresh;
      case 'fraud':
        return Icons.flag;
      case 'behavior':
        return Icons.chat_bubble;
      default:
        return Icons.help_outline;
    }
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textTertiaryOf(context);
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '';
    final numVal = num.tryParse(amount.toString());
    if (numVal == null) return '';
    return '₦${numVal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return AdminScaffold(
      selectedIndex: 4,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? AdminErrorState(message: _error!, onRetry: _loadData)
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildStatCards(),
                    const SizedBox(height: 24),
                    _buildFilterChips(),
                    const SizedBox(height: 24),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildDisputesList()),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildRightColumn()),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildDisputesList(),
                          const SizedBox(height: 32),
                          _buildRightColumn(),
                        ],
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dispute Resolution Center',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage, review and resolve disputes fairly and efficiently.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiaryOf(context),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildIconButton(Icons.refresh, onTap: _loadData),
            const SizedBox(width: 12),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          border: Border.all(color: AppColors.borderLightOf(context)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimaryOf(context)),
      ),
    );
  }

  Widget _buildStatCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            'Open Disputes',
            _openCount.toString(),
            Icons.warning_amber,
            AppColors.warning,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'In Review',
            _inReviewCount.toString(),
            Icons.access_time,
            AppColors.warning,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'Resolved',
            _resolvedCount.toString(),
            Icons.check_circle,
            AppColors.success,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'High Risk',
            _highRiskCount.toString(),
            Icons.flag,
            AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
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
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                    _applyFilter();
                  });
                }
              },
              backgroundColor: AppColors.borderLightOf(context),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.textInverse
                    : AppColors.textSecondaryOf(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDisputesList() {
    if (_filteredDisputes.isEmpty) {
      return AdminEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No disputes found',
        subtitle: 'No disputes match the current filter.',
      );
    }

    return Column(
      children: _filteredDisputes.map((dispute) {
        final patient = dispute['patient_profile'] as Map<String, dynamic>?;
        final doctor = dispute['doctor_profile'] as Map<String, dynamic>?;
        final patientName = patient?['full_name'] ?? 'Unknown Patient';
        final doctorName = doctor?['full_name'] ?? 'Unknown Doctor';
        final category = dispute['category'] ?? 'other';
        final riskLevel = dispute['risk_level'] ?? 'low';
        final createdAt =
            DateTime.tryParse(dispute['created_at'] ?? '') ?? DateTime.now();
        final isSelected = _selectedDispute?['id'] == dispute['id'];

        return GestureDetector(
          onTap: () => setState(() => _selectedDispute = dispute),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.borderLightOf(context),
                width: isSelected ? 2 : 1,
              ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _categoryIconColor(
                          category,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _categoryIcon(category),
                        color: _categoryIconColor(category),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  dispute['title'] ?? 'Untitled Dispute',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimaryOf(context),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _riskColor(
                                    riskLevel,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (riskLevel == 'high') ...[
                                      Icon(
                                        Icons.warning_amber,
                                        size: 12,
                                        color: _riskColor(riskLevel),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      '${riskLevel.toString()[0].toUpperCase()}${riskLevel.toString().substring(1)} Risk',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _riskColor(riskLevel),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dispute['description'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryOf(context),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    AdminAvatar(
                      imageUrl: patient?['avatar_url'] as String?,
                      name: patientName,
                      radius: 12,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      patientName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'vs',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTertiaryOf(context),
                        ),
                      ),
                    ),
                    AdminAvatar(
                      imageUrl: doctor?['avatar_url'] as String?,
                      name: doctorName,
                      radius: 12,
                      backgroundColor: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doctorName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryOf(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          dispute['status'] ?? 'open',
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(dispute['status'] ?? 'open'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(dispute['status'] ?? 'open'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '#DSP-${dispute['id'].toString().substring(0, math.min(8, dispute['id'].toString().length)).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiaryOf(context),
                      ),
                    ),
                    _buildDividerDot(),
                    Text(
                      _timeAgo(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiaryOf(context),
                      ),
                    ),
                    if (dispute['amount'] != null) ...[
                      _buildDividerDot(),
                      Text(
                        _formatAmount(dispute['amount']),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiaryOf(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDividerDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textTertiaryOf(context),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildRightColumn() {
    if (_selectedDispute == null) {
      return _buildInsightsPanel();
    }
    return _buildDisputeDetailPanel();
  }

  Widget _buildInsightsPanel() {
    final total = _openCount + _inReviewCount + _resolvedCount;
    final openPct = total > 0
        ? (_openCount / total * 100).toStringAsFixed(1)
        : '0.0';
    final reviewPct = total > 0
        ? (_inReviewCount / total * 100).toStringAsFixed(1)
        : '0.0';
    final resolvedPct = total > 0
        ? (_resolvedCount / total * 100).toStringAsFixed(1)
        : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dispute Insights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLightOf(context)),
              ),
              child: const Row(
                children: [
                  Text(
                    'This Month',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.expand_more, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
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
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: DonutChartPainter(
                    openCount: _openCount,
                    inReviewCount: _inReviewCount,
                    resolvedCount: _resolvedCount,
                    highRiskCount: _highRiskCount,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          total.toString(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textTertiaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildInsightLegendRow(
                AppColors.warning,
                'Open',
                '$_openCount ($openPct%)',
              ),
              _buildInsightLegendRow(
                AppColors.warning,
                'In Review',
                '$_inReviewCount ($reviewPct%)',
              ),
              _buildInsightLegendRow(
                AppColors.success,
                'Resolved',
                '$_resolvedCount ($resolvedPct%)',
              ),
              _buildInsightLegendRow(
                AppColors.error,
                'High Risk',
                '$_highRiskCount',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We ensure fair, secure and transparent resolution for all parties involved.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Learn more',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisputeDetailPanel() {
    final d = _selectedDispute!;
    final patient = d['patient_profile'] as Map<String, dynamic>?;
    final doctor = d['doctor_profile'] as Map<String, dynamic>?;
    final patientName = patient?['full_name'] ?? 'Unknown Patient';
    final doctorName = doctor?['full_name'] ?? 'Unknown Doctor';
    final createdAt =
        DateTime.tryParse(d['created_at'] ?? '') ?? DateTime.now();
    final status = d['status'] ?? 'open';
    final riskLevel = d['risk_level'] ?? 'low';
    final category = d['category'] ?? 'other';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Dispute Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedDispute = null),
              child: Icon(
                Icons.close,
                size: 20,
                color: AppColors.textTertiaryOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _categoryIconColor(
                        category,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _categoryIcon(category),
                      color: _categoryIconColor(category),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['title'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_statusLabel(status)} • ${_timeAgo(createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                'Category',
                category[0].toUpperCase() + category.substring(1),
              ),
              _buildDetailRow(
                'Risk Level',
                '${riskLevel[0].toUpperCase()}${riskLevel.substring(1)}',
                valueColor: _riskColor(riskLevel),
              ),
              if (d['amount'] != null)
                _buildDetailRow('Amount', _formatAmount(d['amount'])),
              _buildDetailRow(
                'Dispute ID',
                '#DSP-${d['id'].toString().substring(0, math.min(8, d['id'].toString().length)).toUpperCase()}',
              ),
              _buildDetailRow('Created', _formatDate(createdAt)),
              const Divider(height: 32),
              _buildDetailRow('Patient', patientName),
              _buildDetailRow('Patient Email', patient?['email'] ?? 'N/A'),
              const SizedBox(height: 8),
              _buildDetailRow('Doctor', doctorName),
              _buildDetailRow('Doctor Email', doctor?['email'] ?? 'N/A'),
              if (d['description'] != null &&
                  d['description'].toString().isNotEmpty) ...[
                const Divider(height: 32),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiaryOf(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  d['description'],
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryOf(context),
                    height: 1.5,
                  ),
                ),
              ],
              if (d['resolution_notes'] != null &&
                  d['resolution_notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successLightOf(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resolution Notes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d['resolution_notes'],
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (status != 'resolved' && status != 'dismissed') ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
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
                Text(
                  'Resolution Actions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showResolveDialog(
                      d['id'],
                      'under_review',
                      'Mark as Under Review',
                    ),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Mark as In Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.textInverse,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showResolveDialog(
                          d['id'],
                          'resolved',
                          'Resolve Dispute',
                        ),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Resolve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.textInverse,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showResolveDialog(
                          d['id'],
                          'dismissed',
                          'Close Dispute',
                        ),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.borderOf(context),
                          foregroundColor: AppColors.textInverse,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showResolveDialog(
    String disputeId,
    String targetStatus,
    String dialogTitle,
  ) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${targetStatus == 'under_review'
                  ? 'mark this dispute as in review'
                  : targetStatus == 'resolved'
                  ? 'resolve'
                  : 'close'} this dispute?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add resolution notes (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resolveDispute(
                disputeId,
                targetStatus,
                notes: notesController.text.isNotEmpty
                    ? notesController.text
                    : null,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: targetStatus == 'resolved'
                  ? AppColors.success
                  : targetStatus == 'dismissed'
                  ? AppColors.borderOf(context)
                  : AppColors.warning,
              foregroundColor: AppColors.textInverse,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiaryOf(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightLegendRow(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final int openCount;
  final int inReviewCount;
  final int resolvedCount;
  final int highRiskCount;

  DonutChartPainter({
    this.openCount = 0,
    this.inReviewCount = 0,
    this.resolvedCount = 0,
    this.highRiskCount = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        math.min(size.width / 2, size.height / 2) - (paint.strokeWidth / 2);

    final total = openCount + inReviewCount + resolvedCount;
    if (total == 0) {
      paint.color = AppColors.borderLight;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        0,
        2 * math.pi,
        false,
        paint,
      );
      return;
    }

    final segments = [
      {'color': AppColors.success, 'count': resolvedCount},
      {'color': AppColors.warning, 'count': openCount},
      {'color': AppColors.warning, 'count': inReviewCount},
      {'color': AppColors.error, 'count': highRiskCount},
    ];

    double startAngle = -math.pi / 2;

    for (var segment in segments) {
      final count = segment['count'] as int;
      if (count == 0) continue;
      paint.color = segment['color'] as Color;
      final sweepAngle = (count / total) * 2 * math.pi;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 0.05,
        sweepAngle - 0.1,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
