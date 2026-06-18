import 'package:flutter/material.dart';
import 'dart:ui';

class ModeSwitchDialog extends StatelessWidget {
  final String targetMode; // 'Doctor' or 'Patient'
  final VoidCallback onConfirm;

  const ModeSwitchDialog({super.key, required this.targetMode, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.sync_rounded, color: primaryColor, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'Switch to $targetMode Mode?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'You are transitioning to your ${targetMode.toLowerCase()} profile. Your session will remain secure.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
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
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: Text('CONFIRM SWITCH', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}
