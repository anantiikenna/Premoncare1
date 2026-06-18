import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    const bgColor = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildTitleSection(),
            const SizedBox(height: 24),
            _buildProfileSummary(email, userProfile.asData?.value),
            const SizedBox(height: 32),
            _buildSectionHeader('Account Settings'),
            const SizedBox(height: 12),
            _buildAccountSettings(context),
            const SizedBox(height: 32),
            _buildSectionHeader('Privacy & Data'),
            const SizedBox(height: 12),
            _buildPrivacyDataSettings(context),
            const SizedBox(height: 32),
            _buildSectionHeader('Preferences'),
            const SizedBox(height: 12),
            _buildPreferencesSettings(context),
            const SizedBox(height: 32),
            _buildSectionHeader('Support & Legal'),
            const SizedBox(height: 12),
            _buildSupportLegalSettings(context),
            const SizedBox(height: 32),
            _buildFooterAlert(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
        onPressed: () => context.pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
              ],
            ),
            child: const Icon(Icons.medical_services_rounded, color: Color(0xFF0F62FE), size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'Premon',
            style: TextStyle(
              color: Color(0xFF0F62FE),
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          const Text(
            'Care',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B)),
              onPressed: () => context.push('/notifications'),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                child: const Text('8', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16, left: 4),
          child: GlobalUserAvatar(radius: 16),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.shield_rounded, color: Color(0xFF8B5CF6), size: 28),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings & Privacy Center',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage your account, preferences and privacy settings',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSummary(String email, Map<String, dynamic>? profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              const GlobalUserAvatar(radius: 20),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?['full_name'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 10),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Row(
            children: [
              Text(
                'View Profile',
                style: TextStyle(
                  color: Color(0xFF0F62FE),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF0F62FE), size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1E293B),
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.person_outline_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Personal Information',
            subtitle: 'Update your personal details and contact information',
            onTap: () => _showComingSoon(context, 'Personal Information'),
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline_rounded,
            color: const Color(0xFF10B981),
            title: 'Login & Security',
            subtitle: 'Manage password, 2FA and account security',
            isDivider: true,
            onTap: () => _showComingSoon(context, 'Login & Security'),
          ),
          _buildSettingsTile(
            icon: Icons.notifications_none_rounded,
            color: const Color(0xFF8B5CF6),
            title: 'Notification Preferences',
            subtitle: 'Choose what notifications you want to receive',
            isDivider: true,
            onTap: () => _showComingSoon(context, 'Notification Preferences'),
          ),
          _buildSettingsTile(
            icon: Icons.language_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Language & Region',
            subtitle: 'Select your language and region',
            trailingText: 'English (US)',
            isDivider: true,
            isLast: true,
            onTap: () => _showComingSoon(context, 'Language & Region'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyDataSettings(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.shield_outlined,
            color: const Color(0xFF10B981),
            title: 'Biometric & Privacy Controls',
            subtitle: 'Manage who can see your information and biometric data',
            onTap: () => _showComingSoon(context, 'Biometric & Privacy Controls'),
          ),
          _buildSettingsTile(
            icon: Icons.medical_information_outlined,
            color: const Color(0xFF3B82F6),
            title: 'Medical Record Permissions',
            subtitle: 'Manage who can access your medical records',
            isDivider: true,
            onTap: () => _showComingSoon(context, 'Medical Record Permissions'),
          ),
          _buildSettingsTile(
            icon: Icons.devices_rounded,
            color: const Color(0xFF8B5CF6),
            title: 'Device Sessions & Activity',
            subtitle: 'View and manage active sessions and data activity',
            isDivider: true,
            onTap: () => _showComingSoon(context, 'Device Sessions & Activity'),
          ),
          _buildSettingsTile(
            icon: Icons.file_download_outlined,
            color: const Color(0xFFF59E0B),
            title: 'Download My Data',
            subtitle: 'Download a copy of your health data',
            isDivider: true,
            onTap: () => _showComingSoon(context, 'Download My Data'),
          ),
          _buildSettingsTile(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFEF4444),
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and data',
            isDivider: true,
            isLast: true,
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSettings(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.dark_mode_outlined,
            color: const Color(0xFF10B981),
            title: 'Appearance',
            subtitle: 'Choose light or dark mode',
            trailingText: 'Light Mode',
            onTap: () => _showComingSoon(context, 'Appearance'),
          ),
          _buildSettingsTile(
            icon: Icons.accessibility_new_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Accessibility',
            subtitle: 'Text size, contrast and accessibility options',
            isDivider: true,
            onTap: () => _showComingSoon(context, 'Accessibility'),
          ),
          _buildSettingsTile(
            icon: Icons.favorite_border_rounded,
            color: const Color(0xFF8B5CF6),
            title: 'Health Preferences',
            subtitle: 'Health goals, units and other preferences',
            isDivider: true,
            isLast: true,
            onTap: () => _showComingSoon(context, 'Health Preferences'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportLegalSettings(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.headset_mic_outlined,
            color: const Color(0xFF3B82F6),
            title: 'Help & Support',
            subtitle: 'Get help, contact support or view FAQs',
            onTap: () => _showComingSoon(context, 'Help & Support'),
          ),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            color: const Color(0xFF10B981),
            title: 'Terms of Service',
            subtitle: 'Read our terms and conditions',
            isDivider: true,
            onTap: () => _showComingSoon(context, 'Terms of Service'),
          ),
          _buildSettingsTile(
            icon: Icons.verified_user_outlined,
            color: const Color(0xFF8B5CF6),
            title: 'Privacy Policy',
            subtitle: 'Learn how we protect your privacy',
            isDivider: true,
            onTap: () => _showComingSoon(context, 'Privacy Policy'),
          ),
          _buildSettingsTile(
            icon: Icons.info_outline_rounded,
            color: const Color(0xFFF59E0B),
            title: 'About Premon Care',
            subtitle: 'App version 2.4.1',
            isDivider: true,
            isLast: true,
            onTap: () => _showComingSoon(context, 'About Premon Care'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your privacy is our priority',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'We use industry-standard encryption to protect your data and keep it secure.',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? trailingText,
    bool isDivider = false,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        if (isDivider)
          const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF1F5F9)),
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
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Text(
                  trailingText,
                  style: const TextStyle(
                    color: Color(0xFF0F62FE),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$featureName coming soon')),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and all your health data will be erased.',
          style: TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 13),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would trigger re-authentication before deletion
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
