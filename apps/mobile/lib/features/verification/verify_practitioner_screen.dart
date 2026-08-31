import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import 'verification_provider.dart';
import 'widgets/professional_step.dart';
import 'widgets/identity_step.dart';
import 'widgets/facial_step.dart';
import 'widgets/review_step.dart';
import 'widgets/verification_pending_screen.dart';
import 'widgets/verification_approved_screen.dart';
import 'widgets/verification_rejected_screen.dart';

class VerifyPractitionerScreen extends ConsumerStatefulWidget {
  const VerifyPractitionerScreen({super.key});

  @override
  ConsumerState<VerifyPractitionerScreen> createState() => _VerifyPractitionerScreenState();
}

class _VerifyPractitionerScreenState extends ConsumerState<VerifyPractitionerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(verificationProvider.notifier).refreshStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    final isPending = state.verificationStatus == 'pending';
    final isApproved = state.verificationStatus == 'approved';
    final isRejected = state.verificationStatus == 'rejected';

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.slate800),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Become a Doctor',
          style: TextStyle(
            color: AppColors.textPrimaryOf(context),
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
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w700),
              ),
            ),
          if (isApproved || isRejected)
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: isRejected ? AppColors.error : AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.08), size: 500),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.03), size: 300),
          ),

          SafeArea(
            child: isApproved
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                      _buildHeader(context, state.currentStep),
                                      const SizedBox(height: 40),
                                      _buildProgressTracker(context, state.currentStep),
                                      const SizedBox(height: 40),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: _buildCurrentStep(state.currentStep),
                                      ),
                                      const SizedBox(height: 40),
                                    ],
                                  ),
                                ),
                              ),
                              _buildNavigationButton(context, state, notifier),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, VerificationStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_pin_outlined, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verification Wizard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Step ${step.index + 1} of 4 – ${_getStepTitle(step)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
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

  Widget _buildProgressTracker(BuildContext context, VerificationStep currentStep) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildStepNode(context, 1, 'Professional\nProfile', currentStep.index >= 0, currentStep.index == 0),
          _buildStepLine(context, currentStep.index >= 1),
          _buildStepNode(context, 2, 'Identity\nDocuments', currentStep.index >= 1, currentStep.index == 1),
          _buildStepLine(context, currentStep.index >= 2),
          _buildStepNode(context, 3, 'Facial\nBiometrics', currentStep.index >= 2, currentStep.index == 2),
          _buildStepLine(context, currentStep.index >= 3),
          _buildStepNode(context, 4, 'Review &\nSubmit', currentStep.index >= 3, currentStep.index == 3),
        ],
      ),
    );
  }

  Widget _buildStepNode(BuildContext context, int step, String label, bool isCompleted, bool isCurrent) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent || isCompleted ? AppColors.primary : AppColors.surfaceOf(context),
              border: Border.all(color: isCurrent || isCompleted ? AppColors.primary : AppColors.borderOf(context), width: 2),
              boxShadow: isCurrent ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10)] : null,
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  color: isCurrent || isCompleted ? AppColors.textInverse : AppColors.textTertiaryOf(context),
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
              color: isCurrent ? AppColors.primary : AppColors.textTertiaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(BuildContext context, bool isCompleted) {
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 30),
      color: isCompleted ? AppColors.primary : AppColors.borderOf(context),
    );
  }

  Widget _buildNavigationButton(BuildContext context, VerificationState state, VerificationNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 20, offset: const Offset(0, -5))],
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
                        _showSuccessDialog(context);
                      }
                    } else {
                      notifier.nextStep();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                state.isUploading || state.isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 3))
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

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(32),
        backgroundColor: AppColors.surfaceOf(context),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 48)),
            const SizedBox(height: 24),
            Text('Application Submitted!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5)),
            const SizedBox(height: 12),
            Text('Your professional credentials are now under review. This typically takes 24-48 hours. We will notify you once your account has been verified.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryOf(context), height: 1.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/patient_dashboard');
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textInverse, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
        return ProfessionalStep();
      case VerificationStep.identity:
        return IdentityStep();
      case VerificationStep.facial:
        return FacialStep();
      case VerificationStep.review:
        return ReviewStep();
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
