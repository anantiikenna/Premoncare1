import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../core/user_facing_errors.dart';
import '../../shared/widgets/generic_user_avatar.dart';
import 'patient_providers.dart';

class ConfirmBookingScreen extends ConsumerStatefulWidget {
  final String doctorId;
  final String doctorName;
  final int durationMinutes;
  final double totalAmount;
  final bool isEmergency;

  const ConfirmBookingScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.durationMinutes,
    required this.totalAmount,
    required this.isEmergency,
  });

  @override
  ConsumerState<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends ConsumerState<ConfirmBookingScreen> {
  bool _isLoading = false;
  String? _error;

  String get _amountStr => widget.totalAmount
      .toInt()
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Color get _primaryColor => widget.isEmergency ? AppColors.error : AppColors.primary;

  Future<void> _confirmBooking() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null && !widget.isEmergency) {
        throw Exception('Not authenticated. Please log in again.');
      }

      final appointmentDate = (widget.isEmergency ? DateTime.now() : DateTime.now().add(const Duration(hours: 1))).toUtc().toIso8601String();
      final guestToken = userId == null ? 'guest_${DateTime.now().millisecondsSinceEpoch}' : null;
      if (guestToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('premon_guest_token', guestToken);
      }

      final insertPayload = {
        'patient_id': userId,
        'doctor_id': widget.doctorId,
        'appointment_date': appointmentDate,
        'duration_minutes': widget.durationMinutes,
        'status': widget.isEmergency ? 'emergency_request' : 'pending',
        'is_emergency': widget.isEmergency,
        'total_amount': widget.totalAmount,
        'is_patient_approved': true,
        'is_doctor_approved': false,
        if (guestToken != null) 'metadata': {
          'is_guest': true,
          'guest_token': guestToken,
          'pricing_multiplier': 5,
        },
      };

      final insertResponse = await supabase.from('appointments').insert(insertPayload).select('id').single();
      final appointmentId = insertResponse['id'] as String;

      ref.invalidate(patientAppointmentsProvider);

      try {
        await supabase.from('notifications').insert({
          'user_id': widget.doctorId,
          'title': widget.isEmergency ? 'EMERGENCY Consultation Request' : 'New Appointment Request',
          'message': 'A patient has requested a ${widget.isEmergency ? "EMERGENCY " : ""}${widget.durationMinutes}-minute consultation.',
          'type': 'appointment',
          'is_read': false,
          'metadata': {'appointment_id': appointmentId},
        });
      } catch (_) {}

      try {
        final siteUrl = const String.fromEnvironment('NEXT_PUBLIC_SITE_URL', defaultValue: 'https://premoncare.com');
        await http.post(
          Uri.parse('$siteUrl/api/notifications/dispatch'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': widget.doctorId,
            'title': widget.isEmergency ? 'EMERGENCY Consultation Request' : 'New Appointment Request',
            'message': 'A patient has requested a ${widget.isEmergency ? "EMERGENCY " : ""}${widget.durationMinutes}-minute consultation. Fee: ₦${widget.totalAmount.toInt()}',
            'type': 'appointment',
            'sendEmail': widget.isEmergency,
            'emailTemplate': 'doctorAppointment',
            'emailData': {
              'doctorId': widget.doctorId,
              'duration': widget.durationMinutes,
              'amount': widget.totalAmount,
              'isEmergency': widget.isEmergency,
            },
          }),
        );
      } catch (_) {}

      if (mounted) {
        if (widget.isEmergency) {
          context.go(
            '/emergency-waiting',
            extra: {
              'appointmentId': appointmentId,
              'doctorId': widget.doctorId,
              'doctorName': widget.doctorName,
              'totalAmount': widget.totalAmount,
              'durationMinutes': widget.durationMinutes,
            },
          );
        } else {
          context.go(
            '/booking-confirmed',
            extra: {
              'consultationFee': widget.totalAmount,
              'doctorName': widget.doctorName,
              'doctorId': widget.doctorId,
            },
          );
        }
      }
    } catch (e, stackTrace) {
      logHandledError('Booking confirmation failed', e, stackTrace);
      if (mounted) {
        setState(() {
          _error = userFacingError(e, fallback: 'We could not confirm this booking. Please try again.');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: _MeshCircle(color: _primaryColor.withValues(alpha: 0.05), size: 400),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, 'SPECIALIST REVIEW'),
                        const SizedBox(height: 16),
                        _buildDoctorMiniCard(context),
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, 'APPOINTMENT TIMELINE'),
                        const SizedBox(height: 16),
                        _buildTimelineDetails(context),
                        const SizedBox(height: 32),
                        _buildSectionTitle(context, 'FINANCIAL SUMMARY'),
                        const SizedBox(height: 16),
                        _buildPaymentSummary(context),
                        const SizedBox(height: 32),
                        if (widget.isEmergency) _buildEmergencyWarning(context),
                        const SizedBox(height: 32),
                        _buildSecurityNote(context),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.errorLightOf(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: AppColors.error, size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildBottomAction(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondaryOf(context), letterSpacing: 1.5));
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderOf(context))),
              child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context), size: 20),
            ),
          ),
          Text(
            widget.isEmergency ? 'Emergency Review' : 'Final Review',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildDoctorMiniCard(BuildContext context) {
    final displayName = widget.doctorName.startsWith('Dr.') ? widget.doctorName : 'Dr. ${widget.doctorName}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Row(
        children: [
          const GenericUserAvatar(radius: 28, avatarUrl: null),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimaryOf(context))),
                Text('${widget.durationMinutes} min session', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('VERIFIED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDetails(BuildContext context) {
    final now = DateTime.now().add(const Duration(hours: 1));
    final end = now.add(Duration(minutes: widget.durationMinutes));
    final dateStr = '${now.day} ${_monthName(now.month)} ${now.year}';
    final timeStr = '${_fmt(now.hour)}:${_fmt(now.minute)} – ${_fmt(end.hour)}:${_fmt(end.minute)}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Column(
        children: [
          _buildTimelineRow(context, Icons.calendar_today_rounded, 'Schedule', dateStr),
          Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.dividerOf(context))),
          _buildTimelineRow(context, Icons.access_time_rounded, 'Duration', '${widget.durationMinutes} minutes'),
          Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.dividerOf(context))),
          _buildTimelineRow(context, Icons.videocam_rounded, 'Timing', timeStr),
          Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.dividerOf(context))),
          _buildTimelineRow(context, Icons.videocam_rounded, 'Consult Type', widget.isEmergency ? 'Emergency Session' : 'HD Video Session'),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _primaryColor, size: 18),
        ),
        const SizedBox(width: 16),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textTertiaryOf(context))),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
      ],
    );
  }

  Widget _buildPaymentSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildPriceRow(context, 'Consultation Fee', '₦$_amountStr'),
          const SizedBox(height: 12),
          _buildPriceRow(context, 'Platform Service', 'FREE', isSpecial: true),
          Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: AppColors.dividerOf(context))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Payable', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimaryOf(context))),
              Text('₦$_amountStr', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: _primaryColor, letterSpacing: -0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String value, {bool isSpecial = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryOf(context))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isSpecial ? AppColors.success : AppColors.textPrimaryOf(context))),
      ],
    );
  }

  Widget _buildEmergencyWarning(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.flash_on_rounded, color: AppColors.error),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Emergency mode triggers instant notification to the specialist for immediate clinical attention.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.error, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_rounded, size: 14, color: AppColors.textTertiaryOf(context)),
          const SizedBox(width: 8),
          Text('End-to-end encrypted booking & clinical records',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiaryOf(context), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 40, offset: const Offset(0, -10))],
        ),
        child: SizedBox(
          height: 64,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: AppColors.textInverse,
              elevation: 0,
              disabledBackgroundColor: _primaryColor.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 20),
                      const SizedBox(width: 12),
                      const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 20, color: AppColors.dividerOf(context)),
                      const SizedBox(width: 12),
                      Text('₦$_amountStr', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _fmt(int n) => n.toString().padLeft(2, '0');
  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _MeshCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _MeshCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)],
      ),
    );
  }
}
