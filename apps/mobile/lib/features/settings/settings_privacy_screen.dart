import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/supabase_locator.dart';
import '../../core/providers.dart';
import '../../shared/widgets/global_user_avatar.dart';

class SettingsPrivacyCenterScreen extends ConsumerWidget {
  const SettingsPrivacyCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = supabase.auth.currentUser;
    final userProfile = ref.watch(userProfileProvider);
    final email = user?.email ?? 'patient@premoncare.com';

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildTitleSection(context),
            const SizedBox(height: 24),
            _buildProfileSummary(context, email, userProfile.asData?.value),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Account Settings'),
            const SizedBox(height: 12),
            _buildAccountSettings(context),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Privacy & Data'),
            const SizedBox(height: 12),
            _buildPrivacyDataSettings(context),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Preferences'),
            const SizedBox(height: 12),
            _buildPreferencesSettings(context),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Support & Legal'),
            const SizedBox(height: 12),
            _buildSupportLegalSettings(context),
            const SizedBox(height: 32),
            _buildFooterAlert(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final color = AppColors.textPrimaryOf(context);
    return AppBar(
      backgroundColor: AppColors.surfaceOf(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: color),
        onPressed: () => context.pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/logo-horizontal.png',
            height: 28,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 8),
                Text('Premon', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                Text('Care', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
              ],
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: color),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => context.push('/personal-info'),
            child: const GlobalUserAvatar(radius: 16),
          ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    final color = AppColors.textPrimaryOf(context);
    final secondary = AppColors.textSecondaryOf(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings & Privacy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('Manage your account and preferences', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSummary(BuildContext context, String email, Map<String, dynamic>? profile) {
    final color = AppColors.textPrimaryOf(context);
    final secondary = AppColors.textSecondaryOf(context);
    return GestureDetector(
      onTap: () => context.push('/personal-info'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const GlobalUserAvatar(radius: 20),
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceOf(context), width: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile?['full_name'] ?? 'User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
                  Text(email, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, color: AppColors.success, size: 10),
                        SizedBox(width: 4),
                        Text('Verified', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryOf(context), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(title, style: AppTypography.labelMediumOf(context).copyWith(letterSpacing: -0.3, fontSize: 15, fontWeight: FontWeight.w900));
  }

  Widget _buildAccountSettings(BuildContext context) {
    return _buildGroup(context, [
      _SettingsTileData(icon: Icons.person_outline_rounded, color: AppColors.info, title: 'Personal Information', subtitle: 'Update your details', onTap: () => context.push('/personal-info')),
      _SettingsTileData(icon: Icons.lock_outline_rounded, color: AppColors.success, title: 'Login & Security', subtitle: 'Password and security settings', onTap: () => context.push('/login-security')),
      _SettingsTileData(icon: Icons.notifications_none_rounded, color: AppColors.primary, title: 'Notification Preferences', subtitle: 'Choose what notifications to receive', onTap: () => context.push('/notification-preferences')),
      _SettingsTileData(icon: Icons.language_rounded, color: AppColors.warning, title: 'Language & Region', subtitle: 'Language and region', trailingText: 'English', onTap: () => context.push('/language-region')),
    ]);
  }

  Widget _buildPrivacyDataSettings(BuildContext context) {
    return _buildGroup(context, [
      _SettingsTileData(icon: Icons.shield_outlined, color: AppColors.success, title: 'Biometric & Privacy', subtitle: 'Privacy and biometric controls', onTap: () => context.push('/biometric-privacy')),
      _SettingsTileData(icon: Icons.medical_information_outlined, color: AppColors.info, title: 'Record Permissions', subtitle: 'Manage doctor record access', onTap: () => context.push('/medical-record-permissions')),
      _SettingsTileData(icon: Icons.devices_rounded, color: AppColors.primary, title: 'Device Sessions', subtitle: 'Active sessions and activity', onTap: () => context.push('/device-sessions')),
      _SettingsTileData(icon: Icons.file_download_outlined, color: AppColors.warning, title: 'Download My Data', subtitle: 'Export your health data', onTap: () => context.push('/download-data')),
      _SettingsTileData(icon: Icons.delete_outline_rounded, color: AppColors.error, title: 'Delete Account', subtitle: 'Permanently delete your account', onTap: () => _showDeleteAccountDialog(context)),
    ]);
  }

  Widget _buildPreferencesSettings(BuildContext context) {
    return _buildGroup(context, [
      _SettingsTileData(icon: Icons.dark_mode_outlined, color: AppColors.success, title: 'Appearance', subtitle: 'Choose light or dark mode', onTap: () => context.push('/appearance')),
      _SettingsTileData(icon: Icons.accessibility_new_rounded, color: AppColors.info, title: 'Accessibility', subtitle: 'Text size and display options', onTap: () => context.push('/accessibility')),
      _SettingsTileData(icon: Icons.favorite_border_rounded, color: AppColors.primary, title: 'Health Preferences', subtitle: 'Units and health settings', onTap: () => context.push('/health-preferences')),
    ]);
  }

  Widget _buildSupportLegalSettings(BuildContext context) {
    return _buildGroup(context, [
      _SettingsTileData(icon: Icons.headset_mic_outlined, color: AppColors.info, title: 'Help & Support', subtitle: 'FAQs and contact support', onTap: () => context.push('/help-support')),
      _SettingsTileData(icon: Icons.description_outlined, color: AppColors.success, title: 'Terms of Service', subtitle: 'Read our terms', onTap: () => context.push('/terms-of-service')),
      _SettingsTileData(icon: Icons.verified_user_outlined, color: AppColors.primary, title: 'Privacy Policy', subtitle: 'How we protect your data', onTap: () => context.push('/privacy-policy')),
      _SettingsTileData(icon: Icons.info_outline_rounded, color: AppColors.warning, title: 'About Premon Care', subtitle: 'App version 2.4.1', onTap: () => context.push('/about')),
    ]);
  }

  Widget _buildGroup(BuildContext context, List<_SettingsTileData> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final i = entry.key;
          final tile = entry.value;
          return _buildSettingsTile(
            context: context,
            icon: tile.icon,
            color: tile.color,
            title: tile.title,
            subtitle: tile.subtitle,
            trailingText: tile.trailingText,
            isDivider: i > 0,
            onTap: tile.onTap,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? trailingText,
    bool isDivider = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        if (isDivider) Divider(height: 1, indent: 64, endIndent: 20, color: AppColors.dividerOf(context)),
        ListTile(
          onTap: onTap ?? () {},
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context))),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondaryOf(context))),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Text(trailingText, style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryOf(context), size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterAlert(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.success, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your privacy is our priority', style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('We use industry-standard encryption to protect your data.', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final color = AppColors.textPrimaryOf(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 18)),
          ],
        ),
        content: Text(
          'This will permanently delete your account and all health data. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondaryOf(context), height: 1.5, fontSize: 13),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textTertiaryOf(context), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final user = supabase.auth.currentUser;
                if (user != null) {
                  await supabase.from('audit_logs').insert({
                    'user_id': user.id,
                    'action': 'account_deletion_requested',
                  });
                }
                await supabase.auth.signOut();
                if (context.mounted) context.go('/login');
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SettingsTileData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? trailingText;
  final VoidCallback? onTap;

  const _SettingsTileData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailingText,
    this.onTap,
  });
}
