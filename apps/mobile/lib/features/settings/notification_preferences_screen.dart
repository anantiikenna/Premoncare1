import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';

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
        title: Text('Notification Preferences', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('CHANNELS', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildToggleTile(icon: Icons.notifications_active_rounded, color: AppColors.primary, title: 'Push Notifications', subtitle: 'Receive alerts on your device', value: _pushEnabled, onChanged: (v) => setState(() => _pushEnabled = v)),
          _buildToggleTile(icon: Icons.email_outlined, color: AppColors.warning, title: 'Email Notifications', subtitle: 'Receive alerts via email', value: _emailEnabled, onChanged: (v) => setState(() => _emailEnabled = v)),
          const SizedBox(height: 24),
          Text('CATEGORIES', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildToggleTile(icon: Icons.calendar_today_rounded, color: AppColors.success, title: 'Appointment Alerts', subtitle: 'Reminders for upcoming consultations', value: _appointmentAlerts, onChanged: (v) => setState(() => _appointmentAlerts = v)),
          _buildToggleTile(icon: Icons.payment_rounded, color: AppColors.info, title: 'Payment Alerts', subtitle: 'Transaction confirmations and receipts', value: _paymentAlerts, onChanged: (v) => setState(() => _paymentAlerts = v)),
          _buildToggleTile(icon: Icons.medical_services_rounded, color: const Color(0xFF8B5CF6), title: 'Clinical Updates', subtitle: 'Prescription updates and health records', value: _clinicalAlerts, onChanged: (v) => setState(() => _clinicalAlerts = v)),
          _buildToggleTile(icon: Icons.forum_rounded, color: const Color(0xFFEC4899), title: 'Forum Updates', subtitle: 'Replies and mentions in the community', value: _forumUpdates, onChanged: (v) => setState(() => _forumUpdates = v)),
          _buildToggleTile(icon: Icons.emergency_rounded, color: AppColors.error, title: 'Emergency Alerts', subtitle: 'Critical emergency notifications', value: _emergencyAlerts, onChanged: (v) => setState(() => _emergencyAlerts = v)),
          _buildToggleTile(icon: Icons.campaign_rounded, color: AppColors.textTertiaryOf(context), title: 'Marketing Emails', subtitle: 'Product updates and health tips', value: _marketingEmails, onChanged: (v) => setState(() => _marketingEmails = v)),
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
