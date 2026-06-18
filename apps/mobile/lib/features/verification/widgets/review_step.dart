import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../verification_provider.dart';

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info Box
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEF2FF)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF4338CA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Almost there!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Please review all the information below before submitting. You can edit any section if needed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Section 1: Professional Profile
        _buildSectionCard(
          title: 'Professional Profile',
          icon: Icons.person_outline_rounded,
          onEdit: () => notifier.goToStep(VerificationStep.professional),
          children: [
            _buildDetailRow('Medical Specialty', state.specialty),
            _buildDetailRow('Years of Experience', '${state.experience} Years'),
            _buildDetailRow('Medical License Number', state.licenseNumber),
            _buildDetailRow(
              'Uploaded License',
              state.licenseUrl != null ? 'Medical_License.pdf' : 'Not uploaded',
              showFile: state.licenseUrl != null,
              fileIcon: Icons.description_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section 2: Identity Documents
        _buildSectionCard(
          title: 'Identity Documents',
          icon: Icons.badge_outlined,
          onEdit: () => notifier.goToStep(VerificationStep.identity),
          children: [
            _buildDetailRow('ID Type', state.idType ?? 'Not selected'),
            _buildDetailRow(
              'Front Side',
              state.idFrontUrl != null ? 'ID_Front.jpg' : 'Not uploaded',
              showFile: state.idFrontUrl != null,
            ),
            _buildDetailRow(
              'Back Side',
              state.idBackUrl != null ? 'ID_Back.jpg' : 'Not uploaded',
              showFile: state.idBackUrl != null,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section 3: Facial Biometrics
        _buildSectionCard(
          title: 'Facial Biometrics',
          icon: Icons.face_outlined,
          onEdit: () => notifier.goToStep(VerificationStep.facial),
          children: [
            _buildDetailRow(
              'Selfie Captured',
              state.selfieUrl != null ? 'Selfie_Capture.jpg' : 'Not captured',
              showFile: state.selfieUrl != null,
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Submission Disclaimer
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'By submitting, you confirm that all information provided is true and accurate. Our admin team will review your documents and verify your identity. This process may take ',
                      ),
                      TextSpan(
                        text: '24–48 hours',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Submit Button (Handled by the parent screen but shown here as placeholder if needed)
        // Note: The actual Submit for Review button is in VerifyPractitionerScreen's _buildNavigationButton

        // Encryption Footer
        const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF9CA3AF),
                size: 14,
              ),
              SizedBox(width: 8),
              Text(
                'Your information is 256-bit encrypted and securely stored.',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF6366F1), size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: Color(0xFF6366F1),
                  ),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool showFile = false,
    IconData? fileIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!showFile)
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1B4B),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEEF2FF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          fileIcon ?? Icons.image_outlined,
                          size: 14,
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1E1B4B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
