import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_locator.dart';
import '../../core/providers.dart';
import '../../core/app_colors.dart';
import 'patient_providers.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/mode_switch_dialog.dart';
import '../../shared/widgets/global_user_avatar.dart';


class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = supabase.auth.currentUser;
    final userProfile = ref.watch(userProfileProvider);
    final email = user?.email ?? 'patient@premoncare.com';

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.08), size: 500),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.03), size: 300),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildUserCard(context, email, userProfile.asData?.value),
                  const SizedBox(height: 32),
                  _buildAccountModeSwitcher(context, userProfile.asData?.value),
                  const SizedBox(height: 32),
                  _buildStatsGrid(context, ref),
                  const SizedBox(height: 32),
                  _buildMenuSection(context, userProfile.asData?.value),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACCOUNT SETTINGS', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text('Your Profile', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0)),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderLightOf(context)),
            boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10)],
          ),
          child: IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.textPrimaryOf(context)),
            onPressed: () => context.push('/settings-privacy'),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, String email, Map<String, dynamic>? profile) {
    final role = profile?['role'] ?? 'patient';
    final status = profile?['verification_status'] ?? 'unsubmitted';
    
    final bool isVerified = status == 'approved' || status == 'verified';
    final String badgeText = isVerified 
        ? 'VERIFIED ${role.toUpperCase()}' 
        : (status == 'pending' ? 'PENDING VERIFICATION' : 'UNVERIFIED PATIENT');
    final Color badgeColor = isVerified ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderLightOf(context)),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLightOf(context), width: 2),
                ),
                child: const GlobalUserAvatar(radius: 40),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, size: 12, color: AppColors.textInverse),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile?['full_name'] ?? 'Rohan Mehta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isVerified ? Icons.verified_rounded : Icons.pending_rounded, color: badgeColor, size: 12),
                      const SizedBox(width: 6),
                      Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountModeSwitcher(BuildContext context, Map<String, dynamic>? profile) {
    final bool isVerified = profile?['verification_status'] == 'approved';
    final String currentPath = GoRouterState.of(context).matchedLocation;
    final bool isDoctorMode = currentPath.startsWith('/doctor');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.slate800, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: AppColors.slate800.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sync_rounded, color: Colors.white, size: 18),
              SizedBox(width: 12),
              Text('UNIFIED ACCOUNT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildModeTab('Patient Mode', Icons.person_rounded, !isDoctorMode, isDoctorMode ? () => _showModeSwitchDialog(context, 'Patient') : () {})),
              const SizedBox(width: 12),
              Expanded(child: _buildModeTab('Doctor Mode', Icons.medical_services_rounded, isDoctorMode, !isDoctorMode ? (isVerified ? () => _showModeSwitchDialog(context, 'Doctor') : null) : () {})),
            ],
          ),
          if (!isVerified) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => context.push('/verify-practitioner'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: Colors.white70),
                    SizedBox(width: 12),
                    Expanded(child: Text('Complete verification to unlock Practitioner features', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600))),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, IconData icon, bool isActive, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(patientAppointmentsProvider);
    final recordsAsync = ref.watch(patientMedicalRecordsProvider);
    final creditsAsync = ref.watch(patientCreditsProvider);

    final apptsCount = appointmentsAsync.asData?.value.where((a) => a['status'] == 'scheduled').length.toString() ?? '0';
    final historyCount = appointmentsAsync.asData?.value.where((a) => a['status'] == 'completed').length.toString() ?? '0';
    final reportsCount = recordsAsync.asData?.value.length.toString() ?? '0';
    final credits = creditsAsync.asData?.value ?? 0;

    return Row(
      children: [
        _buildStatItem(context, apptsCount, 'Appts', Icons.calendar_month_rounded, AppColors.primary),
        const SizedBox(width: 12),
        _buildStatItem(context, historyCount, 'History', Icons.history_rounded, AppColors.success),
        const SizedBox(width: 12),
        _buildStatItem(context, reportsCount, 'Reports', Icons.description_rounded, AppColors.primary),
        const SizedBox(width: 12),
        _buildStatItem(context, '${credits}m', 'Credits', Icons.account_balance_wallet_rounded, AppColors.warning, onTap: () => context.push('/credits')),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLightOf(context))),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 12),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
              Text(label, style: TextStyle(fontSize: 10, color: AppColors.textTertiaryOf(context), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, Map<String, dynamic>? profile) {
    final status = profile?['verification_status'] ?? 'unsubmitted';
    final String statusLabel = status == 'approved' ? 'Verified' : (status == 'pending' ? 'Reviewing' : 'Register');
    final Color statusColor = status == 'approved' ? AppColors.success : (status == 'pending' ? AppColors.warning : AppColors.primary);

    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Column(
        children: [
          _buildMenuTile(context, Icons.person_rounded, 'Personal Information', onTap: () => context.push('/settings-privacy')),
          _buildMenuTile(context, Icons.verified_rounded, 'Practitioner Registration', badge: statusLabel, badgeColor: statusColor, onTap: () => context.push('/verify-practitioner')),
          _buildMenuTile(context, Icons.folder_shared_rounded, 'Medical Records', onTap: () => context.push('/vault')),
          _buildMenuTile(context, Icons.payment_rounded, 'My Credits & Billing', onTap: () => context.push('/credits')),
          _buildMenuTile(context, Icons.notifications_rounded, 'Notifications', onTap: () => context.push('/notifications')),
          _buildMenuTile(context, Icons.help_center_rounded, 'Help & Support', isLast: true, onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Support: support@premoncare.com | WhatsApp: +234 800 000 0000'), duration: Duration(seconds: 4)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, {String? badge, Color? badgeColor, VoidCallback? onTap, bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.primary, size: 20)),
          title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimaryOf(context))),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: badgeColor!.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w900))),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 72, endIndent: 24, color: AppColors.borderLightOf(context)),
      ],
    );
  }

  void _showModeSwitchDialog(BuildContext context, String target) {
    showDialog(
      context: context,
      builder: (context) => ModeSwitchDialog(
        targetMode: target,
        onConfirm: () => context.go(target == 'Doctor' ? '/doctor_dashboard' : '/patient_dashboard'),
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
