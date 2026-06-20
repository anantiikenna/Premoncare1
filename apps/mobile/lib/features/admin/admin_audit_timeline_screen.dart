import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_scaffold.dart';

class AdminAuditTimelineScreen extends ConsumerStatefulWidget {
  const AdminAuditTimelineScreen({super.key});

  @override
  ConsumerState<AdminAuditTimelineScreen> createState() =>
      _AdminAuditTimelineScreenState();
}

class _AdminAuditTimelineScreenState
    extends ConsumerState<AdminAuditTimelineScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _filteredLogs = [];
  bool _isLoading = true;

  int _totalCount = 0;
  int _securityCount = 0;
  int _financialCount = 0;
  int _infoCount = 0;

  String _selectedFilter = 'All Logs';

  static const Map<String, String> _filterToActionType = {
    'Verification': 'verification',
    'Financial': 'financial',
    'Security': 'security',
    'System': 'system',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadStats(), _loadLogs()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadStats() async {
    try {
      final totalRes =
          await _client.from('audit_logs').select('id').count();
      final securityRes = await _client
          .from('audit_logs')
          .select('id')
          .eq('severity', 'high')
          .count();
      final financialRes = await _client
          .from('audit_logs')
          .select('id')
          .eq('action_type', 'financial')
          .count();
      final infoRes = await _client
          .from('audit_logs')
          .select('id')
          .eq('severity', 'info')
          .count();

      if (mounted) {
        setState(() {
          _totalCount = totalRes.count;
          _securityCount = securityRes.count;
          _financialCount = financialRes.count;
          _infoCount = infoRes.count;
        });
      }
    } catch (e) {
      debugPrint('Error loading audit stats: $e');
    }
  }

  Future<void> _loadLogs() async {
    try {
      final data = await _client
          .from('audit_logs')
          .select('''
            id, created_at, action_type, severity, description, metadata,
            admin_profile:profiles!audit_logs_admin_id_fkey(full_name)
          ''')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _logs = List<Map<String, dynamic>>.from(data);
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('Error loading audit logs: $e');
      if (mounted) {
        setState(() {
          _logs = [];
          _filteredLogs = [];
        });
      }
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'All Logs') {
      _filteredLogs = List.from(_logs);
    } else {
      final actionType = _filterToActionType[_selectedFilter];
      if (actionType != null) {
        _filteredLogs =
            _logs.where((l) => l['action_type'] == actionType).toList();
      } else {
        _filteredLogs = List.from(_logs);
      }
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$min $ampm';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  String _formatDateHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    if (target == today) return 'Today';
    if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'moderate':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _severityLabel(String severity) {
    switch (severity) {
      case 'high':
        return 'High Risk';
      case 'moderate':
        return 'Moderate';
      default:
        return 'Successful';
    }
  }

  IconData _actionIcon(String actionType) {
    switch (actionType) {
      case 'verification':
        return Icons.assignment_ind_rounded;
      case 'financial':
        return Icons.account_balance_wallet_rounded;
      case 'security':
        return Icons.warning_rounded;
      case 'system':
        return Icons.settings_applications_rounded;
      default:
        return Icons.circle;
    }
  }

  Color _actionColor(String actionType) {
    switch (actionType) {
      case 'verification':
        return const Color(0xFF10B981);
      case 'financial':
        return const Color(0xFF3B82F6);
      case 'security':
        return const Color(0xFFEF4444);
      case 'system':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 4,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F62FE)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF0F62FE),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                          _buildStatsRow(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFilterChips(),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateSortHeader(),
                          const SizedBox(height: 24),
                          _buildTimeline(),
                          const SizedBox(height: 24),
                          _buildFooterAlert(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.document_scanner_rounded,
              color: Color(0xFF8B5CF6), size: 28),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audit Timeline Viewer',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5),
              ),
              SizedBox(height: 4),
              Text(
                'Track and review all system activities\nin real-time',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    height: 1.3),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFF10B981), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('LIVE',
                      style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text('Monitoring Active',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildStatCard('$_totalCount', 'Admin Actions', 'All Time',
              Icons.person_outline_rounded, const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          _buildStatCard('$_securityCount', 'Security Alerts', 'High Severity',
              Icons.verified_user_outlined, const Color(0xFF10B981)),
          const SizedBox(width: 12),
          _buildStatCard('$_financialCount', 'Financial Reviews', 'Financial Actions',
              Icons.account_balance_wallet_outlined, const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          _buildStatCard('$_infoCount', 'Info Actions', 'Low Severity',
              Icons.info_outline_rounded, const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String value, String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 16),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      'All Logs',
      'Verification',
      'Financial',
      'Security',
      'System',
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
                _applyFilter();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF0F62FE) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0F62FE)
                        : const Color(0xFFF1F5F9)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: const Color(0xFF0F62FE)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                      ]
                    : [],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSortHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(_filteredLogs.isNotEmpty
                ? _formatDateHeader(
                    DateTime.parse(_filteredLogs.first['created_at']))
                : 'No Logs',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B))),
            const SizedBox(width: 8),
            Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    color: Color(0xFFCBD5E1), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('${_filteredLogs.length} events',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B))),
          ],
        ),
        const Row(
          children: [
            Text('Newest First',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F62FE))),
            SizedBox(width: 4),
            Icon(Icons.swap_vert_rounded,
                color: Color(0xFF0F62FE), size: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    if (_filteredLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.history_rounded,
                  size: 48, color: const Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text('No audit logs found',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              const Text('Pull down to refresh',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(_filteredLogs.length, (index) {
        final log = _filteredLogs[index];
        final createdAt = DateTime.parse(log['created_at']);
        final actionType = log['action_type'] as String? ?? 'system';
        final severity = log['severity'] as String? ?? 'info';
        final description = log['description'] as String? ?? '';
        final metadata = log['metadata'] as Map<String, dynamic>? ?? {};
        final adminName =
            (log['admin_profile'] as Map<String, dynamic>?)?['full_name']
                    as String? ??
                'System';

        final dotColor = _severityColor(severity);
        final icon = _actionIcon(actionType);
        final iconColor = _actionColor(actionType);
        final badgeText = _severityLabel(severity);
        final badgeColor = _severityColor(severity);

        final metaItems = <_EventMeta>[
          _EventMeta(label: 'Admin:', value: adminName),
          if (metadata['ip'] != null)
            _EventMeta(label: 'IP:', value: metadata['ip']),
          if (metadata['device'] != null)
            _EventMeta(
                label: metadata['device'] == 'mobile' ? 'Mobile' : 'Web',
                icon: metadata['device'] == 'mobile'
                    ? Icons.phone_android_rounded
                    : Icons.desktop_windows_outlined),
        ];

        return _buildTimelineItem(
          time: _formatTime(createdAt),
          relativeTime: _timeAgo(createdAt),
          dotColor: dotColor,
          isLast: index == _filteredLogs.length - 1,
          child: _buildEventCard(
            title: description,
            description: 'Action: ${actionType.toUpperCase()} • By: $adminName',
            icon: icon,
            iconColor: iconColor,
            badgeText: badgeText,
            badgeColor: badgeColor,
            metaData: metaItems,
          ),
        );
      }),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String relativeTime,
    required Color dotColor,
    required Widget child,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(relativeTime,
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B))),
              ],
            ),
          ),
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFF1F5F9),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
    required List<_EventMeta> metaData,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
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
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E293B),
                                  height: 1.2)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (badgeText == 'Successful') ...[
                                Icon(Icons.check_circle_rounded,
                                    color: badgeColor, size: 10),
                                const SizedBox(width: 4),
                              ] else if (badgeText == 'High Risk') ...[
                                Icon(Icons.warning_rounded,
                                    color: badgeColor, size: 10),
                                const SizedBox(width: 4),
                              ] else if (badgeText == 'Moderate') ...[
                                Icon(Icons.error_rounded,
                                    color: badgeColor, size: 10),
                                const SizedBox(width: 4),
                              ],
                              Text(badgeText,
                                  style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(description,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          if (metaData.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: metaData.map((meta) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (meta.label.isNotEmpty)
                            Text('${meta.label} ',
                                style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          if (meta.value != null)
                            Text(meta.value!,
                                style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          if (meta.icon != null) ...[
                            if (meta.label.isNotEmpty || meta.value != null)
                              const SizedBox(width: 4),
                            Icon(meta.icon,
                                color: const Color(0xFF94A3B8), size: 12),
                          ],
                          if (meta != metaData.last)
                            Container(
                              margin: const EdgeInsets.only(left: 12),
                              width: 1,
                              height: 10,
                              color: const Color(0xFFE2E8F0),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFCBD5E1), size: 20),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooterAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded,
              color: Color(0xFF3B82F6), size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'All audit activities are securely stored for compliance and investigation purposes.',
              style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.4),
            ),
          ),
          Row(
            children: const [
              Text('Learn more',
                  style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF2563EB), size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventMeta {
  final String label;
  final String? value;
  final IconData? icon;

  const _EventMeta({required this.label, this.value, this.icon});
}
