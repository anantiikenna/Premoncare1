import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';


class ConsultationSummaryScreen extends ConsumerWidget {
  final String appointmentId;
  final String? doctorName;
  final String? doctorSpecialty;
  const ConsultationSummaryScreen({super.key, required this.appointmentId, this.doctorName, this.doctorSpecialty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = AppColors.primary;
    final successColor = AppColors.success;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
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
                  Text('SESSION FINALIZED', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Text('Summary Report', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0)),
                  const SizedBox(height: 32),

                  _SuccessHub(successColor: successColor),
                  const SizedBox(height: 40),

                  _buildSectionTitle(context, 'CONSULTING SPECIALIST'),
                  const SizedBox(height: 16),
                  _SpecialistSummaryCard(primaryColor: primaryColor, doctorName: doctorName, doctorSpecialty: doctorSpecialty),
                  const SizedBox(height: 40),

                  _buildSectionTitle(context, 'CLINICAL PRESCRIPTION'),
                  const SizedBox(height: 16),
                  _PrescriptionFeed(),
                  const SizedBox(height: 40),

                  _buildSectionTitle(context, 'DOCTOR\'S OBSERVATIONS'),
                  const SizedBox(height: 16),
                  _ObservationModule(),
                  const SizedBox(height: 40),

                  _FollowUpHub(primaryColor: primaryColor),
                  const SizedBox(height: 40),

                  _buildSectionTitle(context, 'EXPERIENCE RATING'),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderOf(context))), child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context), size: 20)),
          ),
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderOf(context))), child: Icon(Icons.share_rounded, color: AppColors.textPrimaryOf(context), size: 20)),
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
  final String? doctorName;
  final String? doctorSpecialty;
  const _SpecialistSummaryCard({required this.primaryColor, this.doctorName, this.doctorSpecialty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Row(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text('A', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctorName ?? '', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(doctorSpecialty ?? 'General Medical Physician', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w700)),
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
        _MedicationModule(name: 'Amoxicillin 500mg', instructions: '1 CAPSULE • 3X DAILY • POST-PRANDIAL', duration: '7 DAYS', color: AppColors.primary),
        _MedicationModule(name: 'Paracetamol 500mg', instructions: '1 TABLET • AS REQUIRED • PAIN MANAGEMENT', duration: '5 DAYS', color: AppColors.info),
        _MedicationModule(name: 'Cetirizine 10mg', instructions: '1 TABLET • 1X DAILY • NOCTURNAL', duration: '7 DAYS', color: AppColors.primary),
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
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.medication_rounded, color: color, size: 22)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(instructions, style: TextStyle(fontSize: 10, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ],
            ),
          ),
          Text(duration, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textTertiaryOf(context), letterSpacing: 0.5)),
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
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Text(
        'Presenting symptoms indicate a mild upper respiratory tract infection. Essential to maintain high hydration levels and strict adherence to the antimicrobial regimen. Re-evaluate if clinical status remains unchanged after 5 days.',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondaryOf(context), height: 1.6, fontWeight: FontWeight.w600),
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
                Text('Scheduled in 7 days to monitor clinical trajectory.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w700, height: 1.4)),
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
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.star_rounded, color: AppColors.warning, size: 32))),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.textPrimaryOf(context), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
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
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderOf(context))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondaryOf(context)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textSecondaryOf(context), fontSize: 12, letterSpacing: 0.5)),
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
