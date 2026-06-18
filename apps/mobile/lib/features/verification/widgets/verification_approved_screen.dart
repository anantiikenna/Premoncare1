import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class VerificationApprovedScreen extends StatelessWidget {
  const VerificationApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);
    const successColor = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Immersive mesh background
          Positioned(top: -150, left: -100, child: _MeshCircle(color: primaryColor.withValues(alpha: 0.1), size: 500)),
          Positioned(bottom: -100, right: -50, child: _MeshCircle(color: successColor.withValues(alpha: 0.05), size: 400)),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _CelebrationHeader(successColor: successColor),
                  const SizedBox(height: 40),

                  _StatusTimeline(successColor: successColor),
                  const SizedBox(height: 40),

                  _UnlockedFeaturesFeed(successColor: successColor),
                  const SizedBox(height: 40),

                  _SpecialistOnboardingCard(primaryColor: primaryColor),
                  const SizedBox(height: 48),

                  _ActionHub(context: context, primaryColor: primaryColor),
                  const SizedBox(height: 24),

                  _SecurityNotice(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationHeader extends StatelessWidget {
  final Color successColor;
  const _CelebrationHeader({required this.successColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: successColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: successColor.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 0)],
          ),
          child: Icon(Icons.verified_rounded, color: successColor, size: 64),
        ),
        const SizedBox(height: 32),
        const Text('Congratulations!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1.0)),
        const SizedBox(height: 8),
        Text('Verified Practitioner Status Active', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: successColor, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Your professional credentials have been validated. You now have full clinical authority on the Premon Care platform.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final Color successColor;
  const _StatusTimeline({required this.successColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatusStep(label: 'Profile', status: 'COMPLETE', color: successColor),
          _StatusStep(label: 'Documents', status: 'VERIFIED', color: successColor),
          _StatusStep(label: 'Biometrics', status: 'MATCHED', color: successColor),
          _StatusStep(label: 'Clinical Board', status: 'APPROVED', color: successColor),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final String label;
  final String status;
  final Color color;

  const _StatusStep({required this.label, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.white, size: 10)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(status, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
      ],
    );
  }
}

class _UnlockedFeaturesFeed extends StatelessWidget {
  final Color successColor;
  const _UnlockedFeaturesFeed({required this.successColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('UNLOCKED CAPABILITIES', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _FeatureCard(icon: Icons.dashboard_customize_rounded, title: 'Clinical Console', subtitle: 'Manage schedule & workflow', color: successColor),
            _FeatureCard(icon: Icons.groups_rounded, title: 'Patient Hub', subtitle: 'Direct patient management', color: successColor),
            _FeatureCard(icon: Icons.payments_rounded, title: 'Revenue Vault', subtitle: 'Track clinical earnings', color: successColor),
            _FeatureCard(icon: Icons.videocam_rounded, title: 'Telehealth', subtitle: 'Conduct video consults', color: successColor),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B), letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), height: 1.2, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SpecialistOnboardingCard extends StatelessWidget {
  final Color primaryColor;
  const _SpecialistOnboardingCard({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(32), border: Border.all(color: primaryColor.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('READY TO COMMENCE PRACTICE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B), letterSpacing: -0.5)),
          const SizedBox(height: 12),
          const Text('Activate Doctor Mode to explore your professional console and initiate patient engagements.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          _CheckRow(text: 'Public profile now discoverable'),
          _CheckRow(text: 'Configurable availability & rates'),
          _CheckRow(text: 'Full clinical toolset activated'),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String text;
  const _CheckRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ActionHub extends StatelessWidget {
  final BuildContext context;
  final Color primaryColor;
  const _ActionHub({required this.context, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () => context.go('/doctor_dashboard'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 15, shadowColor: primaryColor.withValues(alpha: 0.3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sync_rounded, size: 20),
                SizedBox(width: 12),
                Text('SWITCH TO DOCTOR MODE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: OutlinedButton(
            onPressed: () => context.go('/patient_dashboard'),
            style: OutlinedButton.styleFrom(foregroundColor: primaryColor, side: BorderSide(color: primaryColor, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
            child: const Text('PATIENT DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 14),
        SizedBox(width: 12),
        Text('256-bit AES Encryption Secure Storage', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
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

