import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../patient/patient_providers.dart';
import 'records_provider.dart';

class RecordSharingSheet extends ConsumerWidget {
  final MedicalRecord record;
  const RecordSharingSheet({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(availableDoctorsProvider);

    return AlertDialog(
      title: const Text('Manage Sharing Access'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Only authorized doctors can view and decrypt this record.',
              style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
            ),
            const SizedBox(height: 20),
            doctorsAsync.when(
              data: (doctors) {
                if (doctors.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No verified doctors found.')),
                  );
                }
                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final doc = doctors[index];
                      final isAuthorized = record.authorizedDoctors.contains(doc['id']);
                      
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(doc['full_name']?[0] ?? 'D'),
                        ),
                        title: Text(doc['full_name'] ?? 'Unknown Doctor'),
                        subtitle: Text(doc['specialty'] ?? 'Healthcare Provider'),
                        trailing: Switch(
                          value: isAuthorized,
                          activeThumbColor: AppColors.success,
                          onChanged: (val) async {
                            try {
                              await RecordsService.toggleAuthorization(record.id, doc['id'], val);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update access: $e')),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
