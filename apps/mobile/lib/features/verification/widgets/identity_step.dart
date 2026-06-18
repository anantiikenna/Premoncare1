import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile/features/verification/verification_provider.dart';

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
        // Security Header Box
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
                child: const Icon(Icons.shield_outlined, color: Color(0xFF4338CA), size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We take your security seriously',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Please upload a valid government-issued ID so we can verify your identity. Your documents are encrypted and stored securely.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
                    ),
                  ],
                ),
              ),
              // Optional: 3D-like Icon placeholder
              const Icon(Icons.folder_shared_rounded, size: 60, color: Color(0xFF818CF8)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Encryption Badge Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEF2FF)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: Color(0xFF6366F1), size: 18),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '256-bit end-to-end encrypted storage',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E1B4B)),
                    ),
                    Text(
                      'Your documents are stored in a private vault and are only accessible to our verification team.',
                      style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Secure',
                  style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Select ID Type
        const Text(
          'Select ID Type *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1B4B)),
        ),
        const Text(
          'Choose the type of government-issued ID you want to upload.',
          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildIdTypeCard('Passport', 'International passport', Icons.public_outlined, state.idType == 'Passport', () => notifier.updateIdType('Passport')),
            const SizedBox(width: 12),
            _buildIdTypeCard('National ID', 'National identity card', Icons.badge_outlined, state.idType == 'National ID', () => notifier.updateIdType('National ID')),
            const SizedBox(width: 12),
            _buildIdTypeCard('Driver\'s License', 'Driver\'s license card', Icons.directions_car_outlined, state.idType == 'Driver\'s License', () => notifier.updateIdType('Driver\'s License')),
          ],
        ),
        const SizedBox(height: 32),

        // Upload Front Side
        const Text(
          'Upload ID Document *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1B4B)),
        ),
        const Text(
          'Upload a clear photo or scan of the front side of your ID.',
          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 16),
        _buildUploadZone(
          title: 'Upload Front Side',
          isUploaded: state.idFrontUrl != null,
          onTap: () => _pickFile(ref, VerificationField.govtIdFront, 'id_front'),
        ),
        const SizedBox(height: 24),

        // Upload Back Side
        const Text(
          'Upload Back Side (If applicable)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1B4B)),
        ),
        const Text(
          'Some IDs have information on the back side.',
          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 16),
        _buildUploadZone(
          title: 'Upload Back Side',
          isUploaded: state.idBackUrl != null,
          onTap: () => _pickFile(ref, VerificationField.govtIdBack, 'id_back'),
        ),
        const SizedBox(height: 32),

        // Document Guidelines
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFF),
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
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF4338CA), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Document Guidelines',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1B4B)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildGuidelineRow('Ensure the document is not expired'),
              _buildGuidelineRow('All four corners should be visible'),
              _buildGuidelineRow('Image should be clear, well-lit, and in focus'),
              _buildGuidelineRow('No editing or filters applied'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdTypeCard(String title, String subtitle, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              if (isSelected)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 18),
                ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFFF9FAFF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: const Color(0xFF6366F1), size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1B4B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadZone({required String title, required bool isUploaded, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isUploaded ? const Color(0xFF10B981) : const Color(0xFF6366F1), width: 1), // Using solid as fallback for dashed
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    isUploaded ? Icons.check_circle_outline_rounded : Icons.cloud_upload_outlined,
                    color: isUploaded ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isUploaded ? 'Document Uploaded' : title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1B4B)),
                  ),
                  const SizedBox(height: 4),
                  const Text('PDF, JPG or PNG (Max. 10MB)', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
            // Preview placeholder
            Container(
              width: 100,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image_outlined, color: Color(0xFFD1D5DB)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
