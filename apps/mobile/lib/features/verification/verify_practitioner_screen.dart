import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'verification_provider.dart';
import 'package:mobile/features/verification/widgets/professional_step.dart';
import 'package:mobile/features/verification/widgets/identity_step.dart';
import 'package:mobile/features/verification/widgets/facial_step.dart';
import 'package:mobile/features/verification/widgets/review_step.dart';

import 'package:mobile/features/verification/widgets/verification_pending_screen.dart';
import 'package:mobile/features/verification/widgets/verification_approved_screen.dart';
import 'package:mobile/features/verification/widgets/verification_rejected_screen.dart';

class VerifyPractitionerScreen extends ConsumerWidget {
  const VerifyPractitionerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    final isPending = state.verificationStatus == 'pending';
    final isApproved = state.verificationStatus == 'approved';
    final isRejected = state.verificationStatus == 'rejected';

    const primaryColor = Color(0xFF0F62FE);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Become a Doctor',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isPending && !isApproved && !isRejected)
            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
              ),
            ),
          if (isApproved || isRejected)
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: isRejected ? const Color(0xFFEF4444) : primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Premium immersive mesh background
          Positioned(
            top: -150,
            right: -100,
            child: _MeshCircle(color: primaryColor.withValues(alpha: 0.08), size: 500),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _MeshCircle(color: primaryColor.withValues(alpha: 0.03), size: 300),
          ),

          SafeArea(
            child: isApproved
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: VerificationApprovedScreen(),
                  )
                : isRejected
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: VerificationRejectedScreen(
                          reason: state.rejectionReason,
                          onResubmit: notifier.resetVerification,
                        ),
                      )
                    : isPending
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: VerificationPendingScreen(),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 24),
                                      // Header
                                      _buildHeader(state.currentStep, primaryColor),
                                      const SizedBox(height: 40),
                                      // Progress Tracker
                                      _buildProgressTracker(state.currentStep, primaryColor),
                                      const SizedBox(height: 40),
                                      // Step Content
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: _buildCurrentStep(state.currentStep),
                                      ),
                                      const SizedBox(height: 40),
                                    ],
                                  ),
                                ),
                              ),
                              // Navigation Button
                              _buildNavigationButton(context, state, notifier, primaryColor),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(VerificationStep step, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.person_pin_outlined, color: primaryColor, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verification Wizard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Step ${step.index + 1} of 4 – ${_getStepTitle(step)}',
                style: TextStyle(
                  fontSize: 13,
                  color: primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle(VerificationStep step) {
    switch (step) {
      case VerificationStep.professional: return 'Professional Profile';
      case VerificationStep.identity: return 'Identity Documents';
      case VerificationStep.facial: return 'Facial Biometrics';
      case VerificationStep.review: return 'Review & Submit';
    }
  }

  Widget _buildProgressTracker(VerificationStep currentStep, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildStepNode(1, 'Professional\nProfile', currentStep.index >= 0, currentStep.index == 0, primaryColor),
          _buildStepLine(currentStep.index >= 1, primaryColor),
          _buildStepNode(2, 'Identity\nDocuments', currentStep.index >= 1, currentStep.index == 1, primaryColor),
          _buildStepLine(currentStep.index >= 2, primaryColor),
          _buildStepNode(3, 'Facial\nBiometrics', currentStep.index >= 2, currentStep.index == 2, primaryColor),
          _buildStepLine(currentStep.index >= 3, primaryColor),
          _buildStepNode(4, 'Review &\nSubmit', currentStep.index >= 3, currentStep.index == 3, primaryColor),
        ],
      ),
    );
  }

  Widget _buildStepNode(int step, String label, bool isCompleted, bool isCurrent, Color primaryColor) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent || isCompleted ? primaryColor : Colors.white,
              border: Border.all(color: isCurrent || isCompleted ? primaryColor : const Color(0xFFE2E8F0), width: 2),
              boxShadow: isCurrent ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 10)] : null,
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  color: isCurrent || isCompleted ? Colors.white : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
              color: isCurrent ? primaryColor : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isCompleted, Color primaryColor) {
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 30),
      color: isCompleted ? primaryColor : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildNavigationButton(BuildContext context, VerificationState state, VerificationNotifier notifier, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: state.isUploading || state.isSubmitting
                ? null
                : () async {
                    if (state.currentStep == VerificationStep.review) {
                      final success = await notifier.submit();
                      if (success && context.mounted) {
                        _showSuccessDialog(context, primaryColor);
                      }
                    } else {
                      notifier.nextStep();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                state.isUploading || state.isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : Text(state.currentStep == VerificationStep.review ? 'Submit for Review' : 'Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(width: 8),
                if (!state.isUploading && !state.isSubmitting) const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, Color primaryColor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(32),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 48)),
            const SizedBox(height: 24),
            const Text('Application Submitted!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF1E293B), letterSpacing: -0.5)),
            const SizedBox(height: 12),
            const Text('Your professional credentials are now under review. This typically takes 24-48 hours. We will notify you once your account has been verified.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.go('/patient_dashboard'); // Return to dashboard
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Return to Dashboard', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(VerificationStep step) {
    switch (step) {
      case VerificationStep.professional:
        return const ProfessionalStep();
      case VerificationStep.identity:
        return const IdentityStep();
      case VerificationStep.facial:
        return const FacialStep();
      case VerificationStep.review:
        return const ReviewStep();
    }
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
