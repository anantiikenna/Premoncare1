import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import 'verification_provider.dart';

class VerificationWizard extends ConsumerWidget {
  const VerificationWizard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryOf(context), size: 20),
          onPressed: () {
            if (state.currentStep == VerificationStep.professional) {
              context.pop();
            } else {
              notifier.previousStep();
            }
          },
        ),
        title: Text(
          'Practitioner Verification',
          style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildStepper(context, state.currentStep),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (state.rejectionReason != null) ...[
                    _buildRejectionNotice(context, state.rejectionReason!),
                    const SizedBox(height: 24),
                  ],
                  
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: KeyedSubtree(
                      key: ValueKey(state.currentStep),
                      child: switch (state.currentStep) {
                        VerificationStep.professional => _ProfessionalStep(),
                        VerificationStep.identity => _IdentityStep(),
                        VerificationStep.facial => _FacialStep(),
                        VerificationStep.review => _ReviewStep(),
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildBottomActions(context, ref),
        ],
      ),
    );
  }

  Widget _buildStepper(BuildContext context, VerificationStep currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Row(
        children: VerificationStep.values.map((step) {
          final index = step.index;
          final isCompleted = index < currentStep.index;
          final isCurrent = index == currentStep.index;
          
          return Expanded(
            child: Row(
              children: [
                _buildStepDot(context, isCompleted, isCurrent, index + 1),
                if (index < VerificationStep.values.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isCompleted ? AppColors.primary : AppColors.borderOf(context),
                            index + 1 <= currentStep.index ? AppColors.primary : AppColors.borderOf(context),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepDot(BuildContext context, bool isCompleted, bool isCurrent, int stepNumber) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCompleted || isCurrent ? AppColors.primary : AppColors.surfaceOf(context),
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted || isCurrent ? AppColors.primary : AppColors.borderOf(context),
          width: 2,
        ),
        boxShadow: isCurrent ? [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)
        ] : null,
      ),
      child: Center(
        child: isCompleted
          ? const Icon(Icons.check_rounded, color: AppColors.textInverse, size: 16)
          : Text(
              stepNumber.toString(),
              style: TextStyle(
                color: isCurrent ? AppColors.textInverse : AppColors.textTertiaryOf(context),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
      ),
    );
  }

  Widget _buildRejectionNotice(BuildContext context, String reason) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorLightOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Action Required',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(color: AppColors.error, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);
    final isLastStep = state.currentStep == VerificationStep.review;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimaryOf(context).withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: state.isSubmitting || state.isUploading || (isLastStep && !state.agreed)
              ? null
              : () async {
                  if (isLastStep) {
                    final success = await notifier.submit();
                    if (success && context.mounted) {
                      context.go('/doctor_dashboard');
                    }
                  } else {
                    if (_validateStep(context, state)) {
                      notifier.nextStep();
                    }
                  }
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: state.isSubmitting || state.isUploading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 3))
              : Text(
                  isLastStep ? 'Submit Application' : 'Continue',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
          ),
        ),
      ),
    );
  }

  bool _validateStep(BuildContext context, VerificationState state) {
    String? error;
    if (state.currentStep == VerificationStep.professional) {
      if (state.specialty.isEmpty) { error = 'Select your specialty'; }
      else if (state.licenseUrl == null) { error = 'Upload medical license'; }
    } else if (state.currentStep == VerificationStep.identity) {
      if (state.idUrl == null) { error = 'Upload ID document'; }
      else if (state.addressUrl == null) { error = 'Upload proof of address'; }
    } else if (state.currentStep == VerificationStep.facial) {
      if (state.selfieUrl == null) error = 'Capture live selfie';
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return false;
    }
    return true;
  }
}

class _ProfessionalStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Professional Credentials', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1)),
        const SizedBox(height: 8),
        Text('Help us verify your medical expertise and practice history.', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14)),
        const SizedBox(height: 32),
        CustomTextField(
          label: 'Professional Title',
          hintText: 'e.g. Dr., Prof.',
          onChanged: (v) => notifier.updateProfessional(v, state.specialty, state.experience, state.licenseNumber),
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Medical Specialty',
          hintText: 'e.g. General Practitioner',
          onChanged: (v) => notifier.updateProfessional(state.title, v, state.experience, state.licenseNumber),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Experience (Years)',
                hintText: 'e.g. 5',
                keyboardType: TextInputType.number,
                onChanged: (v) => notifier.updateProfessional(state.title, state.specialty, v, state.licenseNumber),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                label: 'License Number',
                hintText: 'MD-XXXXX',
                onChanged: (v) => notifier.updateProfessional(state.title, state.specialty, state.experience, v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildUploadBox(
          context: context,
          label: 'Upload Medical License',
          subLabel: 'PDF, JPG or PNG (Max 5MB)',
          isUploaded: state.licenseUrl != null,
          isUploading: state.isUploading && state.licenseUrl == null,
          onTap: () async {
            final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (image != null) {
              await notifier.uploadFile(File(image.path), VerificationField.license, 'license.jpg');
            }
          },
        ),
      ],
    );
  }
}

class _IdentityStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Identity Verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1)),
        const SizedBox(height: 8),
        Text('Securely upload your government-issued identification.', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14)),
        const SizedBox(height: 32),
        _buildUploadBox(
          context: context,
          label: 'Government ID',
          subLabel: 'International Passport or National ID',
          isUploaded: state.idUrl != null,
          isUploading: state.isUploading && state.idUrl == null,
          onTap: () async {
            final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
            if (image != null) {
              await notifier.uploadFile(File(image.path), VerificationField.govtId, 'govt_id.jpg');
            }
          },
        ),
        const SizedBox(height: 20),
        _buildUploadBox(
          context: context,
          label: 'Proof of Address',
          subLabel: 'Utility Bill or Bank Statement',
          isUploaded: state.addressUrl != null,
          isUploading: state.isUploading && state.addressUrl == null,
          onTap: () async {
            final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (image != null) {
              await notifier.uploadFile(File(image.path), VerificationField.address, 'address.jpg');
            }
          },
        ),
      ],
    );
  }
}

class _FacialStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Face Recognition', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1)),
              const SizedBox(height: 8),
              Text('Verify that you are the person on the identity document.', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 60),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: state.selfieUrl != null ? AppColors.success : AppColors.primary, width: 2),
              ),
            ),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceAltOf(context),
                image: state.selfieUrl != null 
                  ? DecorationImage(image: NetworkImage(state.selfieUrl!), fit: BoxFit.cover)
                  : null,
              ),
              child: state.isUploading 
                ? const CircularProgressIndicator(color: AppColors.primary)
                : state.selfieUrl == null 
                  ? Icon(Icons.face_retouching_natural_rounded, size: 80, color: AppColors.textTertiaryOf(context))
                  : null,
            ),
            if (state.selfieUrl == null)
              const _ScannerLine(),
          ],
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () async {
            final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
            if (image != null) {
              await notifier.uploadFile(File(image.path), VerificationField.selfie, 'selfie.jpg');
            }
          },
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text\('Capture\ Selfie'\),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceAltOf(context),
            foregroundColor: AppColors.primary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _ReviewStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review Submission', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1)),
        const SizedBox(height: 8),
        Text('Confirm your details before submitting for official review.', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLightOf(context)),
          ),
          child: Column(
            children: [
              _buildReviewRow(context, 'Specialty', state.specialty),
              _buildReviewRow(context, 'Experience', '${state.experience} Years'),
              _buildReviewRow(context, 'License Number', state.licenseNumber),
              _buildReviewRow(context, 'Docs Status', 'Verification Ready', isSuccess: true),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.infoLightOf(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Checkbox(
                value: state.agreed,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onChanged: (v) => notifier.setAgreed(v ?? false),
              ),
              Expanded(
                child: Text(
                  'I certify that the provided information is accurate and comply with Premon Care Professional Terms.',
                  style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(BuildContext context, String label, String value, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w600, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: isSuccess ? AppColors.success : AppColors.textPrimaryOf(context),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildUploadBox({
  required BuildContext context,
  required String label,
  required String subLabel,
  required bool isUploaded,
  required bool isUploading,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: CustomPaint(
      painter: _DashedBorderPainter(color: isUploaded ? AppColors.success : AppColors.borderOf(context)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isUploaded ? AppColors.successLightOf(context) : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUploaded ? AppColors.success.withValues(alpha: 0.1) : AppColors.surfaceAltOf(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUploaded ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                color: isUploaded ? AppColors.success : AppColors.textSecondaryOf(context),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimaryOf(context))),
            const SizedBox(height: 4),
            Text(subLabel, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ),
  );
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(24)));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerLine extends StatefulWidget {
  const _ScannerLine();
  @override
  _ScannerLineState createState() => _ScannerLineState();
}

class _ScannerLineState extends State<_ScannerLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: 40 + (160 * _controller.value),
          child: Container(
            width: 200,
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)],
              gradient: LinearGradient(colors: [Colors.transparent, AppColors.primary, Colors.transparent]),
            ),
          ),
        );
      },
    );
  }
}
