import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import 'records_provider.dart';
import 'upload_record_sheet.dart';


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
          Text(AppLocalizations.of(context)!.secureMedicalStorageTitle, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.medicalVault, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0)),
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
          Text(AppLocalizations.of(context)!.yourVaultIsEmptyTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(AppLocalizations.of(context)!.securelyStoreManageDesc, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondaryOf(context), height: 1.5, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 48),
          _buildActionButton(context, AppLocalizations.of(context)!.uploadHealthRecordButton, Icons.cloud_upload_rounded, AppColors.primary, isPrimary: true, onTap: () => _showUpload(context)),
          const SizedBox(height: 16),
          _buildActionButton(context, AppLocalizations.of(context)!.scheduleConsultationButton, Icons.calendar_today_rounded, AppColors.primary, isPrimary: false, onTap: () => context.push('/doctor-search')),
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
          foregroundColor: isPrimary ? AppColors.textInverse : primaryColor,
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
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.surfaceOf(context).withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.textInverse.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.lock_person_rounded, color: AppColors.textInverse, size: 28)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.endToEndEncryptionTitle, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textInverse)),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context)!.clinicalDataConfidentialDesc, style: TextStyle(fontSize: 12, color: AppColors.textInverse.withValues(alpha: 0.6), height: 1.4, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(BuildContext context, List<MedicalRecord> records) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: records.length,
      itemBuilder: (context, index) => _buildRecordTile(context, records[index]),
    );
  }

  Widget _buildRecordTile(BuildContext context, MedicalRecord record) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[record.createdAt.month - 1]} ${record.createdAt.day}, ${record.createdAt.year}';
    final typeIcon = record.recordType == RecordType.labResult
        ? Icons.science_rounded
        : record.recordType == RecordType.prescription
            ? Icons.medication_rounded
            : record.recordType == RecordType.imaging
                ? Icons.image_rounded
                : record.recordType == RecordType.immunization
                    ? Icons.vaccines_rounded
                    : record.recordType == RecordType.clinicalNote
                        ? Icons.note_alt_rounded
                        : Icons.description_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showRecordOptions(context, record),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderLightOf(context))),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)), child: Icon(typeIcon, color: AppColors.primary, size: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimaryOf(context))),
                    const SizedBox(height: 4),
                    Text('Uploaded $dateStr', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryOf(context)),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordOptions(BuildContext context, MedicalRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderOf(context), borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 24),
            Text(record.title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimaryOf(context))),
            const SizedBox(height: 4),
            Text(record.recordType.name, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13)),
            const SizedBox(height: 24),
            _optionTile(ctx, Icons.visibility_rounded, AppLocalizations.of(context)!.viewRecordButton, () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening ${record.title}...')),
              );
            }),
            _optionTile(ctx, Icons.share_rounded, AppLocalizations.of(context)!.shareWithDoctorOption, () {
              Navigator.pop(ctx);
              context.push('/doctor-search?shareRecord=${record.id}');
            }),
            _optionTile(ctx, Icons.delete_outline_rounded, AppLocalizations.of(context)!.deleteRecord, () {
              Navigator.pop(ctx);
              _confirmDelete(context, record);
            }, isDestructive: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MedicalRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(AppLocalizations.of(context)!.deleteRecord),
        content: Text(AppLocalizations.of(context)!.deleteRecordConfirmation(record.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancelLabel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await RecordsService.deleteRecord(record);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${record.title} deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.deleteLabel),
          ),
        ],
      ),
    );
  }

  Widget _optionTile(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary),
      title: Text(label, style: TextStyle(color: isDestructive ? AppColors.error : AppColors.textPrimaryOf(context), fontWeight: FontWeight.w700)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryOf(context)),
      onTap: onTap,
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
