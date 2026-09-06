import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/privacy_service.dart';

class BiometricPrivacyScreen extends StatefulWidget {
  const BiometricPrivacyScreen({super.key});

  @override
  State<BiometricPrivacyScreen> createState() => _BiometricPrivacyScreenState();
}

class _BiometricPrivacyScreenState extends State<BiometricPrivacyScreen> {
  final _biometricService = BiometricService();
  bool _biometricLock = false;
  bool _profileVisible = true;
  bool _showOnlineStatus = true;
  bool _shareDataForResearch = false;
  bool _allowCrashReporting = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _biometricLock = prefs.getBool('privacy_biometric') ?? false;
      _profileVisible = prefs.getBool('privacy_profile_visible') ?? true;
      _showOnlineStatus = prefs.getBool('privacy_online_status') ?? true;
      _shareDataForResearch = prefs.getBool('privacy_research') ?? false;
      _allowCrashReporting = prefs.getBool('privacy_crash_reporting') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

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
          _buildToggle(
            icon: Icons.fingerprint_rounded,
            color: AppColors.primary,
            title: 'Biometric Lock',
            subtitle: 'Require fingerprint or face to open app',
            value: _biometricLock,
            onChanged: (v) async {
              if (v) {
                // Turning ON — verify device capability first
                final available = await _biometricService.isAvailable();
                if (!available) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Biometrics not available on this device')),
                    );
                  }
                  return;
                }

                // Prompt for confirmation before enabling
                final authenticated = await _biometricService.authenticate();
                if (!authenticated) return;

                await _biometricService.setEnabled(true);
                setState(() => _biometricLock = true);
              } else {
                // Turning OFF — just save
                await _biometricService.setEnabled(false);
                setState(() => _biometricLock = false);
              }
            },
          ),
          const SizedBox(height: 24),
          Text('VISIBILITY', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildToggle(icon: Icons.visibility_rounded, color: AppColors.success, title: 'Profile Visibility', subtitle: 'Allow doctors to see your profile', value: _profileVisible, onChanged: (v) { setState(() => _profileVisible = v); _savePreference('privacy_profile_visible', v); PrivacyService().syncToServer(); }),
          _buildToggle(icon: Icons.circle_rounded, color: AppColors.info, title: 'Online Status', subtitle: 'Show when you are online', value: _showOnlineStatus, onChanged: (v) { setState(() => _showOnlineStatus = v); _savePreference('privacy_online_status', v); PrivacyService().syncToServer(); }),
          const SizedBox(height: 24),
          Text('DATA', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildToggle(icon: Icons.science_rounded, color: AppColors.primary, title: 'Research Data Sharing', subtitle: 'Share anonymized data for medical research', value: _shareDataForResearch, onChanged: (v) { setState(() => _shareDataForResearch = v); _savePreference('privacy_research', v); }),
          _buildToggle(icon: Icons.bug_report_rounded, color: AppColors.warning, title: 'Crash Reporting', subtitle: 'Help improve the app by sending crash reports', value: _allowCrashReporting, onChanged: (v) { setState(() => _allowCrashReporting = v); _savePreference('privacy_crash_reporting', v); }),
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
