import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/providers.dart';
import '../../core/supabase_locator.dart';
import '../../shared/widgets/generic_user_avatar.dart';

class DoctorEmergencyRequestScreen extends ConsumerStatefulWidget {
  final String appointmentId;
  final String? patientId;
  final String patientName;
  final int durationMinutes;
  final double totalAmount;

  const DoctorEmergencyRequestScreen({
    super.key,
    required this.appointmentId,
    this.patientId,
    required this.patientName,
    required this.durationMinutes,
    required this.totalAmount,
  });

  @override
  ConsumerState<DoctorEmergencyRequestScreen> createState() => _DoctorEmergencyRequestScreenState();
}

class _DoctorEmergencyRequestScreenState extends ConsumerState<DoctorEmergencyRequestScreen>
    with SingleTickerProviderStateMixin {
  late Timer _countdownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _secondsRemaining = 180; // 3 minutes
  bool _isProcessing = false;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _setupRealtimeSubscription();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _pulseController.dispose();
    _subscription?.unsubscribe();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _setupRealtimeSubscription() {
    _subscription = Supabase.instance.client
        .channel('doctor:emergency:${widget.appointmentId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.appointmentId,
          ),
          callback: (payload) {
            if (!mounted) return;
            final newStatus = payload.newRecord['status'] as String?;
            if (newStatus == 'emergency_declined') {
              _countdownTimer.cancel();
              _showPatientCancelled();
            }
          },
        )
        .subscribe();
  }

  void _handleTimeout() {
    // Auto-decline if doctor didn't respond
    _respondToRequest(false);
  }

  void _showPatientCancelled() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Patient has cancelled this emergency request.'),
        backgroundColor: AppColors.warning,
      ),
    );
    context.go('/doctor_dashboard');
  }

  Future<void> _respondToRequest(bool accept) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _countdownTimer.cancel();

    try {
      final newStatus = accept ? 'emergency_accepted' : 'emergency_declined';
      await Supabase.instance.client
          .from('appointments')
          .update({
            'status': newStatus,
            'is_doctor_approved': accept,
            if (!accept) 'accepted_at': null,
          })
          .eq('id', widget.appointmentId);

      ref.invalidate(emergencyRequestsProvider);
      ref.invalidate(upcomingAppointmentsProvider);

      // Notify patient (skip in-app for guests — patient_id is null)
      if (widget.patientId != null && widget.patientId!.isNotEmpty) {
        try {
          await Supabase.instance.client.from('notifications').insert({
            'user_id': widget.patientId,
            'title': accept ? 'Emergency Request Accepted' : 'Emergency Request Declined',
            'message': accept
                ? 'Dr. has accepted your emergency consultation request. Please proceed with payment.'
                : 'Unfortunately, Dr. is unable to take your case right now.',
            'type': 'appointment',
            'is_read': false,
            'metadata': {'appointment_id': widget.appointmentId},
          });
        } catch (_) {}
      }

      // Dispatch FCM push via web notification pipeline
      if (widget.patientId != null && widget.patientId!.isNotEmpty) {
        try {
          final siteUrl = const String.fromEnvironment('NEXT_PUBLIC_SITE_URL', defaultValue: 'https://premoncare.com');
          final session = supabase.auth.currentSession;
          await http.post(
            Uri.parse('$siteUrl/api/notifications/dispatch'),
            headers: {
              'Content-Type': 'application/json',
              if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
            },
            body: jsonEncode({
              'userId': widget.patientId,
              'title': accept ? 'Emergency Request Accepted' : 'Emergency Request Declined',
              'message': accept
                  ? 'Dr. has accepted your emergency consultation request. Please proceed with payment.'
                  : 'Unfortunately, Dr. is unable to take your case right now.',
              'type': 'appointment',
            }),
          );
        } catch (_) {}
      }

      if (mounted) {
        if (accept) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency request accepted. Patient will proceed with payment.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        context.go('/doctor_dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String get _timerText {
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color get _timerColor => _secondsRemaining > 120
      ? AppColors.error
      : _secondsRemaining > 60
          ? AppColors.warning
          : AppColors.error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Urgent red pulse background
          Positioned(
            top: -300,
            left: -100,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 600,
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.04 * _pulseAnimation.value),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Urgent badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.textInverse, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'EMERGENCY REQUEST',
                          style: TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Timer
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: _secondsRemaining / 180,
                            strokeWidth: 8,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
                          ),
                        ),
                        Text(
                          _timerText,
                          style: AppTypography.h1.copyWith(
                            fontSize: 36,
                            color: _timerColor,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Time remaining to respond',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 40),

                  // Patient card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                      boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 20)],
                    ),
                    child: Row(
                      children: [
                        const GenericUserAvatar(radius: 30, avatarUrl: null),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.patientName,
                                style: AppTypography.h4.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.durationMinutes}-minute emergency consultation',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '₦${widget.totalAmount.toInt()}',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'If you accept, the patient will proceed with payment and you will be connected immediately.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.primary, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: OutlinedButton(
                            onPressed: _isProcessing ? null : () => _respondToRequest(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Decline', style: TextStyle(fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : () => _respondToRequest(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.textInverse,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 2),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text('Accept Emergency', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
