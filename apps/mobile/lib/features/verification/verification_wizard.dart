import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/widgets/custom_text_field.dart';
import 'verification_provider.dart';

class VerificationWizard extends ConsumerWidget {
  const VerificationWizard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () {
            if (state.currentStep == VerificationStep.professional) {
              context.pop();
            } else {
              notifier.previousStep();
            }
          },
        ),
        title: const Text(
          'Practitioner Verification',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildStepper(state.currentStep),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (state.rejectionReason != null) ...[
                    _buildRejectionNotice(state.rejectionReason!),
                    const SizedBox(height: 24),
                  ],
                  
                  // Content based on step
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

  Widget _buildStepper(VerificationStep currentStep) {
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
                _buildStepDot(isCompleted, isCurrent, index + 1),
                if (index < VerificationStep.values.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isCompleted ? const Color(0xFF0F62FE) : const Color(0xFFE2E8F0),
                            index + 1 <= currentStep.index ? const Color(0xFF0F62FE) : const Color(0xFFE2E8F0),
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

  Widget _buildStepDot(bool isCompleted, bool isCurrent, int stepNumber) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCompleted || isCurrent ? const Color(0xFF0F62FE) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted || isCurrent ? const Color(0xFF0F62FE) : const Color(0xFFE2E8F0),
          width: 2,
        ),
        boxShadow: isCurrent ? [
          BoxShadow(color: const Color(0xFF0F62FE).withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)
        ] : null,
      ),
      child: Center(
        child: isCompleted
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : Text(
              stepNumber.toString(),
              style: TextStyle(
                color: isCurrent ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
      ),
    );
  }

  Widget _buildRejectionNotice(String reason) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Action Required',
                  style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
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
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
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
                    // Basic validation
                    if (_validateStep(context, state)) {
                      notifier.nextStep();
                    }
                  }
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F62FE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: state.isSubmitting || state.isUploading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
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
          backgroundColor: const Color(0xFFEF4444),
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
        const Text('Professional Credentials', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1)),
        const SizedBox(height: 8),
        const Text('Help us verify your medical expertise and practice history.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        const SizedBox(height: 32),
        CustomTextField(
          label: 'Medical Specialty',
          hintText: 'e.g. General Practitioner',
          onChanged: (v) => notifier.updateProfessional(v, state.experience, state.licenseNumber),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Experience (Years)',
                hintText: 'e.g. 5',
                keyboardType: TextInputType.number,
                onChanged: (v) => notifier.updateProfessional(state.specialty, v, state.licenseNumber),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                label: 'License Number',
                hintText: 'MD-XXXXX',
                onChanged: (v) => notifier.updateProfessional(state.specialty, state.experience, v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildUploadBox(
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
        const Text('Identity Verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1)),
        const SizedBox(height: 8),
        const Text('Securely upload your government-issued identification.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        const SizedBox(height: 32),
        _buildUploadBox(
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
        const Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Face Recognition', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1)),
              SizedBox(height: 8),
              Text('Verify that you are the person on the identity document.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
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
                border: Border.all(color: state.selfieUrl != null ? const Color(0xFF22C55E) : const Color(0xFF0F62FE), width: 2),
              ),
            ),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F9),
                image: state.selfieUrl != null 
                  ? DecorationImage(image: NetworkImage(state.selfieUrl!), fit: BoxFit.cover) // This would be FileImage in real app
                  : null,
              ),
              child: state.isUploading 
                ? const CircularProgressIndicator(color: Color(0xFF0F62FE))
                : state.selfieUrl == null 
                  ? const Icon(Icons.face_retouching_natural_rounded, size: 80, color: Color(0xFF94A3B8))
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
          label: const Text('Capture Selfie'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            foregroundColor: const Color(0xFF0F62FE),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        const Text('Review Submission', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1)),
        const SizedBox(height: 8),
        const Text('Confirm your details before submitting for official review.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              _buildReviewRow('Specialty', state.specialty),
              _buildReviewRow('Experience', '${state.experience} Years'),
              _buildReviewRow('License Number', state.licenseNumber),
              _buildReviewRow('Docs Status', 'Verification Ready', isSuccess: true),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Checkbox(
                value: state.agreed,
                activeColor: const Color(0xFF0F62FE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (v) => notifier.setAgreed(v ?? false),
              ),
              const Expanded(
                child: Text(
                  'I certify that the provided information is accurate and comply with Premon Care Professional Terms.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: isSuccess ? const Color(0xFF22C55E) : const Color(0xFF1E293B),
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
  required String label,
  required String subLabel,
  required bool isUploaded,
  required bool isUploading,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: CustomPaint(
      painter: _DashedBorderPainter(color: isUploaded ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isUploaded ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUploaded ? const Color(0xFF22C55E).withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUploaded ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                color: isUploaded ? const Color(0xFF22C55E) : const Color(0xFF64748B),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(subLabel, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500)),
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
              boxShadow: [BoxShadow(color: const Color(0xFF0F62FE).withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)],
              gradient: LinearGradient(colors: [Colors.transparent, const Color(0xFF0F62FE), Colors.transparent]),
            ),
          ),
        );
      },
    );
  }
}
