import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile/features/verification/verification_provider.dart';
import '../../../core/app_colors.dart';

class IdentityStep extends ConsumerWidget {
  const IdentityStep({super.key});

  Future<void> _pickFile(WidgetRef ref, VerificationField field, String fileName) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      await ref.read(verificationProvider.notifier).uploadFile(
        file, 
        field,
        '${fileName}_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

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
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAltOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We take your security seriously',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please upload a valid government-issued ID so we can verify your identity. Your documents are encrypted and stored securely.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), height: 1.4),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.folder_shared_rounded, size: 60, color: AppColors.primaryLight),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '256-bit end-to-end encrypted storage',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimaryOf(context)),
                    ),
                    Text(
                      'Your documents are stored in a private vault and are only accessible to our verification team.',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLightOf(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Secure',
                  style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        Text(
          'Select ID Type *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryOf(context)),
        ),
        Text(
          'Choose the type of government-issued ID you want to upload.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildIdTypeCard(context, 'Passport', 'International passport', Icons.public_outlined, state.idType == 'Passport', () => notifier.updateIdType('Passport')),
            const SizedBox(width: 12),
            _buildIdTypeCard(context, 'National ID', 'National identity card', Icons.badge_outlined, state.idType == 'National ID', () => notifier.updateIdType('National ID')),
            const SizedBox(width: 12),
            _buildIdTypeCard(context, 'Driver\'s License', 'Driver\'s license card', Icons.directions_car_outlined, state.idType == 'Driver\'s License', () => notifier.updateIdType('Driver\'s License')),
          ],
        ),
        const SizedBox(height: 32),

        Text(
          'Upload ID Document *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryOf(context)),
        ),
        Text(
          'Upload a clear photo or scan of the front side of your ID.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: 16),
        _buildUploadZone(
          context: context,
          title: 'Upload Front Side',
          isUploaded: state.idFrontUrl != null,
          onTap: () => _pickFile(ref, VerificationField.govtIdFront, 'id_front'),
        ),
        const SizedBox(height: 24),

        Text(
          'Upload Back Side (If applicable)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryOf(context)),
        ),
        Text(
          'Some IDs have information on the back side.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: 16),
        _buildUploadZone(
          context: context,
          title: 'Upload Back Side',
          isUploaded: state.idBackUrl != null,
          onTap: () => _pickFile(ref, VerificationField.govtIdBack, 'id_back'),
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAltOf(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Document Guidelines',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryOf(context)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildGuidelineRow(context, 'Ensure the document is not expired'),
              _buildGuidelineRow(context, 'All four corners should be visible'),
              _buildGuidelineRow(context, 'Image should be clear, well-lit, and in focus'),
              _buildGuidelineRow(context, 'No editing or filters applied'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdTypeCard(BuildContext context, String title, String subtitle, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.backgroundOf(context) : AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderOf(context),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              if (isSelected)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryOf(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.textTertiaryOf(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadZone({required BuildContext context, required String title, required bool isUploaded, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isUploaded ? AppColors.success : AppColors.primary, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    isUploaded ? Icons.check_circle_outline_rounded : Icons.cloud_upload_outlined,
                    color: isUploaded ? AppColors.success : AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isUploaded ? 'Document Uploaded' : title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryOf(context)),
                  ),
                  const SizedBox(height: 4),
                  Text('PDF, JPG or PNG (Max. 10MB)', style: TextStyle(fontSize: 12, color: AppColors.textTertiaryOf(context))),
                ],
              ),
            ),
            Container(
              width: 100,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceAltOf(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.image_outlined, color: AppColors.borderOf(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineRow(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context)),
          ),
        ],
      ),
    );
  }
}
