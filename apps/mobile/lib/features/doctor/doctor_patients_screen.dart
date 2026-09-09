import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/supabase_locator.dart';
import '../../shared/widgets/generic_user_avatar.dart';
import '../../l10n/app_localizations.dart';

final doctorPatientsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final doctor = supabase.auth.currentUser;
  if (doctor == null) return [];

  // 1. Get all appointments for this doctor to find unique patients
  final appointmentsData = await supabase
      .from('appointments')
      .select('patient_id')
      .eq('doctor_id', doctor.id);

  if (appointmentsData.isEmpty) return [];

  // 2. Extract unique patient IDs, filtering out nulls (e.g. from guest bookings)
  final patientIds = (appointmentsData as List)
      .where((a) => a['patient_id'] != null)
      .map((a) => a['patient_id'] as String)
      .toSet()
      .toList();

  if (patientIds.isEmpty) return [];

  // 3. Fetch patient profiles
  final profilesData = await supabase
      .from('profiles')
      .select('id, full_name, avatar_url, phone, is_profile_visible')
      .inFilter('id', patientIds);

  return List<Map<String, dynamic>>.from(profilesData);
});

class DoctorPatientsScreen extends ConsumerStatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  ConsumerState<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends ConsumerState<DoctorPatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterPatients(List<Map<String, dynamic>> patients) {
    if (_searchQuery.isEmpty) return patients;
    
    return patients.where((patient) {
      final isProfileVisible = patient['is_profile_visible'] ?? true;
      if (!isProfileVisible) return false;
      final name = (patient['full_name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(doctorPatientsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                AppLocalizations.of(context)!.myPatients,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderOf(context)),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiaryOf(context), size: 20),
                    hintText: AppLocalizations.of(context)!.searchPatients,
                    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiaryOf(context)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            Expanded(
              child: patientsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(AppLocalizations.of(context)!.failedToLoadPatients, style: AppTypography.bodyLarge),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(doctorPatientsProvider),
                        child: const Text\(AppLocalizations.of(context)!.retryLabel\),
                      ),
                    ],
                  ),
                ),
                data: (patients) {
                  final filtered = _filterPatients(patients);

                  if (patients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_off_rounded, color: AppColors.textTertiaryOf(context), size: 56),
                          const SizedBox(height: 16),
                          Text(AppLocalizations.of(context)!.noPatientsYet, style: AppTypography.h4),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.patientsWhoBookWillAppear,
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, color: AppColors.textTertiaryOf(context), size: 56),
                          const SizedBox(height: 16),
                          Text('No matches found', style: AppTypography.h4),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final patient = filtered[index];
                      final isProfileVisible = patient['is_profile_visible'] ?? true;
                      final name = isProfileVisible ? (patient['full_name'] as String? ?? 'Patient') : 'Patient (Hidden)';
                      final phone = isProfileVisible ? (patient['phone'] as String?) : null;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderOf(context)),
                          boxShadow: [
                            BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          onTap: () => context.push('/doctor/patient/${patient['id']}'),
                          leading: GenericUserAvatar(
                            radius: 24,
                            avatarUrl: isProfileVisible ? (patient['avatar_url'] as String?) : null,
                          ),
                          title: Text(
                            name,
                            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                          ),
                          subtitle: phone != null && phone.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(phone, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryOf(context))),
                                )
                              : null,
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
