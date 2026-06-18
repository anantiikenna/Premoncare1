import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../verification_provider.dart';

class FacialStep extends ConsumerWidget {
  const FacialStep({super.key});

  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
    );

    if (image != null) {
      final file = File(image.path);
      await ref.read(verificationProvider.notifier).uploadFile(
        file, 
        VerificationField.selfie, 
        'live_selfie_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);

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
                child: const Icon(Icons.verified_user_outlined, color: Color(0xFF4338CA), size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secure facial verification',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'We use facial biometrics to verify you are the person on your identity document.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.face_retouching_natural_outlined, size: 60, color: Color(0xFF818CF8)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Camera Preview Simulation
        const Center(
          child: Column(
            children: [
              Text(
                'Take a live selfie',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1B4B)),
              ),
              SizedBox(height: 8),
              Text(
                'Position your face in the center of the frame and follow the instructions to capture your photo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Simulated Camera Frame
        Center(
          child: Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: state.selfieUrl != null ? null : const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
                opacity: 0.8,
              ),
              color: Colors.black,
            ),
            child: Stack(
              children: [
                if (state.selfieUrl == null) ...[
                  // Camera Indicators
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          const Text('Camera ready', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                      child: const Icon(Icons.flash_off_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  // Oval Overlay
                  Center(
                    child: Container(
                      width: 180,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5, style: BorderStyle.solid),
                        borderRadius: const BorderRadius.all(Radius.elliptical(180, 240)),
                      ),
                    ),
                  ),
                  // Animated Oval segments (simplified)
                  Center(
                    child: Container(
                      width: 180,
                      height: 240,
                      padding: const EdgeInsets.all(2),
                      child: const CircularProgressIndicator(
                        value: 0.7,
                        strokeWidth: 4,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                  ),
                  // Bottom text overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      ),
                      child: const Text(
                        'Position your face inside the oval',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ] else
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 80),
                        SizedBox(height: 16),
                        Text('Selfie Captured Successfully', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Tips Section
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
                    'Tips for best results',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1B4B)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildTipRow('Use a well-lit environment'),
                        _buildTipRow('Remove sunglasses or hats'),
                        _buildTipRow('Look directly at the camera'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTipRow('Keep a neutral expression'),
                        _buildTipRow('Ensure your face is clearly visible'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Capture Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(Icons.refresh_rounded, 'Retake', () => _pickImage(ref, ImageSource.camera)),
            GestureDetector(
              onTap: state.isUploading ? null : () => _pickImage(ref, ImageSource.camera),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.2), width: 4),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
            _buildControlButton(Icons.image_outlined, 'Upload', () => _pickImage(ref, ImageSource.gallery)),
          ],
        ),
      ],
    );
  }

  Widget _buildTipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(icon, color: const Color(0xFF1E1B4B)),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
      ],
    );
  }
}
