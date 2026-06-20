import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_locator.dart';
import '../../shared/widgets/generic_user_avatar.dart';


class BookingConfirmedScreen extends StatefulWidget {
  final double? consultationFee;
  final String? doctorName;
  final String? doctorSpecialty;
  final String? doctorId;

  const BookingConfirmedScreen({super.key, this.consultationFee, this.doctorName, this.doctorSpecialty, this.doctorId});

  @override
  State<BookingConfirmedScreen> createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen> {
  String? _paymentInstructions;

  @override
  void initState() {
    super.initState();
    _fetchPaymentInstructions();
  }

  Future<void> _fetchPaymentInstructions() async {
    if (widget.doctorId == null) return;
    try {
      final data = await supabase
          .from('profiles')
          .select('payment_instructions')
          .eq('id', widget.doctorId!)
          .single();
      if (mounted) {
        setState(() {
          _paymentInstructions = data['payment_instructions'] as String?;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final isEmergency = state.uri.queryParameters['emergency'] == 'true';
    final primaryColor = isEmergency ? const Color(0xFFEF4444) : const Color(0xFF0F62FE);
    final extra = state.extra as Map<String, dynamic>?;
    final fee = widget.consultationFee ?? extra?['consultationFee'] ?? 0;
    final name = widget.doctorName ?? extra?['doctorName'] ?? '';
    final docId = widget.doctorId ?? extra?['doctorId'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
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
                  _buildDoctorCard(primaryColor, name),
                  const SizedBox(height: 32),
                  _buildSectionTitle('SESSION DETAILS'),
                  const SizedBox(height: 16),
                  _buildConsultationCard(primaryColor, isEmergency),
                  const SizedBox(height: 32),
                  if (isEmergency) ...[
                    _buildSectionTitle('P2P PAYMENT INSTRUCTIONS'),
                    const SizedBox(height: 16),
                    _buildPaymentInstructionsCard(fee),
                    const SizedBox(height: 32),
                  ],
                  _buildSectionTitle('PAYMENT RECEIPT'),
                  const SizedBox(height: 16),
                  _buildPaymentCard(primaryColor, fee),
                  const SizedBox(height: 32),
                  _buildSupportBanner(),
                  const SizedBox(height: 40),
                  _buildActionButtons(context, primaryColor, isEmergency, docId),
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
          isEmergency ? 'Your priority medical session is scheduled for immediate connection. Complete payment to start.' : 'Your appointment has been successfully scheduled and verified.',
          style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w500, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(Color primaryColor, String name) {
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
                Text(name.isNotEmpty ? name : '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
                const Text('Specialist', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w700)),
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

  Widget _buildConsultationCard(Color primaryColor, bool isEmergency) {
    final now = DateTime.now();
    final dateStr = '${now.day} ${_monthName(now.month)} ${now.year}';
    final timeStr = '${_fmt(now.hour)}:${_fmt(now.minute)}';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today_rounded, 'Date', dateStr),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          _buildInfoRow(Icons.access_time_rounded, 'Time', timeStr),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Icon(Icons.flash_on_rounded, color: primaryColor, size: 16),
                const SizedBox(width: 12),
                Text(
                  isEmergency ? 'Emergency session — pay now to connect' : 'Connecting automatically...',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: primaryColor),
                ),
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

  Widget _buildPaymentInstructionsCard(double fee) {
    final feeStr = fee.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 12),
              const Text('P2P Payment Instructions', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFB91C1C))),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Pay the emergency fee below to start your consultation immediately:',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '₦$feeStr',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 36, color: Color(0xFFEF4444), letterSpacing: -1),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _paymentInstructions ?? 'Contact doctor for payment details',
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Once paid, the doctor will be alerted for immediate session startup.',
              style: TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Color primaryColor, double fee) {
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
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
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

  Widget _buildActionButtons(BuildContext context, Color primaryColor, bool isEmergency, String? docId) {
    return Column(
      children: [
        if (isEmergency)
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => context.push('/account-conversion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('Create Permanent Account', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
        if (isEmergency) const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => context.go(isEmergency ? '/login' : '/patient_dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(isEmergency ? 'Sign In to Continue' : 'Back to Dashboard', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
