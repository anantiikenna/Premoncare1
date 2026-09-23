import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/supabase_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers.dart';
import '../../shared/widgets/global_user_avatar.dart';
import 'package:mobile/features/doctor/propose_followup_dialog.dart';
import '../../core/app_colors.dart';
import '../../core/doctor_name_utils.dart';
import '../../l10n/app_localizations.dart';

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
          .select('full_name, title, is_online')
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
      // Fallback: try auth metadata if profile fetch fails
      if (mounted) {
        final user = supabase.auth.currentUser;
        final metaName = user?.userMetadata?['full_name'] as String?;
        final email = user?.email;
        if (metaName != null || email != null) {
          setState(() {
            _profileData = {
              'full_name': metaName ?? email?.split('@').first ?? 'Doctor',
              'title': 'Dr.',
              'is_online': false,
            };
          });
        }
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _sendHeartbeatPing();
    
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _sendHeartbeatPing();
    });
  }

  Future<void> _sendHeartbeatPing() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final shouldShowOnline = prefs.getBool('privacy_online_status') ?? true;
    if (!shouldShowOnline) {
      // Don't update online status if user disabled it
      return;
    }

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
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.notAuthenticatedPleaseLogIn)),
        );
      }
      return;
    }

    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final shouldShowOnline = prefs.getBool('privacy_online_status') ?? true;
    if (newStatus && !shouldShowOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.onlineStatusDisabledInPrivacy)),
        );
      }
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final response = await supabase.from('profiles').update({
        'is_online': newStatus,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId).select();

      if (mounted) {
        setState(() {
          _isOnline = newStatus;
        });

        if (newStatus) {
          _startHeartbeat();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.nowActiveForEmergencyConsult),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          _stopHeartbeat();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.emergencyPresenceTurnedOff),
              backgroundColor: AppColors.slate600,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('permission')
            ? AppLocalizations.of(context)!.permissionDeniedProfileSetup
            : AppLocalizations.of(context)!.failedToUpdatePresence(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
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
    const primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
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
                  _buildSectionTitle(AppLocalizations.of(context)!.performanceMetrics),
                  const SizedBox(height: 20),
                  _buildMetricsGrid(context, ref, primaryColor),
                  const SizedBox(height: 32),
                  _buildSectionTitle(AppLocalizations.of(context)!.clinicalWorkflow),
                  const SizedBox(height: 20),
                  _buildQuickActions(context, primaryColor),
                  const SizedBox(height: 32),
                  _buildSectionTitle(AppLocalizations.of(context)!.upcomingSessions),
                  const SizedBox(height: 20),
                  _buildScheduleList(context, ref, primaryColor),
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
    return Text(title, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildHeader() {
    final user = supabase.auth.currentUser;
    var fullName = _profileData?['full_name'] as String?;
    if (fullName == null || fullName.isEmpty) {
      fullName = user?.userMetadata?['full_name'] as String?;
    }
    if (fullName == null || fullName.isEmpty) {
      fullName = user?.email?.split('@').first;
    }

    final doctorName = formatDoctorName(
      _profileData?['title'] as String?,
      fullName,
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.practitionerHub, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(
                doctorName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0),
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
              final patientIdSuffix = (req['patient_id'] ?? '').toString();
              final lastFour = patientIdSuffix.substring((patientIdSuffix.length - 4).clamp(0, 99));
              final patientName = req['metadata']?['guest_token'] != null
                  ? AppLocalizations.of(context)!.emergencyGuest
                  : AppLocalizations.of(context)!.patientIdDisplay(lastFour);
              final duration = req['duration_minutes'] ?? 15;
              final amount = (req['total_amount'] as num?)?.toInt() ?? 0;
              final createdAt = req['created_at'] != null
                  ? DateTime.tryParse(req['created_at'])?.toLocal()
                  : null;
              final timeAgo = createdAt != null ? _timeAgo(createdAt, context) : '';

              return GestureDetector(
                onTap: () => context.push('/doctor-emergency-request', extra: {
                  'appointmentId': req['id'],
                  'patientId': req['patient_id'] as String?,
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
                        AppColors.error.withValues(alpha: 0.08),
                        AppColors.errorLightOf(context).withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: AppColors.textInverse, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                           AppLocalizations.of(context)!.emergencyRequest,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.error, letterSpacing: 1),
                        ),
                            const SizedBox(height: 4),
                            Text(
                              '$patientName • ${duration}min • ₦$amount',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context)),
                            ),
                            if (timeAgo.isNotEmpty)
                              Text(
                                timeAgo,
                                style: TextStyle(fontSize: 11, color: AppColors.textTertiaryOf(context)),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.viewLabel,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textInverse, letterSpacing: 0.5),
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

  String _timeAgo(DateTime dt, BuildContext context) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return AppLocalizations.of(context)!.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildPresenceSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: _isOnline ? 0.05 : 0),
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
              color: _isOnline ? AppColors.success : AppColors.textSecondaryOf(context),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isOnline ? AppLocalizations.of(context)!.onlineLabel : AppLocalizations.of(context)!.offlineLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: _isOnline ? AppColors.success : AppColors.textSecondaryOf(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 32,
            width: 52,
            child: Switch.adaptive(
              value: _isOnline,
              activeTrackColor: AppColors.success,
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
        gradient: LinearGradient(colors: [primaryColor, AppColors.info], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
              const Text('TOTAL CLINICAL REVENUE', style: TextStyle(color: AppColors.textInverse, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.textInverse.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Text('MONTHLY', style: TextStyle(color: AppColors.textInverse, fontSize: 9, fontWeight: FontWeight.w900)),
                    Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textInverse, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          revenueAsync.when(
            data: (revenue) => Text('₦${revenue.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textInverse, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
            loading: () => const SizedBox(height: 42, child: CircularProgressIndicator(color: AppColors.textInverse)),
            error: (_, _) => const Text('₦0.00', style: TextStyle(color: AppColors.textInverse, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
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
      decoration: BoxDecoration(color: AppColors.textInverse.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.textInverse, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildGlassButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppColors.textInverse.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.textInverse.withValues(alpha: 0.24))),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textInverse, fontSize: 11, fontWeight: FontWeight.w900)),
            const SizedBox(width: 6),
            Icon(icon, color: AppColors.textInverse, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, WidgetRef ref, Color primaryColor) {
    final metricsAsync = ref.watch(userProfileProvider);

    return metricsAsync.when(
      data: (metrics) {
        if (metrics == null) return const SizedBox.shrink();
        final patientsHelped = metrics['patients_helped']?.toString() ?? '0';
        final rating = (metrics['rating'] as num?)?.toStringAsFixed(1) ?? '0.0';
        final todaySessions = metrics['consultation_counts']?.toString() ?? '0';

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
                  _buildMetricCard(context, patientsHelped, AppLocalizations.of(context)!.totalPatients, primaryColor, Icons.people_rounded),
            _buildMetricCard(context, todaySessions, AppLocalizations.of(context)!.todaySessions, AppColors.success, Icons.calendar_today_rounded),
            _buildMetricCard(context, rating, AppLocalizations.of(context)!.clinicalRatingLabel, AppColors.primary, Icons.star_rounded),
            _buildMetricCard(context, '0', AppLocalizations.of(context)!.avgSession, AppColors.info, Icons.timer_outlined),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildMetricCard(BuildContext context, String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLightOf(context)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
              Icon(icon, color: color.withValues(alpha: 0.4), size: 20),
            ],
          ),
          const Spacer(),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Color primaryColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildActionItem(context, Icons.calendar_month_rounded, AppLocalizations.of(context)!.schedule, primaryColor, onTap: () => context.push('/doctor/schedule')),
          _buildActionItem(context, Icons.person_add_rounded, AppLocalizations.of(context)!.requests, AppColors.success, onTap: () => context.push('/appointments')),
          _buildActionItem(context, Icons.history_edu_rounded, AppLocalizations.of(context)!.followUp, AppColors.warning, onTap: () {
            showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => const ProposeFollowupDialog());
          }),
          _buildActionItem(context, Icons.medication_rounded, AppLocalizations.of(context)!.prescribe, AppColors.primary, onTap: () => context.push('/appointments')),
          _buildActionItem(context, Icons.verified_user_rounded, AppLocalizations.of(context)!.compliance, AppColors.info, onTap: () => context.push('/doctor/subscription')),
          _buildActionItem(context, Icons.payments_rounded, AppLocalizations.of(context)!.payments, AppColors.success, onTap: () => context.push('/doctor/payments')),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.15))), child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondaryOf(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(BuildContext context, WidgetRef ref, Color primaryColor) {
    final appointmentsAsync = ref.watch(upcomingAppointmentsProvider);

    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      padding: const EdgeInsets.all(24),
      child: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noUpcomingSessions, style: TextStyle(color: AppColors.textSecondaryOf(context))));
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
                  _buildScheduleItem(context, time, patientName, AppLocalizations.of(context)!.consultationLabel, isConfirmed, primaryColor),
                  if (!isLast) Divider(height: 32, color: AppColors.borderLightOf(context)),
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

  Widget _buildScheduleItem(BuildContext context, String time, String patient, String type, bool isConfirmed, Color primaryColor) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (isConfirmed ? AppColors.success : AppColors.textTertiaryOf(context)).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(isConfirmed ? 'CONFIRMED' : 'PENDING', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isConfirmed ? AppColors.success : AppColors.textTertiaryOf(context), letterSpacing: 0.5))),
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
              Text(patient, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
              const SizedBox(height: 2),
              Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondaryOf(context), letterSpacing: 0.5)),
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
