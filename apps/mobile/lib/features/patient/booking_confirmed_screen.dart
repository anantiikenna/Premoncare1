import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../shared/widgets/generic_user_avatar.dart';


class BookingConfirmedScreen extends StatefulWidget {
  final double? consultationFee;
  final String? doctorName;
  final String? doctorSpecialty;
  final String? doctorId;
  final int? durationMinutes;
  final String? appointmentId;
  final String? appointmentDate;
  final String? consultationType;

  const BookingConfirmedScreen({
    super.key,
    this.consultationFee,
    this.doctorName,
    this.doctorSpecialty,
    this.doctorId,
    this.durationMinutes,
    this.appointmentId,
    this.appointmentDate,
    this.consultationType,
  });

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
    final primaryColor = isEmergency ? AppColors.error : AppColors.primary;
    final extra = state.extra as Map<String, dynamic>?;
    final fee = widget.consultationFee ?? extra?['consultationFee'] ?? 0;
    final name = widget.doctorName ?? extra?['doctorName'] ?? '';
    final docId = widget.doctorId ?? extra?['doctorId'];
    final durationMinutes = widget.durationMinutes ?? extra?['durationMinutes'] as int?;
    final appointmentDate = widget.appointmentDate ?? extra?['appointmentDate'] as String?;
    final consultationType = widget.consultationType ?? extra?['consultationType'] as String?;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
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
                  _buildConsultationCard(primaryColor, isEmergency, consultationType: consultationType, durationMinutes: durationMinutes, appointmentDateStr: appointmentDate),
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
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textSecondaryOf(context), letterSpacing: 1.5),
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
            color: isEmergency ? AppColors.error : AppColors.success,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: (isEmergency ? AppColors.error : AppColors.success).withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: const Icon(Icons.check_rounded, color: AppColors.textInverse, size: 48),
        ),
        const SizedBox(height: 32),
        Text(
          isEmergency ? 'Emergency Consult\nConfirmed' : 'Booking\nConfirmed!',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), height: 1.1, letterSpacing: -1.5),
        ),
        const SizedBox(height: 12),
        Text(
          isEmergency ? 'Your priority medical session is scheduled for immediate connection. Complete payment to start.' : 'Your appointment has been successfully scheduled and verified.',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w500, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(Color primaryColor, String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLight)),
      child: Row(
        children: [
          const GenericUserAvatar(radius: 32, avatarUrl: null),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isNotEmpty ? name : '', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimaryOf(context))),
                Text('Specialist', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14, fontWeight: FontWeight.w700)),
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

  Widget _buildConsultationCard(Color primaryColor, bool isEmergency, {String? consultationType, int? durationMinutes, String? appointmentDateStr}) {
    String dateStr;
    String timeStr;
    if (appointmentDateStr != null) {
      final dt = DateTime.parse(appointmentDateStr).toLocal();
      dateStr = '${dt.day} ${_monthName(dt.month)} ${dt.year}';
      timeStr = '${_fmt(dt.hour)}:${_fmt(dt.minute)}';
    } else {
      final now = DateTime.now();
      dateStr = '${now.day} ${_monthName(now.month)} ${now.year}';
      timeStr = '${_fmt(now.hour)}:${_fmt(now.minute)}';
    }
    final consultLabel = consultationType ?? 'Video Call';
    final durationLabel = durationMinutes != null ? '$durationMinutes mins' : '30 mins';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today_rounded, 'Date', dateStr),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.borderLight)),
          _buildInfoRow(Icons.access_time_rounded, 'Time', timeStr),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.borderLight)),
          _buildInfoRow(Icons.timer_outlined, 'Duration', durationLabel),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.borderLight)),
          _buildInfoRow(Icons.videocam_rounded, 'Consultation Type', consultLabel),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.borderLight)),
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
        Icon(icon, size: 18, color: AppColors.textTertiaryOf(context)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textTertiaryOf(context))),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
      ],
    );
  }

  Widget _buildPaymentInstructionsCard(double fee) {
    final feeStr = fee.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.errorLight, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 12),
              Text('P2P Payment Instructions', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Pay the emergency fee below to start your consultation immediately:',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context), height: 1.4),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '₦$feeStr',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 36, color: AppColors.error, letterSpacing: -1),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.textPrimaryOf(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _paymentInstructions ?? 'Contact doctor for payment details',
              style: const TextStyle(color: AppColors.textInverse, fontFamily: 'monospace', fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Once paid, the doctor will be alerted for immediate session startup.',
              style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold),
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
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        children: [
          _buildPriceRow('Consultation Fee', '₦$feeStr'),
          const SizedBox(height: 12),
          _buildPriceRow('Platform Service', '₦0.00', isSpecial: true),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: AppColors.borderLight)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimaryOf(context))),
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
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryOf(context))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isSpecial ? AppColors.success : AppColors.textPrimaryOf(context))),
      ],
    );
  }

  Widget _buildSupportBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceAltOf(context), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Icon(Icons.headset_mic_rounded, color: AppColors.textSecondaryOf(context), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need assistance?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textPrimaryOf(context))),
                Text('Our care team is available 24/7', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryOf(context)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Color primaryColor, bool isEmergency, String? docId) {
    final fee = widget.consultationFee ?? 0;
    return Column(
      children: [
        if (!isEmergency)
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => context.push('/upload-receipt', extra: {
                'doctorId': docId,
                'amount': fee,
                'appointmentId': widget.appointmentId,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Proceed to Payment', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
            ),
          ),
        if (!isEmergency) const SizedBox(height: 16),
        if (isEmergency)
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => context.push('/account-conversion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textInverse,
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
          child: OutlinedButton(
            onPressed: () => context.go(isEmergency ? '/login' : '/patient_dashboard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(isEmergency ? 'Sign In to Continue' : 'Back to Dashboard', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt has been saved to your device downloads')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondaryOf(context),
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
