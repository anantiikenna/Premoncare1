import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import 'records_provider.dart';
import 'upload_record_sheet.dart';
import 'dart:math' as math;

class MedicalVaultScreen extends ConsumerWidget {
  const MedicalVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(patientRecordsProvider);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildHeader(context),
                const SizedBox(height: 32),
                Expanded(
                  child: recordsAsync.when(
                    data: (records) {
                      if (records.isEmpty) {
                        return _buildEmptyState(context);
                      }
                      return _buildRecordsList(context, records);
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SECURE MEDICAL STORAGE', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Medical Vault', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0)),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.success.withValues(alpha: 0.2))),
                child: const Icon(Icons.shield_rounded, color: AppColors.success, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(Icons.folder_shared_rounded, size: 80, color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 40),
          Text('Your vault is empty', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text('Securely store and manage your clinical reports, prescriptions, and medical history in one encrypted location.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondaryOf(context), height: 1.5, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 48),
          _buildActionButton(context, 'Upload Health Record', Icons.cloud_upload_rounded, AppColors.primary, isPrimary: true, onTap: () => _showUpload(context)),
          const SizedBox(height: 16),
          _buildActionButton(context, 'Schedule Consultation', Icons.calendar_today_rounded, AppColors.primary, isPrimary: false, onTap: () => context.push('/doctor-search')),
          const SizedBox(height: 48),
          _buildSecurityCard(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color primaryColor, {required bool isPrimary, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? primaryColor : AppColors.surfaceOf(context),
          foregroundColor: isPrimary ? Colors.white : primaryColor,
          elevation: isPrimary ? 10 : 0,
          shadowColor: isPrimary ? primaryColor.withValues(alpha: 0.3) : Colors.transparent,
          side: isPrimary ? BorderSide.none : BorderSide(color: primaryColor.withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.slate800, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: AppColors.slate800.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.lock_person_rounded, color: Colors.white, size: 28)),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('End-to-End Encryption', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                SizedBox(height: 4),
                Text('Your clinical data is strictly confidential and accessible only by you and your authorized specialists.', style: TextStyle(fontSize: 12, color: Colors.white60, height: 1.4, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(BuildContext context, List<dynamic> records) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: records.length,
      itemBuilder: (context, index) => _buildRecordTile(records[index]),
    );
  }

  Widget _buildRecordTile(dynamic record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderLight)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clinical Report #${math.Random().nextInt(10000)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('Uploaded Oct 24, 2023 • 2.4 MB', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
        ],
      ),
    );
  }

  void _showUpload(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UploadRecordSheet(),
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
