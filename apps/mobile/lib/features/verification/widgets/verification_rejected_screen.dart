import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';

class VerificationRejectedScreen extends StatelessWidget {
  final String? reason;
  final VoidCallback onResubmit;

  const VerificationRejectedScreen({super.key, this.reason, required this.onResubmit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(top: -150, right: -100, child: _MeshCircle(color: AppColors.error.withValues(alpha: 0.1), size: 500)),
          Positioned(bottom: -100, left: -50, child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.05), size: 400)),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const _ErrorHub(),
                  const SizedBox(height: 40),

                  _buildSectionTitle(context, 'REQUIRED CORRECTIONS'),
                  const SizedBox(height: 16),
                  _CorrectionFeed(reason: reason),
                  const SizedBox(height: 40),

                  _buildSectionTitle(context, 'NEXT STEPS'),
                  const SizedBox(height: 16),
                  const _ActionTileFeed(),
                  const SizedBox(height: 40),

                  const _SecurityBox(),
                  const SizedBox(height: 48),

                  _ActionHub(onResubmit: onResubmit),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }
}

class _ErrorHub extends StatelessWidget {
  const _ErrorHub();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(36), border: Border.all(color: AppColors.borderLightOf(context)), boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 20))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.gpp_maybe_rounded, color: AppColors.error, size: 28)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Review Incomplete', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    const Text('Action Required', style: TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'We were unable to approve your clinical credentials at this time. Please address the highlighted issues below and resubmit for priority review.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondaryOf(context), height: 1.6, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CorrectionFeed extends StatelessWidget {
  final String? reason;
  const _CorrectionFeed({this.reason});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _CorrectionCard(icon: Icons.badge_rounded, title: 'Identity Document', description: 'The uploaded ID is slightly blurry. Please ensure all text is legible and well-lit.'),
        const _CorrectionCard(icon: Icons.face_rounded, title: 'Facial Biometric', description: 'The selfie does not match the provided ID document. Please retake in a brighter environment.'),
        if (reason != null) _CorrectionCard(icon: Icons.description_rounded, title: 'Clinical License', description: reason!),
      ],
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _CorrectionCard({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: AppColors.error, size: 20)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimaryOf(context), letterSpacing: -0.3)),
                const SizedBox(height: 6),
                Text(description, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), height: 1.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTileFeed extends StatelessWidget {
  const _ActionTileFeed();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(icon: Icons.help_center_rounded, title: 'View Requirements', subtitle: 'Detailed guide on clinical standards'),
        _ActionTile(icon: Icons.support_agent_rounded, title: 'Contact Support', subtitle: 'Speak with clinical onboarding'),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActionTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.primary, size: 20)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimaryOf(context), letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate300, size: 20),
        ],
      ),
    );
  }
}

class _SecurityBox extends StatelessWidget {
  const _SecurityBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceAltOf(context), borderRadius: BorderRadius.circular(28)),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: AppColors.textSecondaryOf(context), size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text('Your information remains encrypted and protected in our private clinical vault.', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w700, height: 1.4))),
        ],
      ),
    );
  }
}

class _ActionHub extends StatelessWidget {
  final VoidCallback onResubmit;
  const _ActionHub({required this.onResubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: onResubmit,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textInverse, elevation: 15, shadowColor: AppColors.primary.withValues(alpha: 0.3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
            child: const Text('CORRECT & RESUBMIT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate800, foregroundColor: AppColors.textInverse, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
            child: const Text('BACK TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }
}

class _MeshCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _MeshCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)],
      ),
    );
  }
}
