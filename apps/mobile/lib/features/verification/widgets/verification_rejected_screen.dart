import 'package:flutter/material.dart';


class VerificationRejectedScreen extends StatelessWidget {
  final String? reason;
  final VoidCallback onResubmit;

  const VerificationRejectedScreen({super.key, this.reason, required this.onResubmit});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);
    const errorColor = Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Immersive mesh background
          Positioned(top: -150, right: -100, child: _MeshCircle(color: errorColor.withValues(alpha: 0.1), size: 500)),
          Positioned(bottom: -100, left: -50, child: _MeshCircle(color: primaryColor.withValues(alpha: 0.05), size: 400)),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _ErrorHub(errorColor: errorColor),
                  const SizedBox(height: 40),

                  _buildSectionTitle('REQUIRED CORRECTIONS'),
                  const SizedBox(height: 16),
                  _CorrectionFeed(reason: reason, errorColor: errorColor),
                  const SizedBox(height: 40),

                  _buildSectionTitle('NEXT STEPS'),
                  const SizedBox(height: 16),
                  _ActionTileFeed(primaryColor: primaryColor),
                  const SizedBox(height: 40),

                  _SecurityBox(),
                  const SizedBox(height: 48),

                  _ActionHub(onResubmit: onResubmit, primaryColor: primaryColor),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }
}

class _ErrorHub extends StatelessWidget {
  final Color errorColor;
  const _ErrorHub({required this.errorColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(36), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: errorColor.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 20))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: errorColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.gpp_maybe_rounded, color: errorColor, size: 28)),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Review Incomplete', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                    SizedBox(height: 4),
                    Text('Action Required', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'We were unable to approve your clinical credentials at this time. Please address the highlighted issues below and resubmit for priority review.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.6, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CorrectionFeed extends StatelessWidget {
  final String? reason;
  final Color errorColor;
  const _CorrectionFeed({this.reason, required this.errorColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CorrectionCard(icon: Icons.badge_rounded, title: 'Identity Document', description: 'The uploaded ID is slightly blurry. Please ensure all text is legible and well-lit.', color: errorColor),
        _CorrectionCard(icon: Icons.face_rounded, title: 'Facial Biometric', description: 'The selfie does not match the provided ID document. Please retake in a brighter environment.', color: errorColor),
        if (reason != null) _CorrectionCard(icon: Icons.description_rounded, title: 'Clinical License', description: reason!, color: errorColor),
      ],
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _CorrectionCard({required this.icon, required this.title, required this.description, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B), letterSpacing: -0.3)),
                const SizedBox(height: 6),
                Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTileFeed extends StatelessWidget {
  final Color primaryColor;
  const _ActionTileFeed({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(icon: Icons.help_center_rounded, title: 'View Requirements', subtitle: 'Detailed guide on clinical standards', color: primaryColor),
        _ActionTile(icon: Icons.support_agent_rounded, title: 'Contact Support', subtitle: 'Speak with clinical onboarding', color: primaryColor),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B), letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
        ],
      ),
    );
  }
}

class _SecurityBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(28)),
      child: const Row(
        children: [
          Icon(Icons.lock_rounded, color: Color(0xFF64748B), size: 20),
          SizedBox(width: 16),
          Expanded(child: Text('Your information remains encrypted and protected in our private clinical vault.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700, height: 1.4))),
        ],
      ),
    );
  }
}

class _ActionHub extends StatelessWidget {
  final VoidCallback onResubmit;
  final Color primaryColor;
  const _ActionHub({required this.onResubmit, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: onResubmit,
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 15, shadowColor: primaryColor.withValues(alpha: 0.3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
            child: const Text('CORRECT & RESUBMIT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
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


