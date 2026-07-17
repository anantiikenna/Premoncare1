import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_locator.dart';
import '../../core/app_colors.dart';
import 'admin_avatar.dart';
import 'admin_scaffold.dart';

final adminEmergencyRequestsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return supabase
      .from('appointments')
      .stream(primaryKey: ['id'])
      .eq('status', 'emergency_request')
      .order('created_at', ascending: false)
      .map((data) => List<Map<String, dynamic>>.from(data));
});

final emergencyAcceptedProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return supabase
      .from('appointments')
      .stream(primaryKey: ['id'])
      .eq('status', 'emergency_accepted')
      .order('created_at', ascending: false)
      .map((data) => List<Map<String, dynamic>>.from(data));
});

class AdminEmergencyQueueScreen extends ConsumerStatefulWidget {
  const AdminEmergencyQueueScreen({super.key});

  @override
  ConsumerState<AdminEmergencyQueueScreen> createState() =>
      _AdminEmergencyQueueScreenState();
}

class _AdminEmergencyQueueScreenState
    extends ConsumerState<AdminEmergencyQueueScreen> {
  List<Map<String, dynamic>> _enrichedRequests = [];
  bool _loadingProfiles = false;

  Future<void> _enrichRequests(
      List<Map<String, dynamic>> requests) async {
    if (requests.isEmpty) {
      setState(() {
        _enrichedRequests = [];
        _loadingProfiles = false;
      });
      return;
    }

    setState(() => _loadingProfiles = true);

    final ids = <String>{
      for (final r in requests) ...[
        if (r['patient_id'] != null) r['patient_id'] as String,
        if (r['doctor_id'] != null) r['doctor_id'] as String,
      ],
    };

    final profiles = await supabase
        .from('profiles')
        .select('id, full_name, avatar_url')
        .inFilter('id', ids.toList());

    final profileMap = {
      for (final p in profiles) p['id'] as String: {
        'full_name': p['full_name'] as String,
        'avatar_url': p['avatar_url'] as String?,
      },
    };

    setState(() {
      _enrichedRequests = requests.map((r) {
        final patientProfile = r['patient_id'] != null ? profileMap[r['patient_id']] : null;
        final doctorProfile = r['doctor_id'] != null ? profileMap[r['doctor_id']] : null;
        final patientName = patientProfile != null ? (patientProfile['full_name'] ?? 'Unknown Patient') : 'Guest Patient';
        final doctorName = doctorProfile != null ? (doctorProfile['full_name'] ?? 'Unknown Doctor') : 'Unassigned';
        return {
          ...r,
          '_patientName': patientName,
          '_doctorName': doctorName,
          '_patientAvatar': patientProfile?['avatar_url'],
          '_doctorAvatar': doctorProfile?['avatar_url'],
        };
      }).toList();
      _loadingProfiles = false;
    });
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final date = DateTime.tryParse(iso);
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
    final requestsAsync = ref.watch(adminEmergencyRequestsProvider);
    final acceptedAsync = ref.watch(emergencyAcceptedProvider);

    return AdminScaffold(
      selectedIndex: 4,
      body: requestsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load emergency queue',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminEmergencyRequestsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (requests) {
          final acceptedCount = acceptedAsync.whenOrNull(data: (a) => a.length) ?? 0;

          _enrichRequests(requests);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.emergency_rounded,
                          color: AppColors.error, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Emergency Queue',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(
                            '${requests.length} pending • $acceptedCount accepted today',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'PENDING',
                        value: '${requests.length}',
                        icon: Icons.flash_on_rounded,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'ACCEPTED',
                        value: '$acceptedCount',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'WATCHING',
                        value: '24/7',
                        icon: Icons.monitor_heart_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (_loadingProfiles && _enrichedRequests.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.borderLightOf(context)),
                    ),
                    child: const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_enrichedRequests.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.borderLightOf(context)),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.health_and_safety_rounded,
                              color: AppColors.success, size: 34),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'No emergency consults waiting',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'New guest emergency bookings will appear here for immediate operational review.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  ..._enrichedRequests.map(
                    (req) => _EmergencyRequestCard(
                      appointment: req,
                      timeAgo: _timeAgo(req['created_at'] as String?),
                    ),
                  ),
                const SizedBox(height: 28),
                const Text('Response Checklist',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 14),
                const _ChecklistItem(
                    title: 'Confirm doctor availability',
                    subtitle:
                        'Ensure the selected specialist is online and responsive.'),
                const _ChecklistItem(
                    title: 'Validate emergency payment',
                    subtitle:
                        'Check P2P evidence before session activation.'),
                const _ChecklistItem(
                    title: 'Monitor conversion follow-up',
                    subtitle:
                        'Guide guests to secure their records after consultation.'),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 14),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

class _EmergencyRequestCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final String timeAgo;

  const _EmergencyRequestCard({
    required this.appointment,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    final status = appointment['status'] as String? ?? 'emergency_request';
    final isAccepted = status == 'emergency_accepted';
    final patientName = appointment['_patientName'] as String? ?? 'Unknown';
    final doctorName = appointment['_doctorName'] as String? ?? 'Unassigned';
    final amount = (appointment['total_amount'] as num?) ?? 0;
    final metadata = appointment['metadata'] as Map<String, dynamic>?;
    final isGuest = patientName == 'Guest Patient' ||
        (metadata != null && metadata.containsKey('guest_token'));
    final appointmentDate = appointment['appointment_date'] as String?;

    final statusColor = isAccepted ? AppColors.success : AppColors.error;
    final statusLabel = isAccepted ? 'ACCEPTED' : 'PENDING';
    final statusIcon =
        isAccepted ? Icons.check_circle_outline_rounded : Icons.access_time_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminAvatar(
                imageUrl: appointment['_doctorAvatar'] as String?,
                name: doctorName,
                radius: 20,
                backgroundColor: AppColors.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Emergency consultation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              AdminAvatar(
                imageUrl: appointment['_patientAvatar'] as String?,
                name: patientName,
                radius: 10,
              ),
              const SizedBox(width: 6),
              _infoChip(Icons.person_outline_rounded, patientName,
                  isGuest ? AppColors.warning : AppColors.textSecondary),
              const SizedBox(width: 10),
              _infoChip(Icons.calendar_today_rounded,
                  _formatDate(appointmentDate), AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _infoChip(Icons.currency_exchange_rounded,
                  '₦${amount.toStringAsFixed(0)}', AppColors.success),
              const Spacer(),
              Text(
                timeAgo,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(String? iso) {
    if (iso == null) return 'No date';
    final date = DateTime.tryParse(iso);
    if (date == null) return 'No date';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ChecklistItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ChecklistItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
