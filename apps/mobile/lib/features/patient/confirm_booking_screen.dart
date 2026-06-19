import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/supabase_locator.dart';
import '../../core/user_facing_errors.dart';
import '../../shared/widgets/generic_user_avatar.dart';

class ConfirmBookingScreen extends StatefulWidget {
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
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  bool _isLoading = false;
  String? _error;

  String get _amountStr => widget.totalAmount
      .toInt()
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Color get _primaryColor => widget.isEmergency ? const Color(0xFFEF4444) : const Color(0xFF0F62FE);

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

      await supabase.from('appointments').insert({
        'patient_id': userId,
        'doctor_id': widget.doctorId,
        'appointment_date': appointmentDate,
        'duration_minutes': widget.durationMinutes,
        'status': widget.isEmergency ? 'emergency_pending' : 'pending',
        'is_emergency': widget.isEmergency,
        'total_amount': widget.totalAmount,
        'is_patient_approved': true,
        'is_doctor_approved': false,
        if (guestToken != null) 'metadata': {
          'is_guest': true,
          'guest_token': guestToken,
          'pricing_multiplier': 5,
        },
      });

      // Send in-app notification to doctor
      try {
        await supabase.from('notifications').insert({
          'user_id': widget.doctorId,
          'title': widget.isEmergency ? '🚨 Emergency Consultation Request' : 'New Appointment Request',
          'message': 'A patient has requested a ${widget.isEmergency ? "EMERGENCY " : ""}${widget.durationMinutes}-minute consultation.',
          'type': 'appointment',
          'is_read': false,
        });
      } catch (_) {
        // Non-fatal: notification failure shouldn't block booking
      }

      if (mounted) {
        context.go(
          widget.isEmergency ? '/booking-confirmed?emergency=true' : '/booking-confirmed',
          extra: {
            'consultationFee': widget.totalAmount,
            'doctorName': widget.doctorName,
            'doctorId': widget.doctorId,
          },
        );
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
      backgroundColor: const Color(0xFFF8FAFC),
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
                        _buildSectionTitle('SPECIALIST REVIEW'),
                        const SizedBox(height: 16),
                        _buildDoctorMiniCard(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('APPOINTMENT TIMELINE'),
                        const SizedBox(height: 16),
                        _buildTimelineDetails(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('FINANCIAL SUMMARY'),
                        const SizedBox(height: 16),
                        _buildPaymentSummary(),
                        const SizedBox(height: 32),
                        if (widget.isEmergency) _buildEmergencyWarning(),
                        const SizedBox(height: 32),
                        _buildSecurityNote(),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.w600)),
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.5));
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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 20),
            ),
          ),
          Text(
            widget.isEmergency ? 'Emergency Review' : 'Final Review',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildDoctorMiniCard() {
    final displayName = widget.doctorName.startsWith('Dr.') ? widget.doctorName : 'Dr. ${widget.doctorName}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          const GenericUserAvatar(radius: 28, avatarUrl: null),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
                Text('${widget.durationMinutes} min session', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('VERIFIED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDetails() {
    final now = DateTime.now().add(const Duration(hours: 1));
    final end = now.add(Duration(minutes: widget.durationMinutes));
    final dateStr = '${now.day} ${_monthName(now.month)} ${now.year}';
    final timeStr = '${_fmt(now.hour)}:${_fmt(now.minute)} – ${_fmt(end.hour)}:${_fmt(end.minute)}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        children: [
          _buildTimelineRow(Icons.calendar_today_rounded, 'Schedule', dateStr),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          _buildTimelineRow(Icons.access_time_rounded, 'Duration', '${widget.durationMinutes} minutes'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          _buildTimelineRow(Icons.videocam_rounded, 'Timing', timeStr),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          _buildTimelineRow(Icons.videocam_rounded, 'Consult Type', widget.isEmergency ? 'Emergency Session' : 'HD Video Session'),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _primaryColor, size: 18),
        ),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildPriceRow('Consultation Fee', '₦$_amountStr'),
          const SizedBox(height: 12),
          _buildPriceRow('Platform Service', 'FREE', isSpecial: true),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Payable', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
              Text('₦$_amountStr', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: _primaryColor, letterSpacing: -0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isSpecial = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isSpecial ? const Color(0xFF10B981) : const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildEmergencyWarning() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.flash_on_rounded, color: Color(0xFFEF4444)),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Emergency mode triggers instant notification to the specialist for immediate clinical attention.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return const Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_rounded, size: 14, color: Color(0xFF94A3B8)),
          SizedBox(width: 8),
          Text('End-to-end encrypted booking & clinical records',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
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
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, -10))],
        ),
        child: SizedBox(
          height: 64,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              disabledBackgroundColor: _primaryColor.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 20),
                      const SizedBox(width: 12),
                      const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 20, color: Colors.white24),
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
