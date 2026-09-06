import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/supabase_locator.dart';

class DownloadDataScreen extends StatefulWidget {
  const DownloadDataScreen({super.key});

  @override
  State<DownloadDataScreen> createState() => _DownloadDataScreenState();
}

class _DownloadDataScreenState extends State<DownloadDataScreen> {
  bool _loading = false;
  bool _requested = false;

  Future<void> _requestExport() async {
    setState(() => _loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // GDPR: Right to Data Portability — call export_user_data RPC
      final data = await supabase.rpc('export_user_data', params: {
        'p_user_id': user.id,
      });

      if (data == null || data is Map && data.containsKey('error')) {
        throw Exception(data?['error'] ?? 'Export failed');
      }

      // Copy JSON to clipboard as a simple export mechanism
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      await Clipboard.setData(ClipboardData(text: jsonStr));

      if (!mounted) return;
      setState(() {
        _loading = false;
        _requested = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        title: Text('Download My Data', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_requested) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.successLightOf(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
                  const SizedBox(height: 12),
                  Text('Data Exported', style: AppTypography.h4Of(context)),
                  const SizedBox(height: 8),
                  Text(
                    'Your data has been copied to the clipboard as JSON. You can paste it into a secure document.',
                    style: AppTypography.bodySmallOf(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _requestExport(),
                    child: const Text('Export Again'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.infoLightOf(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.download_rounded, color: AppColors.info, size: 48),
                  const SizedBox(height: 12),
                  Text('Export Your Data', style: AppTypography.h4Of(context)),
                  const SizedBox(height: 8),
                  Text(
                    'Get a copy of all your health data, consultation history, and account information.',
                    style: AppTypography.bodySmallOf(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('WHAT\'S INCLUDED', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
            const SizedBox(height: 12),
            _buildIncludedItem(Icons.person_rounded, 'Personal Information'),
            _buildIncludedItem(Icons.medical_services_rounded, 'Medical Records'),
            _buildIncludedItem(Icons.calendar_today_rounded, 'Appointment History'),
            _buildIncludedItem(Icons.chat_rounded, 'Messages & Consultations'),
            _buildIncludedItem(Icons.receipt_rounded, 'Payment History'),
            _buildIncludedItem(Icons.forum_rounded, 'Forum Posts & Replies'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _requestExport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 2))
                    : const Text('Export My Data', style: TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncludedItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimaryOf(context))),
        ],
      ),
    );
  }
}
