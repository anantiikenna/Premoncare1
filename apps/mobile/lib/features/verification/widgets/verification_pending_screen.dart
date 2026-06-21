import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../../core/app_colors.dart';

class VerificationPendingScreen extends StatelessWidget {
  VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(top: -150, right: -100, child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.1), size: 500)),
          Positioned(bottom: -100, left: -50, child: _MeshCircle(color: AppColors.warning.withValues(alpha: 0.05), size: 400)),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _StatusHub(),
                  const SizedBox(height: 40),

                  _buildSectionTitle(context, 'VERIFICATION TIMELINE'),
                  const SizedBox(height: 16),
                  _TimelineModule(),
                  const SizedBox(height: 40),

                  _buildSectionTitle(context, 'SECURITY & COMPLIANCE'),
                  const SizedBox(height: 16),
                  const _SecurityModule(),
                  const SizedBox(height: 40),

                  _buildSectionTitle(context, 'APPLICATION SUMMARY'),
                  const SizedBox(height: 16),
                  _SummaryFeed(),
                  const SizedBox(height: 40),

                  _InfoHub(),
                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () => context.go('/patient_dashboard'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate800, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                      child: const Text('RETURN TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
                    ),
                  ),
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

class _StatusHub extends StatelessWidget {
  _StatusHub();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(36), border: Border.all(color: AppColors.borderLightOf(context)), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 20))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 28)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Review In Progress', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('Clinical Credentialing', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Our clinical administration team is currently verifying your professional credentials. This process ensures the highest standard of care on Premon Care.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondaryOf(context), height: 1.6, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: 0.1))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_filled_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 12),
                Text('EST. TIME: 24-48 HOURS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineModule extends StatelessWidget {
  _TimelineModule();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Column(
        children: [
          _TimelineItem(icon: Icons.how_to_reg_rounded, title: 'Clinical Credentialing', subtitle: 'Verifying medical license & certifications.', status: 'IN PROGRESS', color: AppColors.warning, isFirst: true),
          _TimelineItem(icon: Icons.face_unlock_rounded, title: 'Identity Validation', subtitle: 'Automated biometric matching against ID.', status: 'PENDING', color: AppColors.textTertiaryOf(context)),
          _TimelineItem(icon: Icons.domain_verification_rounded, title: 'Board Certification', subtitle: 'Final review by clinical board.', status: 'PENDING', color: AppColors.textTertiaryOf(context), isLast: true),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color color;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({required this.icon, required this.title, required this.subtitle, required this.status, required this.color, this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
            if (!isLast) Container(width: 2, height: 44, color: AppColors.borderLightOf(context)),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimaryOf(context), letterSpacing: -0.3)),
                  Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w600, height: 1.4)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecurityModule extends StatelessWidget {
  const _SecurityModule();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.shield_rounded, color: AppColors.success, size: 32)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AES-256 Encryption', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimaryOf(context), letterSpacing: -0.3)),
                const SizedBox(height: 6),
                Text('All clinical documents are stored in a secure, HIPAA-compliant vault.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), height: 1.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryFeed extends StatelessWidget {
  _SummaryFeed();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SummaryItem(icon: Icons.description_rounded, label: 'DOCUMENTS', status: 'FINALIZED', color: AppColors.success),
        _SummaryItem(icon: Icons.fingerprint_rounded, label: 'BIOMETRICS', status: 'MATCHED', color: AppColors.success),
        _SummaryItem(icon: Icons.account_balance_rounded, label: 'LICENSE', status: 'REVIEWING', color: AppColors.warning),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final Color color;

  const _SummaryItem({required this.icon, required this.label, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (math.min(MediaQuery.of(context).size.width, 500) - 48 - 32) / 3,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textTertiaryOf(context), letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _InfoHub extends StatelessWidget {
  _InfoHub();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.primary.withValues(alpha: 0.1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text('You can continue using the platform as a patient while we review.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w700, height: 1.4))),
        ],
      ),
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
