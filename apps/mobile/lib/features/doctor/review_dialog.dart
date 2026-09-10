import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/app_colors.dart';
import 'review_provider.dart';

class ReviewDialog extends StatefulWidget {
  final String appointmentId;
  final String doctorId;
  final String doctorName;

  const ReviewDialog({
    super.key,
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.rateDoctor(widget.doctorName)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.howWasConsultationExperience),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  icon: Icon(
                    starIndex <= _rating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _rating = starIndex),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.addCommentOptional,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelLabel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleReviewSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textInverse,
          ),
          child: _isSubmitting 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 2))
            : Text(l10n.submitReview),
        ),
      ],
    );
  }

  Future<void> _handleReviewSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      await ReviewService.submitReview(
        appointmentId: widget.appointmentId,
        doctorId: widget.doctorId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.thankYouForFeedback)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
