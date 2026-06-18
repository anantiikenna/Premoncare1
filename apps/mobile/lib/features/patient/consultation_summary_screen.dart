import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class ConsultationSummaryScreen extends ConsumerWidget {
  final String appointmentId;
  const ConsultationSummaryScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(context),
                  const SizedBox(height: 24),
                  const Text('SESSION FINALIZED', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  const Text('Summary Report', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1.0)),
                  const SizedBox(height: 32),

                  _SuccessHub(successColor: successColor),
                  const SizedBox(height: 40),

                  _buildSectionTitle('CONSULTING SPECIALIST'),
                  const SizedBox(height: 16),
                  _SpecialistSummaryCard(primaryColor: primaryColor),
                  const SizedBox(height: 40),

                  _buildSectionTitle('CLINICAL PRESCRIPTION'),
                  const SizedBox(height: 16),
                  _PrescriptionFeed(),
                  const SizedBox(height: 40),

                  _buildSectionTitle('DOCTOR\'S OBSERVATIONS'),
                  const SizedBox(height: 16),
                  _ObservationModule(),
                  const SizedBox(height: 40),

                  _FollowUpHub(primaryColor: primaryColor),
                  const SizedBox(height: 40),

                  _buildSectionTitle('EXPERIENCE RATING'),
                  const SizedBox(height: 16),
                  _FeedbackModule(),
                  const SizedBox(height: 48),

                  _ActionHub(context: context, primaryColor: primaryColor),
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))), child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 20)),
          ),
          Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))), child: const Icon(Icons.share_rounded, color: Color(0xFF1E293B), size: 20)),
        ],
      ),
    );
  }
}

class _SuccessHub extends StatelessWidget {
  final Color successColor;
  const _SuccessHub({required this.successColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [successColor, successColor.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [BoxShadow(color: successColor.withValues(alpha: 0.25), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.verified_rounded, color: Colors.white, size: 32)),
          const SizedBox(width: 24),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session Complete', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                SizedBox(height: 4),
                Text('Your clinical encounter has been verified and securely archived.', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialistSummaryCard extends StatelessWidget {
  final Color primaryColor;
  const _SpecialistSummaryCard({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF0F62FE).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text('A', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F62FE))),
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dr. Adaeze Nwosu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                SizedBox(height: 4),
                Text('General Medical Physician • PC-9921', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)), child: Text('VERIFIED', style: TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
        ],
      ),
    );
  }
}

class _PrescriptionFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MedicationModule(name: 'Amoxicillin 500mg', instructions: '1 CAPSULE • 3X DAILY • POST-PRANDIAL', duration: '7 DAYS', color: Colors.indigo),
        _MedicationModule(name: 'Paracetamol 500mg', instructions: '1 TABLET • AS REQUIRED • PAIN MANAGEMENT', duration: '5 DAYS', color: Colors.blue),
        _MedicationModule(name: 'Cetirizine 10mg', instructions: '1 TABLET • 1X DAILY • NOCTURNAL', duration: '7 DAYS', color: Colors.purple),
      ],
    );
  }
}

class _MedicationModule extends StatelessWidget {
  final String name;
  final String instructions;
  final String duration;
  final Color color;

  const _MedicationModule({required this.name, required this.instructions, required this.duration, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.medication_rounded, color: color, size: 22)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(instructions, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ],
            ),
          ),
          Text(duration, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFCBD5E1), letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _ObservationModule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: const Text(
        'Presenting symptoms indicate a mild upper respiratory tract infection. Essential to maintain high hydration levels and strict adherence to the antimicrobial regimen. Re-evaluate if clinical status remains unchanged after 5 days.',
        style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.6, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FollowUpHub extends StatelessWidget {
  final Color primaryColor;
  const _FollowUpHub({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(36), border: Border.all(color: primaryColor.withValues(alpha: 0.1))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXT EVALUATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1)),
                const SizedBox(height: 6),
                const Text('Scheduled in 7 days to monitor clinical trajectory.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => context.go('/doctor-search'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 10, shadowColor: primaryColor.withValues(alpha: 0.3), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('SCHEDULE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _FeedbackModule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 32))),
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
        Row(
          children: [
            Expanded(child: _SecondaryAction(icon: Icons.picture_as_pdf_rounded, label: 'PDF REPORT')),
            const SizedBox(width: 16),
            Expanded(child: _SecondaryAction(icon: Icons.share_rounded, label: 'SHARE LINK')),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () => context.go('/account-conversion'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
            child: const Text('DISMISS REPORT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SecondaryAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 12, letterSpacing: 0.5)),
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
