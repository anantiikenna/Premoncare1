import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/app_colors.dart';

class ModeSwitchDialog extends StatelessWidget {
  final String targetMode;
  final VoidCallback onConfirm;

  const ModeSwitchDialog({super.key, required this.targetMode, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: AppColors.surfaceOf(context).withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: AppColors.surfaceOf(context).withValues(alpha: 0.2)),
        ),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.sync_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'Switch to $targetMode Mode?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'You are transitioning to your ${targetMode.toLowerCase()} profile. Your session will remain secure.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('CONFIRM SWITCH', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: TextStyle(color: AppColors.textTertiaryOf(context), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}
