import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
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
      title: Text(AppLocalizations.of(context)!.manageSharingAccess),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.onlyAuthorizedDoctorsDesc,
              style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
            ),
            const SizedBox(height: 20),
            doctorsAsync.when(
              data: (doctors) {
                if (doctors.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text(AppLocalizations.of(context)!.noVerifiedDoctorsFound)),
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
                        title: Text(doc['full_name'] ?? AppLocalizations.of(context)!.unknownDoctor),
                        subtitle: Text(doc['specialty'] ?? AppLocalizations.of(context)!.healthcareProvider),
                        trailing: Switch(
                          value: isAuthorized,
                          activeThumbColor: AppColors.success,
                          onChanged: (val) async {
                            try {
                              await RecordsService.toggleAuthorization(record.id, doc['id'], val);
                            } catch (e) {
                              if (context.mounted) {
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
              error: (err, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.failedToLoadDoctorsGeneric,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(availableDoctorsProvider),
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.closeLabel),
        ),
      ],
    );
  }
}
