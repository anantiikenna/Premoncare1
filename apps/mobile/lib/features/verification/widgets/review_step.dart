import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../verification_provider.dart';

class ReviewStep extends ConsumerWidget {
  ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLightOf(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.borderLightOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
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
                      'Almost there!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please review all the information below before submitting. You can edit any section if needed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryOf(context),
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

        _buildSectionCard(
          context: context,
          title: 'Professional Profile',
          icon: Icons.person_outline_rounded,
          onEdit: () => notifier.goToStep(VerificationStep.professional),
          children: [
            _buildDetailRow(context, 'Medical Specialty', state.specialty),
            _buildDetailRow(context, 'Years of Experience', '${state.experience} Years'),
            _buildDetailRow(context, 'Medical License Number', state.licenseNumber),
            _buildDetailRow(
              context,
              'Uploaded License',
              state.licenseUrl != null ? 'Medical_License.pdf' : 'Not uploaded',
              showFile: state.licenseUrl != null,
              fileIcon: Icons.description_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),

        _buildSectionCard(
          context: context,
          title: 'Identity Documents',
          icon: Icons.badge_outlined,
          onEdit: () => notifier.goToStep(VerificationStep.identity),
          children: [
            _buildDetailRow(context, 'ID Type', state.idType ?? 'Not selected'),
            _buildDetailRow(
              context,
              'Front Side',
              state.idFrontUrl != null ? 'ID_Front.jpg' : 'Not uploaded',
              showFile: state.idFrontUrl != null,
            ),
            _buildDetailRow(
              context,
              'Back Side',
              state.idBackUrl != null ? 'ID_Back.jpg' : 'Not uploaded',
              showFile: state.idBackUrl != null,
            ),
          ],
        ),
        const SizedBox(height: 24),

        _buildSectionCard(
          context: context,
          title: 'Facial Biometrics',
          icon: Icons.face_outlined,
          onEdit: () => notifier.goToStep(VerificationStep.facial),
          children: [
            _buildDetailRow(
              context,
              'Selfie Captured',
              state.selfieUrl != null ? 'Selfie_Capture.jpg' : 'Not captured',
              showFile: state.selfieUrl != null,
            ),
          ],
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryOf(context),
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
                          color: AppColors.textPrimaryOf(context),
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

        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textTertiaryOf(context),
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                'Your information is 256-bit encrypted and securely stored.',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiaryOf(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderOf(context)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
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
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context)),
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLightOf(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          fileIcon ?? Icons.image_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textPrimaryOf(context),
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
