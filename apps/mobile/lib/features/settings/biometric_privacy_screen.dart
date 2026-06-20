import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';

class BiometricPrivacyScreen extends StatefulWidget {
  const BiometricPrivacyScreen({super.key});

  @override
  State<BiometricPrivacyScreen> createState() => _BiometricPrivacyScreenState();
}

class _BiometricPrivacyScreenState extends State<BiometricPrivacyScreen> {
  bool _biometricLock = false;
  bool _profileVisible = true;
  bool _showOnlineStatus = true;
  bool _shareDataForResearch = false;
  bool _allowCrashReporting = true;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.textPrimaryOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: color),
          onPressed: () => context.pop(),
        ),
        title: Text('Biometric & Privacy', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('SECURITY', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildToggle(icon: Icons.fingerprint_rounded, color: AppColors.primary, title: 'Biometric Lock', subtitle: 'Require fingerprint or face to open app', value: _biometricLock, onChanged: (v) => setState(() => _biometricLock = v)),
          const SizedBox(height: 24),
          Text('VISIBILITY', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildToggle(icon: Icons.visibility_rounded, color: AppColors.success, title: 'Profile Visibility', subtitle: 'Allow doctors to see your profile', value: _profileVisible, onChanged: (v) => setState(() => _profileVisible = v)),
          _buildToggle(icon: Icons.circle_rounded, color: AppColors.info, title: 'Online Status', subtitle: 'Show when you are online', value: _showOnlineStatus, onChanged: (v) => setState(() => _showOnlineStatus = v)),
          const SizedBox(height: 24),
          Text('DATA', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildToggle(icon: Icons.science_rounded, color: const Color(0xFF8B5CF6), title: 'Research Data Sharing', subtitle: 'Share anonymized data for medical research', value: _shareDataForResearch, onChanged: (v) => setState(() => _shareDataForResearch = v)),
          _buildToggle(icon: Icons.bug_report_rounded, color: AppColors.warning, title: 'Crash Reporting', subtitle: 'Help improve the app by sending crash reports', value: _allowCrashReporting, onChanged: (v) => setState(() => _allowCrashReporting = v)),
        ],
      ),
    );
  }

  Widget _buildToggle({required IconData icon, required Color color, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context))),
        trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
      ),
    );
  }
}
