import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/supabase_locator.dart';
import '../../core/providers.dart';
import '../../shared/widgets/global_user_avatar.dart';
import 'package:mobile/features/doctor/propose_followup_dialog.dart';

class DoctorDashboard extends ConsumerStatefulWidget {
  const DoctorDashboard({super.key});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> {
  Map<String, dynamic>? _profileData;
  bool _isOnline = false;
  bool _loading = false;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _stopHeartbeat();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select('full_name, is_online')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _profileData = data;
          _isOnline = data['is_online'] ?? false;
        });

        if (_isOnline) {
          _startHeartbeat();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching doctor profile: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // Immediately send first heartbeat ping
    _sendHeartbeatPing();
    
    // Set 60-second periodic heartbeat ping
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _sendHeartbeatPing();
    });
  }

  Future<void> _sendHeartbeatPing() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase
          .from('profiles')
          .update({'last_seen': DateTime.now().toUtc().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      if (kDebugMode) debugPrint('Heartbeat ping failed: $e');
    }
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _togglePresence(bool newStatus) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _loading = true);

    try {
      await supabase.from('profiles').update({
        'is_online': newStatus,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);

      if (mounted) {
        setState(() {
          _isOnline = newStatus;
        });

        if (newStatus) {
          _startHeartbeat();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are now active for emergency consult requests.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        } else {
          _stopHeartbeat();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency presence turned off.'),
              backgroundColor: Color(0xFF475569),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update presence status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Deep immersive mesh background
          Positioned(
            top: -150,
            right: -100,
            child: _MeshCircle(color: primaryColor.withValues(alpha: 0.08), size: 500),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _MeshCircle(color: primaryColor.withValues(alpha: 0.03), size: 300),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildEmergencyRequestsBanner(ref),
                  const SizedBox(height: 8),
                  _buildRevenueCard(context, ref, primaryColor),
                  const SizedBox(height: 32),
                  _buildSectionTitle('PERFORMANCE METRICS'),
                  const SizedBox(height: 20),
                  _buildMetricsGrid(ref, primaryColor),
                  const SizedBox(height: 32),
                  _buildSectionTitle('CLINICAL WORKFLOW'),
                  const SizedBox(height: 20),
                  _buildQuickActions(context, primaryColor),
                  const SizedBox(height: 32),
                  _buildSectionTitle('UPCOMING SESSIONS'),
                  const SizedBox(height: 20),
                  _buildScheduleList(ref, primaryColor),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildHeader() {
    final doctorName = _profileData?['full_name'] ?? 'Professional';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PRACTITIONER HUB', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(
                doctorName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1.0),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildPresenceSwitch(),
      ],
    );
  }

  Widget _buildEmergencyRequestsBanner(WidgetRef ref) {
    final emergencyAsync = ref.watch(emergencyRequestsProvider);
    return emergencyAsync.when(
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...requests.map((req) {
              final patientName = req['metadata']?['guest_token'] != null
                  ? 'Emergency Guest'
                  : 'Patient ···${(req['patient_id'] ?? '').toString().substring(((req['patient_id'] ?? '').toString().length - 4).clamp(0, 99))}';
              final duration = req['duration_minutes'] ?? 15;
              final amount = (req['total_amount'] as num?)?.toInt() ?? 0;
              final createdAt = req['created_at'] != null
                  ? DateTime.tryParse(req['created_at'])?.toLocal()
                  : null;
              final timeAgo = createdAt != null ? _timeAgo(createdAt) : '';

              return GestureDetector(
                onTap: () => context.push('/doctor-emergency-request', extra: {
                  'appointmentId': req['id'],
                  'patientId': req['patient_id'] ?? '',
                  'patientName': patientName,
                  'durationMinutes': duration,
                  'totalAmount': amount.toDouble(),
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFEF4444).withValues(alpha: 0.08),
                        const Color(0xFFFEE2E2).withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EMERGENCY REQUEST',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFEF4444), letterSpacing: 1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$patientName • ${duration}min • ₦$amount',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                            ),
                            if (timeAgo.isNotEmpty)
                              Text(
                                timeAgo,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'VIEW',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildPresenceSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F62FE).withValues(alpha: _isOnline ? 0.05 : 0),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isOnline ? const Color(0xFF10B981) : const Color(0xFF64748B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isOnline ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: _isOnline ? const Color(0xFF10B981) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 32,
            width: 52,
            child: Switch.adaptive(
              value: _isOnline,
              activeTrackColor: const Color(0xFF10B981),
              onChanged: _loading ? null : (val) => _togglePresence(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(BuildContext context, WidgetRef ref, Color primaryColor) {
    final revenueAsync = ref.watch(doctorRevenueProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F62FE), Color(0xFF0EA5E9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL CLINICAL REVENUE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  children: [
                    Text('MONTHLY', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                    Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          revenueAsync.when(
            data: (revenue) => Text('₦${revenue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
            loading: () => const SizedBox(height: 42, child: CircularProgressIndicator(color: Colors.white)),
            error: (_, _) => const Text('₦0.00', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMainCardChip(Icons.trending_up_rounded, '18.6% Growth', Colors.green),
              const Spacer(),
              _buildGlassButton('Analytics', Icons.bar_chart_rounded, () => context.push('/doctor/earnings')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainCardChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF22C55E), size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildGlassButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            const SizedBox(width: 6),
            Icon(icon, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(WidgetRef ref, Color primaryColor) {
    final metricsAsync = ref.watch(userProfileProvider);

    return metricsAsync.when(
      data: (metrics) {
        if (metrics == null) return const SizedBox.shrink();
        final patientsHelped = metrics['patients_helped']?.toString() ?? '0';
        final todaySessions = '0'; // Real count needs appointments query for today, leaving dummy/0 for now or compute later
        final pendingInvites = '0';
        final rating = '4.9'; // Need a review aggregation or column, dummy for now

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildMetricCard(patientsHelped, 'Total Patients', primaryColor, Icons.people_rounded),
            _buildMetricCard(todaySessions, 'Today Sessions', const Color(0xFF10B981), Icons.calendar_today_rounded),
            _buildMetricCard(pendingInvites, 'Pending Invites', const Color(0xFFF59E0B), Icons.hourglass_empty_rounded),
            _buildMetricCard(rating, 'Clinical Rating', const Color(0xFF6366F1), Icons.star_rounded),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildMetricCard(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              Icon(icon, color: color.withValues(alpha: 0.4), size: 20),
            ],
          ),
          const Spacer(),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Color primaryColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionItem(Icons.calendar_month_rounded, 'Schedule', primaryColor, onTap: () => context.push('/doctor/schedule')),
          _buildActionItem(Icons.person_add_rounded, 'Requests', const Color(0xFF10B981), onTap: () => context.push('/appointments')),
          _buildActionItem(Icons.history_edu_rounded, 'Follow-up', const Color(0xFFF59E0B), onTap: () {
            showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => const ProposeFollowupDialog());
          }),
          _buildActionItem(Icons.medication_rounded, 'Prescribe', const Color(0xFF6366F1), onTap: () => context.push('/appointments')),
          _buildActionItem(Icons.verified_user_rounded, 'Compliance', const Color(0xFF3B82F6), onTap: () => context.push('/doctor/subscription')),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.15))), child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(WidgetRef ref, Color primaryColor) {
    final appointmentsAsync = ref.watch(upcomingAppointmentsProvider);

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      padding: const EdgeInsets.all(24),
      child: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return const Center(child: Text('No upcoming sessions.', style: TextStyle(color: Color(0xFF64748B))));
          }
          return Column(
            children: appointments.asMap().entries.map((entry) {
              final index = entry.key;
              final appt = entry.value;
              final time = appt['appointment_date'] != null 
                  ? DateTime.parse(appt['appointment_date']).toLocal().toString().substring(11, 16) 
                  : 'N/A';
              final patientName = appt['patient_id'] != null
                  ? 'Patient ···${appt['patient_id'].toString().substring(appt['patient_id'].toString().length - 4)}'
                  : 'Unknown';
              final isConfirmed = appt['status'] == 'confirmed';
              final isLast = index == appointments.length - 1;

              return Column(
                children: [
                  _buildScheduleItem(time, patientName, 'CONSULTATION', isConfirmed, primaryColor),
                  if (!isLast) const Divider(height: 32, color: Color(0xFFF1F5F9)),
                ],
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildScheduleItem(String time, String patient, String type, bool isConfirmed, Color primaryColor) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (isConfirmed ? const Color(0xFF10B981) : const Color(0xFF94A3B8)).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(isConfirmed ? 'CONFIRMED' : 'PENDING', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isConfirmed ? const Color(0xFF10B981) : const Color(0xFF94A3B8), letterSpacing: 0.5))),
          ],
        ),
        const SizedBox(width: 20),
        const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          child: GlobalUserAvatar(radius: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(patient, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5)),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.videocam_rounded, color: primaryColor, size: 18),
        ),
      ],
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
