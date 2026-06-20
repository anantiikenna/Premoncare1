import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.textPrimaryOf(context);
    final secondary = AppColors.textSecondaryOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: color),
          onPressed: () => context.pop(),
        ),
        title: Text('Terms of Service', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Last updated: June 2026', style: AppTypography.captionOf(context)),
          const SizedBox(height: 24),
          _buildSection('1. Acceptance of Terms', 'By accessing and using Premon Care ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.', secondary),
          _buildSection('2. Description of Service', 'Premon Care is a telemedicine platform that connects patients with licensed healthcare providers for virtual consultations. We facilitate appointments, secure messaging, and medical record management.', secondary),
          _buildSection('3. User Accounts', 'You must register an account to use the App. You are responsible for maintaining the confidentiality of your account credentials. You must provide accurate and complete information during registration.', secondary),
          _buildSection('4. Medical Disclaimer', 'Premon Care does not provide medical advice. The App facilitates communication between patients and licensed healthcare providers. All medical decisions are made solely by the treating physician.', secondary),
          _buildSection('5. Payment Terms', 'Consultation fees are set by individual practitioners. Payment is processed through peer-to-peer transfers. Receipts must be uploaded for verification. Premon Care charges no additional platform fees for patients.', secondary),
          _buildSection('6. Privacy', 'Your use of the App is also governed by our Privacy Policy. We are committed to protecting your personal and medical data in compliance with applicable data protection laws.', secondary),
          _buildSection('7. Limitation of Liability', 'Premon Care shall not be liable for any indirect, incidental, special, or consequential damages arising out of or in connection with your use of the App.', secondary),
          _buildSection('8. Changes to Terms', 'We reserve the right to modify these terms at any time. Changes will be effective upon posting. Continued use of the App constitutes acceptance of modified terms.', secondary),
          const SizedBox(height: 24),
          Text('Contact us at legal@premoncare.com for questions about these terms.', style: AppTypography.bodySmallOf(context)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String body, Color secondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(fontSize: 14, color: secondary, height: 1.6)),
        ],
      ),
    );
  }
}
