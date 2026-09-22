import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../core/user_facing_errors.dart';
import 'patient_providers.dart';

class EmergencyWaitingScreen extends ConsumerStatefulWidget {
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
  ConsumerState<EmergencyWaitingScreen> createState() =>
      _EmergencyWaitingScreenState();
}

class _EmergencyWaitingScreenState
    extends ConsumerState<EmergencyWaitingScreen> {
  RealtimeChannel? _appointmentChannel;
  RealtimeChannel? _doctorStatusChannel;

  String _currentStatus = 'emergency_request';
  bool _navigated = false;

  int _elapsedSeconds = 0;
  int _doctorRemainingSeconds = 3 * 60;
  Timer? _patientTimer;
  Timer? _doctorTimer;

  final List<String> _connectionSteps = [
    'Emergency request submitted',
    'Scanning for available doctors',
    'Sending secure notification to doctor',
    'Waiting for doctor response',
    'Doctor verifying credentials',
  ];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _startTimers();
    _subscribeToAppointment();
    _subscribeToDoctorStatus();
    _doctorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _doctorRemainingSeconds--;
        if (_doctorRemainingSeconds <= 0) {
          timer.cancel();
          _declineByTimeout();
        }
      });
    });
    _patientTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _elapsedSeconds++);
    });
  }

  void _startTimers() {}

  void _subscribeToAppointment() {
    _appointmentChannel = supabase
        .channel('emergency:${widget.appointmentId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.appointmentId,
          ),
          callback: _handleAppointmentUpdate,
        )
        .subscribe();
  }

  void _subscribeToDoctorStatus() {
    _doctorStatusChannel = supabase
        .channel('doctor_status:${widget.doctorId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.doctorId,
          ),
          callback: _handleDoctorStatusUpdate,
        )
        .subscribe();
  }

  void _handleDoctorUpdate(PostgresChangePayload payload) {
    final status = payload.newRecord['status'] as String?;
    if (status != null && mounted) {
      setState(() => _currentStatus = status);
    }
  }

  void _handleDoctorStatusUpdate(PostgresChangePayload payload) {
    final isOnline = payload.newRecord['is_online'] as bool? ?? false;
    final isActive = isOnline;
    if (kDebugMode) debugPrint('Doctor online: $isActive');
  }

  void _handleAppointmentUpdate(PostgresChangePayload payload) {
    final newRecord = payload.newRecord;
    final status = newRecord['status'] as String? ?? '';
    final paymentStatus = newRecord['payment_status'] as String? ?? '';

    if (!mounted || _navigated) return;

    setState(() {
      _currentStatus = status;
      _doctorTimer?.cancel();
    });

    if (status == 'emergency_declined') {
      _showDeclinedDialog();
    } else if (status == 'ongoing' || paymentStatus == 'completed') {
      _navigated = true;
      context.go('/consultation/${widget.appointmentId}', extra: {
        'doctorName': widget.doctorName,
        'specialty': null,
        'durationMinutes': widget.durationMinutes,
      });
    }
  }

  void _declineByTimeout() {
    _showDeclinedDialog();
  }

  void _showDeclinedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.emergency_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.requestExpired,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.requestExpiredMessage,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondaryOf(context),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resendEmergencyRequest();
            },
            child: Text(
              AppLocalizations.of(context)!.sendAgain,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/doctor-details', extra: {
                'id': widget.doctorId,
                'name': widget.doctorName,
                'specialty': '',
                'isEmergency': true,
              });
            },
            child: Text(
              AppLocalizations.of(context)!.viewDoctor,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/patient_dashboard');
            },
            child: Text(
              AppLocalizations.of(context)!.goHome,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resendEmergencyRequest() async {
    try {
      await supabase.from('appointments').update({
        'status': 'emergency_request',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.appointmentId);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to resend: $e');
    }
  }

  @override
  void dispose() {
    _appointmentChannel?.unsubscribe();
    _doctorStatusChannel?.unsubscribe();
    _patientTimer?.cancel();
    _doctorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      _buildPulsingCircle(context),
                      const SizedBox(height: 40),
                      _buildDoctorInfo(context),
                      const SizedBox(height: 48),
                      _buildConnectionSteps(context),
                      const SizedBox(height: 32),
                      _buildCountdownTimer(context),
                      const SizedBox(height: 32),
                      _buildTipsSection(context),
                      const SizedBox(height: 32),
                      _buildFeeSummary(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.go('/patient_dashboard'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimaryOf(context),
                size: 20,
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context)!.emergencyMode,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildPulsingCircle(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          width: 160 + (_elapsedSeconds % 3) * 20.0,
          height: 160 + (_elapsedSeconds % 3) * 20.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withValues(alpha: 0.05),
            border: Border.all(
              color: AppColors.error.withValues(
                alpha: 0.2 + (_elapsedSeconds % 3) * 0.1,
              ),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.emergency_rounded,
                color: AppColors.error,
                size: 48,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          AppLocalizations.of(context)!.searchingDoctors,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.searchingDoctorsMessage,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiaryOf(context),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDoctorInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.minutesReview,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppLocalizations.of(context)!.pending,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionSteps(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.connectionProgress,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_connectionSteps.length, (index) {
          final isComplete = index < _currentStep;
          final isCurrent = index == _currentStep;
          final isPending = index > _currentStep;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? AppColors.success
                        : isCurrent
                            ? AppColors.error
                            : AppColors.surfaceAltOf(context),
                    shape: BoxShape.circle,
                  ),
                  child: isComplete
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.textInverse,
                          size: 14,
                        )
                      : isCurrent
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textInverse,
                              ),
                            )
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _connectionSteps[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isPending
                          ? AppColors.textTertiaryOf(context)
                          : AppColors.textPrimaryOf(context),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCountdownTimer(BuildContext context) {
    final minutes = (_doctorRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_doctorRemainingSeconds % 60).toString().padLeft(2, '0');
    final progress = _doctorRemainingSeconds / (3 * 60);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.doctorRespondTime,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.borderLightOf(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _doctorRemainingSeconds > 60
                          ? AppColors.warning
                          : AppColors.error,
                    ),
                    strokeWidth: 6,
                  ),
                ),
                Text(
                  '$minutes:$seconds',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _doctorRemainingSeconds > 60
                        ? AppColors.textPrimaryOf(context)
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.whileYouWait,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem(context, AppLocalizations.of(context)!.tipSymptoms),
          _buildTipItem(context, AppLocalizations.of(context)!.tipRelax),
          _buildTipItem(context, AppLocalizations.of(context)!.tipConnection),
          _buildTipItem(context, AppLocalizations.of(context)!.tipSecure),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondaryOf(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeSummary(BuildContext context) {
    final baseFee = widget.totalAmount / 5;
    final emergencyFee = widget.totalAmount;
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
            AppLocalizations.of(context)!.feeBreakdown,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          _buildFeeRow(context, AppLocalizations.of(context)!.baseConsultationFee, baseFee),
          _buildFeeRow(context, AppLocalizations.of(context)!.emergencyPremium, emergencyFee),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.dividerOf(context)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.totalEstimated,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              Text(
                '₦${widget.totalAmount.toInt()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: AppColors.textTertiaryOf(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.emergencyPaymentNote,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiaryOf(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(BuildContext context, String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          Text(
            '₦${amount.toInt()}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
