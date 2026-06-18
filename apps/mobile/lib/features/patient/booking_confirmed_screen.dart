import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/generic_user_avatar.dart';


class BookingConfirmedScreen extends StatelessWidget {
  final double? consultationFee;
  final String? doctorName;
  final String? doctorSpecialty;

  const BookingConfirmedScreen({super.key, this.consultationFee, this.doctorName, this.doctorSpecialty});

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final isEmergency = state.uri.queryParameters['emergency'] == 'true';
    final primaryColor = isEmergency ? const Color(0xFFEF4444) : const Color(0xFF0F62FE);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background mesh
          Positioned(
            top: -150,
            right: -100,
            child: _MeshCircle(color: primaryColor.withValues(alpha: 0.08), size: 500),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildSuccessHeader(isEmergency, primaryColor),
                  const SizedBox(height: 40),
                  _buildSectionTitle('MEDICAL SPECIALIST'),
                  const SizedBox(height: 16),
                  _buildDoctorCard(primaryColor),
                  const SizedBox(height: 32),
                  _buildSectionTitle('SESSION DETAILS'),
                  const SizedBox(height: 16),
                  _buildConsultationCard(primaryColor),
                  const SizedBox(height: 32),
                  _buildSectionTitle('PAYMENT RECEIPT'),
                  const SizedBox(height: 16),
                  _buildPaymentCard(primaryColor),
                  const SizedBox(height: 32),
                  _buildSupportBanner(),
                  const SizedBox(height: 40),
                  _buildActionButtons(context, primaryColor),
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
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.5),
    );
  }

  Widget _buildSuccessHeader(bool isEmergency, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: isEmergency ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: (isEmergency ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 32),
        Text(
          isEmergency ? 'Emergency Consult\nConfirmed' : 'Booking\nConfirmed!',
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1.1, letterSpacing: -1.5),
        ),
        const SizedBox(height: 12),
        Text(
          isEmergency ? 'Your priority medical session is scheduled for immediate connection.' : 'Your appointment has been successfully scheduled and verified.',
          style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w500, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          const GenericUserAvatar(radius: 32, avatarUrl: null),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctorName ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
                Text(doctorSpecialty ?? 'Specialist', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.videocam_rounded, color: primaryColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today_rounded, 'Date', 'Today, 21 May 2024'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          _buildInfoRow(Icons.access_time_rounded, 'Time', '11:00 AM (30 Mins)'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Icon(Icons.flash_on_rounded, color: Color(0xFF10B981), size: 16),
                SizedBox(width: 12),
                Text('Connecting automatically in 04:58', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildPaymentCard(Color primaryColor) {
    final fee = consultationFee ?? 0;
    final feeStr = fee.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        children: [
          _buildPriceRow('Consultation Fee', '₦$feeStr'),
          const SizedBox(height: 12),
          _buildPriceRow('Platform Service', '₦0.00', isSpecial: true),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
              Text('₦$feeStr', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: primaryColor)),
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

  Widget _buildSupportBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(24)),
      child: const Row(
        children: [
          Icon(Icons.headset_mic_rounded, color: Color(0xFF64748B), size: 20),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need assistance?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                Text('Our care team is available 24/7', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => context.go('/patient_dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt download coming soon')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('Download Digital Receipt', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
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
