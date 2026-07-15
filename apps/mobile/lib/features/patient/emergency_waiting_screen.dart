import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../shared/widgets/generic_user_avatar.dart';

class EmergencyWaitingScreen extends StatefulWidget {
  final String appointmentId;
  final String doctorId;
  final String doctorName;
  final double totalAmount;
  final int durationMinutes;

  const EmergencyWaitingScreen({
    super.key,
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    required this.totalAmount,
    required this.durationMinutes,
  });

  @override
  State<EmergencyWaitingScreen> createState() => _EmergencyWaitingScreenState();
}

class _EmergencyWaitingScreenState extends State<EmergencyWaitingScreen>
    with SingleTickerProviderStateMixin {
  late Timer _countdownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _secondsRemaining = 180; // 3 minutes
  String _status = 'waiting'; // waiting, accepted, declined, timeout
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _setupRealtimeSubscription();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
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
        .channel('emergency:waiting:${widget.appointmentId}')
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
            if (newStatus == 'emergency_accepted') {
              _handleAccepted();
            } else if (newStatus == 'emergency_declined') {
              _handleDeclined();
            }
          },
        )
        .subscribe();
  }

  void _handleAccepted() {
    _countdownTimer.cancel();
    setState(() => _status = 'accepted');
    // Navigate to booking confirmed after showing success animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/booking-confirmed?emergency=true', extra: {
          'consultationFee': widget.totalAmount,
          'doctorName': widget.doctorName,
          'doctorId': widget.doctorId,
        });
      }
    });
  }

  void _handleDeclined() {
    _countdownTimer.cancel();
    setState(() => _status = 'declined');
  }

  void _handleTimeout() {
    setState(() => _status = 'timeout');
    Supabase.instance.client
        .from('appointments')
        .update({'status': 'emergency_declined'})
        .eq('id', widget.appointmentId)
        .then((_) {})
        .catchError((_) {});
  }

  String get _timerText {
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background pulse effect
          Positioned(
            top: -200,
            left: -100,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_status == 'accepted'
                            ? AppColors.success
                            : _status == 'declined' || _status == 'timeout'
                                ? AppColors.error
                                : AppColors.primary)
                        .withValues(alpha: 0.05 * _pulseAnimation.value),
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
                  const SizedBox(height: 40),
                  _buildStatusHeader(),
                  const SizedBox(height: 48),
                  _buildDoctorCard(),
                  const SizedBox(height: 48),
                  _buildTimerSection(),
                  const SizedBox(height: 32),
                  _buildStatusMessage(),
                  const Spacer(),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final color = _status == 'accepted'
                ? AppColors.success
                : _status == 'declined' || _status == 'timeout'
                    ? AppColors.error
                    : AppColors.primary;
            return Transform.scale(
              scale: _status == 'waiting' ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                ),
                child: Icon(
                  _status == 'accepted'
                      ? Icons.check_rounded
                      : _status == 'declined' || _status == 'timeout'
                          ? Icons.close_rounded
                          : Icons.hourglass_top_rounded,
                  color: color,
                  size: 36,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          _status == 'accepted'
              ? 'Doctor Accepted!'
              : _status == 'declined'
                  ? 'Doctor Unavailable'
                  : _status == 'timeout'
                      ? 'Request Expired'
                      : 'Connecting You...',
          style: AppTypography.h3.copyWith(
            color: _status == 'accepted'
                ? AppColors.success
                : _status == 'declined' || _status == 'timeout'
                    ? AppColors.error
                    : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _status == 'waiting'
              ? 'Sending your emergency request to Dr. ${widget.doctorName.replaceFirst('Dr. ', '')}...'
              : _status == 'accepted'
                  ? 'Dr. ${widget.doctorName.replaceFirst('Dr. ', '')} is ready for your consultation.'
                  : _status == 'declined'
                      ? 'The doctor is currently unavailable. Let us find you another specialist.'
                      : 'The request timed out. We\'ll find you another available doctor.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          GenericUserAvatar(radius: 36, avatarUrl: null),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  style: AppTypography.h4.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Emergency Consultation',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (_status == 'accepted')
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    if (_status != 'waiting') return const SizedBox.shrink();

    return Column(
      children: [
        // Circular progress
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _secondsRemaining / 180,
                  strokeWidth: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _secondsRemaining > 60
                        ? AppColors.primary
                        : _secondsRemaining > 30
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                ),
              ),
              Text(
                _timerText,
                style: AppTypography.h2.copyWith(
                  fontSize: 28,
                  color: _secondsRemaining > 60
                      ? AppColors.textPrimary
                      : _secondsRemaining > 30
                          ? AppColors.warning
                          : AppColors.error,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Waiting for doctor response',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildStatusMessage() {
    if (_status == 'waiting') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'The doctor will receive an urgent notification. You\'ll be connected immediately once they accept.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.primary, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    if (_status == 'declined' || _status == 'timeout') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _status == 'declined'
                    ? 'Dr. ${widget.doctorName.replaceFirst('Dr. ', '')} is unable to take your case right now.'
                    : 'No response received within the time limit.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.error, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButtons() {
    if (_status == 'waiting') {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: () async {
            _countdownTimer.cancel();
            // Cancel the appointment
            await Supabase.instance.client
                .from('appointments')
                .update({'status': 'emergency_declined'})
                .eq('id', widget.appointmentId);
            if (mounted) context.go('/doctor-search');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
    }

    if (_status == 'accepted') {
      return const SizedBox.shrink(); // Auto-navigates after delay
    }

    // Declined or timeout — show retry options
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.go('/doctor-search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Find Another Doctor', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textInverse)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => context.go('/doctor-search'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
