import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: Text(AppLocalizations.of(context)!.privacyPolicyScreenTitle, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(AppLocalizations.of(context)!.lastUpdatedJune2026, style: AppTypography.captionOf(context)),
          const SizedBox(height: 24),
          _buildSection(context, '1. Information We Collect', 'We collect personal information you provide during registration (name, email, date of birth), medical records you upload, consultation notes, payment receipts, and device information for security purposes.', secondary),
          _buildSection(context, '2. How We Use Your Information', 'Your information is used to provide telemedicine services, facilitate consultations, manage your medical records, process payments, and send important notifications about your care.', secondary),
          _buildSection(context, '3. Data Security', 'We implement industry-standard encryption (AES-256) for data at rest and TLS 1.3 for data in transit. Your medical records are stored in HIPAA-compliant infrastructure with strict access controls.', secondary),
          _buildSection(context, '4. Data Sharing', 'We do not sell your personal data. Medical records are shared only with healthcare providers you have explicitly granted access to. Anonymous, aggregated data may be used for platform improvement.', secondary),
          _buildSection(context, '5. Your Rights', 'You have the right to access, correct, export, and delete your personal data. You can manage privacy settings in the app or contact our data protection officer.', secondary),
          _buildSection(context, '6. Cookies & Tracking', 'We use essential cookies for app functionality. Analytics data is collected anonymously to improve the platform. You can opt out of non-essential tracking in settings.', secondary),
          _buildSection(context, '7. Children\'s Privacy', 'Premon Care is not intended for users under 18. For minors, a parent or guardian must create and manage the account.', secondary),
          _buildSection(context, '8. Contact', 'For privacy-related inquiries, contact our Data Protection Officer at privacy@premoncare.com.', secondary),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String body, Color secondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context))),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(fontSize: 14, color: secondary, height: 1.6)),
        ],
      ),
    );
  }
}
