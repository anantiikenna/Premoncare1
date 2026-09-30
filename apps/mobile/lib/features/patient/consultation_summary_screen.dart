import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../core/user_facing_errors.dart';
import 'patient_providers.dart';

class ConsultationSummaryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> appointmentData;

  const ConsultationSummaryScreen({super.key, required this.appointmentData});

  @override
  ConsumerState<ConsultationSummaryScreen> createState() =>
      _ConsultationSummaryScreenState();
}

class _ConsultationSummaryScreenState
    extends ConsumerState<ConsultationSummaryScreen> {
  String? _selectedRating;
  final _commentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmittingReview = false;
  String? _reviewSubmittedError;

  String get _doctorName => widget.appointmentData['doctor_name'] ?? 'Doctor';
  String get _doctorId => widget.appointmentData['doctor_id'] ?? '';
  String get _appointmentId =>
      widget.appointmentData['appointment_id'] ?? const Uuid().v4();
  double get _fee =>
      (widget.appointmentData['fee'] as num?)?.toDouble() ?? 15000.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating == null) return;

    setState(() {
      _isSubmittingReview = true;
      _reviewSubmittedError = null;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final ratingValue = int.parse(_selectedRating!);

      await supabase.from('reviews').insert({
        'patient_id': userId,
        'doctor_id': _doctorId,
        'appointment_id': _appointmentId,
        'rating': ratingValue,
        'comment': _commentController.text.trim(),
        'is_anonymous': _isAnonymous,
        'created_at': DateTime.now().toIso8601String(),
      });

      final response = await supabase
          .from('profiles')
          .select('rating, review_count')
          .eq('id', _doctorId)
          .single();

      final currentAvg = (response['rating'] as num?)?.toDouble() ?? 0.0;
      final currentTotal = (response['review_count'] as num?)?.toInt() ?? 0;

      final newTotal = currentTotal + 1;
      final newAvg = ((currentAvg * currentTotal) + ratingValue) / newTotal;

      await supabase.from('profiles').update({
        'rating': double.parse(newAvg.toStringAsFixed(2)),
        'review_count': newTotal,
      }).eq('id', _doctorId);

      ref.invalidate(patientAppointmentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.reviewSubmitted,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textInverse,
              ),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        setState(() {
          _selectedRating = null;
          _commentController.clear();
          _isAnonymous = false;
        });
      }
    } catch (e, stackTrace) {
      logHandledError('Failed to submit review', e, stackTrace);
      if (mounted) {
        setState(() {
          _reviewSubmittedError = userFacingError(
            e,
            fallback: 'Failed to submit review. Please try again.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final dateStr = dateFormat.format(DateTime.now());
    final timeStr = timeFormat.format(DateTime.now());

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
                      const SizedBox(height: 24),
                      _buildCompletionHeader(context),
                      const SizedBox(height: 24),
                      _buildDoctorCard(context),
                      const SizedBox(height: 24),
                      _buildDetailsCard(context, dateStr, timeStr),
                      const SizedBox(height: 24),
                      _buildPaymentReceiptSection(context),
                      const SizedBox(height: 24),
                      _buildReviewSection(context),
                      const SizedBox(height: 24),
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
                Icons.close_rounded,
                color: AppColors.textPrimaryOf(context),
                size: 20,
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context)!.consultationComplete,
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

  Widget _buildCompletionHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 80,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          AppLocalizations.of(context)!.consultationSuccessful,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimaryOf(context),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.sessionCompletedMessage,
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

  Widget _buildDoctorCard(BuildContext context) {
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
                  _doctorName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.videoCall,
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
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppLocalizations.of(context)!.completed,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, String dateStr, String timeStr) {
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
            AppLocalizations.of(context)!.appointmentDetails,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            Icons.calendar_today_rounded,
            AppLocalizations.of(context)!.date,
            dateStr,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            Icons.access_time_rounded,
            AppLocalizations.of(context)!.timeLabel,
            timeStr,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            Icons.timer_rounded,
            AppLocalizations.of(context)!.sessionDurationLabel,
            '30 mins',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiaryOf(context),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentReceiptSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.success,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.digitalReceipt,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildReceiptRow(
            context,
            AppLocalizations.of(context)!.doctorConsultation,
            _doctorName,
          ),
          const SizedBox(height: 12),
          _buildReceiptRow(
            context,
            AppLocalizations.of(context)!.consultationType,
            AppLocalizations.of(context)!.videoCall,
          ),
          const SizedBox(height: 12),
          _buildReceiptRow(context, AppLocalizations.of(context)!.statusLabel, AppLocalizations.of(context)!.completed),
          const SizedBox(height: 12),
          _buildReceiptRow(context, AppLocalizations.of(context)!.amountPaid, '₦${_fee.toInt()}'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.paymentConfirmed,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiaryOf(context),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.rateExperience,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = (index + 1).toString();
              final isSelected = _selectedRating == value;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    isSelected
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: isSelected
                        ? AppColors.warning
                        : AppColors.textTertiaryOf(context),
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.addComment,
              hintStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiaryOf(context),
              ),
              filled: true,
              fillColor: AppColors.surfaceAltOf(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.borderOf(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.borderOf(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _isAnonymous,
                  onChanged: (value) => setState(() => _isAnonymous = value ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.postAnonymously,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  _selectedRating == null || _isSubmittingReview
                      ? null
                      : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                elevation: 0,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  _isSubmittingReview
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.textInverse,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.submitReview,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
            ),
          ),
          if (_reviewSubmittedError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _reviewSubmittedError!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
