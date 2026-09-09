import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../l10n/app_localizations.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.textPrimaryOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: color),
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context)!.helpSupportTile, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(AppLocalizations.of(context)!.faqSection, style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildFaqItem(context, AppLocalizations.of(context)!.howDoIBookConsultation, AppLocalizations.of(context)!.howDoIBookConsultationAnswer),
          _buildFaqItem(context, AppLocalizations.of(context)!.howDoIUploadPaymentReceipt, AppLocalizations.of(context)!.howDoIUploadPaymentReceiptAnswer),
          _buildFaqItem(context, AppLocalizations.of(context)!.howDoIBecomeVerifiedDoctor, AppLocalizations.of(context)!.howDoIBecomeVerifiedDoctorAnswer),
          _buildFaqItem(context, AppLocalizations.of(context)!.whatIsEmergencyCare, AppLocalizations.of(context)!.whatIsEmergencyCareAnswer),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.contactUsSection, style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildContactOption(
            context,
            icon: Icons.email_outlined,
            color: AppColors.primary,
            title: AppLocalizations.of(context)!.emailSupportLabel,
            subtitle: 'support@premoncare.com',
            onTap: () => _launchUrl('mailto:support@premoncare.com'),
          ),
          _buildContactOption(
            context,
            icon: Icons.phone_outlined,
            color: AppColors.success,
            title: AppLocalizations.of(context)!.phoneSupportLabel,
            subtitle: '+234 800 PREMON',
            onTap: () => _launchUrl('tel:+234800773666'),
          ),
          _buildContactOption(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            color: AppColors.primary,
            title: AppLocalizations.of(context)!.liveChatLabel,
            subtitle: AppLocalizations.of(context)!.liveChatAvailability,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.liveChatNotice)));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(question, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context))),
      iconColor: AppColors.primary,
      children: [
        Text(answer, style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context), height: 1.5)),
      ],
    );
  }

  Widget _buildContactOption(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryOf(context), size: 20),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
