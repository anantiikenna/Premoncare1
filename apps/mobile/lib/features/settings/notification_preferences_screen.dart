import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../core/supabase_locator.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _appointmentAlerts = true;
  bool _paymentAlerts = true;
  bool _clinicalAlerts = true;
  bool _forumUpdates = false;
  bool _emergencyAlerts = true;
  bool _marketingEmails = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushEnabled = prefs.getBool('notif_push') ?? true;
      _emailEnabled = prefs.getBool('notif_email') ?? false;
      _appointmentAlerts = prefs.getBool('notif_appointments') ?? true;
      _paymentAlerts = prefs.getBool('notif_payments') ?? true;
      _clinicalAlerts = prefs.getBool('notif_clinical') ?? true;
      _forumUpdates = prefs.getBool('notif_forum') ?? false;
      _emergencyAlerts = prefs.getBool('notif_emergency') ?? true;
      _marketingEmails = prefs.getBool('notif_marketing') ?? false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    // Sync email_alerts_enabled to server (used by web backend for notification dispatch)
    if (key == 'notif_email') {
      try {
        final user = supabase.auth.currentUser;
        if (user != null) {
          await supabase.from('profiles').update({
            'email_alerts_enabled': value,
          }).eq('id', user.id);
        }
      } catch (_) {}
    }
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
        title: Text(AppLocalizations.of(context)!.notificationPreferencesTile, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(AppLocalizations.of(context)!.channelsSection, style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildToggleTile(icon: Icons.notifications_active_rounded, color: AppColors.primary, title: AppLocalizations.of(context)!.pushNotificationsLabel, subtitle: AppLocalizations.of(context)!.receiveAlertsOnDevice, value: _pushEnabled, onChanged: (v) { setState(() => _pushEnabled = v); _savePreference('notif_push', v); }),
          _buildToggleTile(icon: Icons.email_outlined, color: AppColors.warning, title: AppLocalizations.of(context)!.emailNotificationsLabel, subtitle: AppLocalizations.of(context)!.receiveAlertsViaEmail, value: _emailEnabled, onChanged: (v) { setState(() => _emailEnabled = v); _savePreference('notif_email', v); }),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.categoriesSection, style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildToggleTile(icon: Icons.calendar_today_rounded, color: AppColors.success, title: AppLocalizations.of(context)!.appointmentAlertsLabel, subtitle: AppLocalizations.of(context)!.remindersForConsultations, value: _appointmentAlerts, onChanged: (v) { setState(() => _appointmentAlerts = v); _savePreference('notif_appointments', v); }),
          _buildToggleTile(icon: Icons.payment_rounded, color: AppColors.info, title: AppLocalizations.of(context)!.paymentAlertsLabel, subtitle: AppLocalizations.of(context)!.transactionConfirmations, value: _paymentAlerts, onChanged: (v) { setState(() => _paymentAlerts = v); _savePreference('notif_payments', v); }),
          _buildToggleTile(icon: Icons.medical_services_rounded, color: AppColors.primary, title: AppLocalizations.of(context)!.clinicalUpdatesLabel, subtitle: AppLocalizations.of(context)!.prescriptionUpdatesAndRecords, value: _clinicalAlerts, onChanged: (v) { setState(() => _clinicalAlerts = v); _savePreference('notif_clinical', v); }),
          _buildToggleTile(icon: Icons.forum_rounded, color: AppColors.pink, title: AppLocalizations.of(context)!.forumUpdatesLabel, subtitle: AppLocalizations.of(context)!.repliesAndMentions, value: _forumUpdates, onChanged: (v) { setState(() => _forumUpdates = v); _savePreference('notif_forum', v); }),
          _buildToggleTile(icon: Icons.emergency_rounded, color: AppColors.error, title: AppLocalizations.of(context)!.emergencyAlertsLabel, subtitle: AppLocalizations.of(context)!.criticalEmergencyNotifications, value: _emergencyAlerts, onChanged: (v) { setState(() => _emergencyAlerts = v); _savePreference('notif_emergency', v); }),
          _buildToggleTile(icon: Icons.campaign_rounded, color: AppColors.textTertiaryOf(context), title: AppLocalizations.of(context)!.marketingEmailsLabel, subtitle: AppLocalizations.of(context)!.productUpdatesAndHealthTips, value: _marketingEmails, onChanged: (v) { setState(() => _marketingEmails = v); _savePreference('notif_marketing', v); }),
        ],
      ),
    );
  }

  Widget _buildToggleTile({required IconData icon, required Color color, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    final textColor = AppColors.textPrimaryOf(context);
    final secondaryColor = AppColors.textSecondaryOf(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: secondaryColor)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ),
    );
  }
}
