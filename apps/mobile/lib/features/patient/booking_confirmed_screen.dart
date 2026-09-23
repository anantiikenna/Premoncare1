import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../l10n/app_localizations.dart';
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
          isEmergency ? AppLocalizations.of(context)!.emergencyBookingConfirmed : AppLocalizations.of(context)!.bookingConfirmed,
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), height: 1.1, letterSpacing: -1.5),
        ),
        const SizedBox(height: 12),
        Text(
          isEmergency ? AppLocalizations.of(context)!.emergencyConsultScheduled : AppLocalizations.of(context)!.bookingScheduled,
          style: TextStyle(fontSize: 16, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w500, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(Color primaryColor, String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Row(
        children: [
          const GenericUserAvatar(radius: 32, avatarUrl: null),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isNotEmpty ? name : '', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimaryOf(context))),
                Text(AppLocalizations.of(context)!.specialistLabel, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
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
    final consultLabel = consultationType ?? AppLocalizations.of(context)!.videoCall;
    final durationLabel = durationMinutes != null ? '$durationMinutes mins' : '30 mins';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today_rounded, AppLocalizations.of(context)!.date, dateStr),
          Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.borderLightOf(context))),
          _buildInfoRow(Icons.access_time_rounded, AppLocalizations.of(context)!.timeLabel, timeStr),
          Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.borderLightOf(context))),
          _buildInfoRow(Icons.timer_outlined, AppLocalizations.of(context)!.sessionDurationLabel, durationLabel),
          Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.borderLightOf(context))),
          _buildInfoRow(Icons.videocam_rounded, AppLocalizations.of(context)!.consultationType, consultLabel),
          Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.borderLightOf(context))),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Icon(Icons.flash_on_rounded, color: primaryColor, size: 16),
                const SizedBox(width: 12),
                Text(
                  isEmergency ? AppLocalizations.of(context)!.emergencySessionPayNow : AppLocalizations.of(context)!.connectingAutomatically,
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
        border: Border.all(color: AppColors.errorLightOf(context), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.p2pPaymentInstructions, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.payEmergencyFeeBelow,
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
              _paymentInstructions ?? AppLocalizations.of(context)!.contactDoctorPayment,
              style: const TextStyle(color: AppColors.textInverse, fontFamily: 'monospace', fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              AppLocalizations.of(context)!.doctorAlertedAfterPayment,
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
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Column(
        children: [
          _buildPriceRow(AppLocalizations.of(context)!.consultationFee, '₦$feeStr'),
          const SizedBox(height: 12),
          _buildPriceRow(AppLocalizations.of(context)!.platformService, '₦0.00', isSpecial: true),
          Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: AppColors.borderLightOf(context))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.totalPayable, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimaryOf(context))),
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
                Text(AppLocalizations.of(context)!.needAssistance, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textPrimaryOf(context))),
                Text(AppLocalizations.of(context)!.careTeamAvailable247, style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w600)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_rounded, size: 20),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.proceedToPayment, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(AppLocalizations.of(context)!.createPermanentAccount, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(isEmergency ? AppLocalizations.of(context)!.signInToContinue : AppLocalizations.of(context)!.backToDashboard, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: TextButton(
            onPressed: () {
              final feeVal = widget.consultationFee ?? 0;
              final doctorName = widget.doctorName ?? '';
              final feeStr = feeVal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
              final receipt = 'Premoncare Emergency Receipt\n'
                  'Doctor: $doctorName\n'
                  'Amount: ₦$feeStr\n'
                  'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\n'
                  'Appointment ID: ${widget.appointmentId ?? 'N/A'}';
              Clipboard.setData(ClipboardData(text: receipt));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.receiptCopiedClipboard)),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondaryOf(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(AppLocalizations.of(context)!.downloadDigitalReceipt, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
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
