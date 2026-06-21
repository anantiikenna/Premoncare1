import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import 'records_provider.dart';

class DoctorSharedRecordsScreen extends ConsumerWidget {
  const DoctorSharedRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(authorizedRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Patient Records'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: recordsAsync.when(
          data: (records) {
            if (records.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 60, color: AppColors.textTertiaryOf(context)),
                      const SizedBox(height: 16),
                      const Text(
                        'No Shared Records',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Patients must explicitly share their vault documents with you for them to appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondaryOf(context)),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SharedRecordCard(record: record),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _SharedRecordCard extends StatelessWidget {
  final MedicalRecord record;
  const _SharedRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.file_present, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      'TYPE: ${record.recordType.name.split('_').join(' ').toUpperCase()}',
                      style: TextStyle(fontSize: 10, color: AppColors.textTertiaryOf(context), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shared on ${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiaryOf(context)),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push('/document-viewer', extra: {
                  'bucket': 'patient-medical-vault',
                  'path': record.documentUrl,
                  'title': record.title,
                }),
                icon: const Icon(Icons.visibility),
                label: const Text('View Record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
