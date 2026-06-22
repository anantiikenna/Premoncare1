import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import 'patient_providers.dart';
import '../../shared/widgets/generic_user_avatar.dart';

class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(patientDetailedCreditsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(top: -150, right: -100, child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.1), size: 500)),
          Positioned(bottom: -100, left: -50, child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.05), size: 400)),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(context),
                  const SizedBox(height: 24),
                  Text('FINANCIAL HUB', style: AppTypography.overline.copyWith(color: AppColors.textSecondaryOf(context), letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Text('Consultation Credits', style: AppTypography.h1.copyWith(letterSpacing: -1.0)),
                  const SizedBox(height: 32),
                  _HeaderStatsCard(creditsAsync: creditsAsync),
                  const SizedBox(height: 32),
                  _buildActionGrid(context),
                  const SizedBox(height: 40),
                  Text('MY DOCTOR CREDITS', style: AppTypography.overline.copyWith(color: AppColors.textSecondaryOf(context), letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  creditsAsync.when(
                    data: (credits) {
                      if (credits.isEmpty) return _buildEmptyCreditsState(context);
                      return Column(
                        children: credits.map((credit) => _DoctorCreditCard(
                          name: credit['doctor_name'],
                          specialty: credit['specialty'],
                          rate: '₦${credit['hourly_rate']}/hr',
                          remainingMinutes: credit['minutes_remaining'] as int,
                          totalMinutes: (credit['minutes_remaining'] as int) + 30,
                          lastUsed: 'Recently',
                          avatarUrl: credit['avatar_url'],
                        )).toList(),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                    error: (_, _) => _buildEmptyCreditsState(context),
                  ),
                  const SizedBox(height: 32),
                  const _DisclaimerBanner(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderOf(context))),
              child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickAction(icon: Icons.timer_rounded, label: 'Buy Time', color: AppColors.primary, onTap: () => context.push('/doctor-search'))),
        const SizedBox(width: 12),
        Expanded(child: _QuickAction(icon: Icons.upload_file_rounded, label: 'Upload Receipt', color: AppColors.success, onTap: () => context.push('/upload-receipt'))),
        const SizedBox(width: 12),
        Expanded(child: _QuickAction(icon: Icons.receipt_long_rounded, label: 'History', color: AppColors.warning, onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction history will appear here after your first credit purchase')));
        })),
        const SizedBox(width: 12),
        Expanded(child: _QuickAction(icon: Icons.help_outline_rounded, label: 'Guide', color: AppColors.info, onTap: () {
          context.push('/help-support');
        })),
      ],
    );
  }

  Widget _buildEmptyCreditsState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: AppColors.textTertiaryOf(context), size: 48),
          const SizedBox(height: 16),
          Text('No credits yet', style: AppTypography.h4),
          const SizedBox(height: 8),
          Text(
            'Purchase time credits to consult with your doctors',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
                  onPressed: () => context.push('/doctor-search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Buy Credits', style: AppTypography.labelLarge.copyWith(color: AppColors.textInverse)),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatsCard extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> creditsAsync;

  const _HeaderStatsCard({required this.creditsAsync});

  @override
  Widget build(BuildContext context) {
    final int totalMinutes = creditsAsync.maybeWhen(
      data: (credits) => credits.fold(0, (sum, item) => sum + (item['minutes_remaining'] as int)),
      orElse: () => 0,
    );
    final int activeDoctors = creditsAsync.maybeWhen(
      data: (credits) => credits.length,
      orElse: () => 0,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.shadowMedium, blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined, color: AppColors.textInverse, size: 14),
                        SizedBox(width: 6),
                        Text('Total Remaining', style: TextStyle(color: AppColors.textInverse, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$totalMinutes', style: const TextStyle(color: AppColors.textInverse, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2.0)),
                        const SizedBox(width: 6),
                        const Text('mins', style: TextStyle(color: AppColors.textInverse, fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Across $activeDoctors Active Doctors', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(width: 1, height: 80, color: AppColors.borderLightOf(context), margin: const EdgeInsets.symmetric(horizontal: 20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Active Credits', style: TextStyle(color: AppColors.textInverse, fontSize: 10, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('$activeDoctors', style: const TextStyle(color: AppColors.textInverse, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    const Text('Status', style: TextStyle(color: AppColors.textInverse, fontSize: 10, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(totalMinutes > 0 ? 'Active' : 'Empty', style: TextStyle(color: totalMinutes > 0 ? AppColors.success : AppColors.warning, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLightOf(context)),
              boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Center(child: Icon(icon, color: color, size: 24)),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryOf(context))),
        ],
      ),
    );
  }
}

class _DoctorCreditCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String rate;
  final int remainingMinutes;
  final int totalMinutes;
  final String lastUsed;
  final String? avatarUrl;

  const _DoctorCreditCard({
    required this.name,
    required this.specialty,
    required this.rate,
    required this.remainingMinutes,
    required this.totalMinutes,
    required this.lastUsed,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalMinutes > 0 ? remainingMinutes / totalMinutes : 0;
    final bool isLow = remainingMinutes < 15;
    final Color progressColor = isLow ? AppColors.error : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isLow ? AppColors.errorLightOf(context) : AppColors.borderLightOf(context)),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GenericUserAvatar(radius: 28, avatarUrl: avatarUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(specialty, style: AppTypography.bodySmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.borderLightOf(context), borderRadius: BorderRadius.circular(8)),
                      child: Text(rate, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryOf(context))),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$remainingMinutes', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: progressColor, letterSpacing: -1.0)),
                  Text('mins', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textTertiaryOf(context))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, backgroundColor: AppColors.borderLightOf(context), color: progressColor, minHeight: 8),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last used $lastUsed', style: AppTypography.caption),
              Text('$remainingMinutes / $totalMinutes mins', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryOf(context))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
            onPressed: () => context.push('/doctor-search'),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text('Buy More', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/doctor-search'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textInverse, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Consult', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withValues(alpha: 0.1))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Credits are doctor-specific. Time credits can only be used to consult with the doctor who credited them. Unused time never expires.',
              style: AppTypography.bodySmall.copyWith(height: 1.5, color: AppColors.textSecondaryOf(context)),
            ),
          ),
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
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)]));
  }
}
