import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../l10n/app_localizations.dart';

final patientDetailsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, patientId) async {
  final data = await supabase
      .from('profiles')
      .select('full_name, avatar_url, phone, is_profile_visible')
      .eq('id', patientId)
      .single();
  return data;
});

final patientAppointmentsHistoryProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, patientId) async {
  final doctor = supabase.auth.currentUser;
  if (doctor == null) return [];
  final data = await supabase
      .from('appointments')
      .select('id, appointment_date, status, consultation_mode, duration_minutes, total_amount')
      .eq('patient_id', patientId)
      .eq('doctor_id', doctor.id)
      .order('appointment_date', ascending: false);
  return data;
});

final patientRecordsForDoctorProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, patientId) async {
  final doctor = supabase.auth.currentUser;
  if (doctor == null) return [];
  final data = await supabase
      .from('medical_records')
      .select('id, title, record_type, created_at')
      .eq('patient_id', patientId)
      .order('created_at', ascending: false);
  return data;
});

class PatientDetailsLayout extends ConsumerStatefulWidget {
  final String patientId;
  const PatientDetailsLayout({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailsLayout> createState() => _PatientDetailsLayoutState();
}

class _PatientDetailsLayoutState extends ConsumerState<PatientDetailsLayout> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientAsync = ref.watch(patientDetailsProvider(widget.patientId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          patientAsync.when(
            data: (patient) => _buildPatientHeader(context, patient),
            loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
            error: (_, _) => SizedBox(height: 100, child: Center(child: Text(l10n.couldNotLoadPatient))),
          ),
          const SizedBox(height: 20),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(patientId: widget.patientId),
                _ConsultationsTab(patientId: widget.patientId),
                _RecordsTab(patientId: widget.patientId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: AppColors.surfaceOf(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context)),
        onPressed: () => context.pop(),
      ),
      title: Text(
        l10n.patientDetailsLabel,
        style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.w900, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert_rounded, color: AppColors.textPrimaryOf(context)),
          onPressed: () => _showPatientMenu(context),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Divider(height: 1.0, color: AppColors.borderLightOf(context)),
      ),
    );
  }

  void _showPatientMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderOf(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.message_rounded, color: AppColors.success),
                title: Text(l10n.sendMessageLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/chat/${widget.patientId}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_rounded, color: AppColors.error),
                title: Text(l10n.blockPatientLabel, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmBlockPatient(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmBlockPatient(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.blockPatientLabel),
        content: Text(l10n.areYouSureBlockPatient),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancelLabel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await supabase.from('blocked_users').insert({
                  'blocker_id': supabase.auth.currentUser?.id,
                  'blocked_id': widget.patientId,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.patientBlocked)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToBlock(e.toString())), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text(l10n.blockLabel, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientHeader(BuildContext context, Map<String, dynamic>? patient) {
    final l10n = AppLocalizations.of(context)!;
    final isProfileVisible = patient?['is_profile_visible'] ?? true;
    final name = isProfileVisible ? (patient?['full_name'] as String? ?? l10n.patientLabel) : l10n.patientHiddenLabel;
    final initial = isProfileVisible && name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      color: AppColors.surfaceOf(context),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Text(initial, style: TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.w900, fontSize: 32)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(
                  isProfileVisible ? l10n.patientIdLabel(widget.patientId.substring(0, 8)) : l10n.privacyProtected,
                  style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.surfaceOf(context),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textTertiaryOf(context),
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: [
          Tab(text: l10n.overviewTab),
          Tab(text: l10n.consultationsTab),
          Tab(text: l10n.recordsTab),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final String patientId;
  const _OverviewTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(patientAppointmentsHistoryProvider(patientId));
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          appointmentsAsync.when(
            data: (appointments) {
              final completed = appointments.where((a) => a['status'] == 'completed').length;
              final pending = appointments.where((a) => a['status'] == 'pending').length;
              final total = appointments.length;
              return _buildAppointmentSummary(context, total, completed, pending);
            },
            loading: () => _SectionCard(title: l10n.appointmentSummary, child: const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()))),
            error: (_, _) => _SectionCard(title: l10n.appointmentSummary, child: Text(l10n.couldNotLoadData)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentSummary(BuildContext context, int total, int completed, int pending) {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      title: l10n.appointmentSummary,
      child: Column(
        children: [
          _buildSummaryRow(context, l10n.totalAppointments, total.toString()),
          const SizedBox(height: 12),
          _buildSummaryRow(context, l10n.completedStatusLabel, completed.toString()),
          const SizedBox(height: 12),
          _buildSummaryRow(context, l10n.pendingStatusLabel, pending.toString()),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimaryOf(context))),
      ],
    );
  }
}

class _ConsultationsTab extends ConsumerWidget {
  final String patientId;
  const _ConsultationsTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(patientAppointmentsHistoryProvider(patientId));
    final l10n = AppLocalizations.of(context)!;

    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_rounded, size: 48, color: AppColors.textTertiaryOf(context)),
                const SizedBox(height: 16),
                Text(l10n.noConsultationsYet, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: appointments.length,
          itemBuilder: (context, index) => _buildAppointmentItem(context, appointments[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.couldNotLoadConsultations)),
    );
  }

  Widget _buildAppointmentItem(BuildContext context, Map<String, dynamic> appt) {
    final l10n = AppLocalizations.of(context)!;
    final date = appt['appointment_date'] != null ? DateTime.parse(appt['appointment_date']) : null;
    final months = [l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr, l10n.monthMay, l10n.monthJun, l10n.monthJul, l10n.monthAug, l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec];
    final monthStr = date != null ? months[date.month - 1] : '';
    final dayStr = date != null ? date.day.toString() : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Column(
        children: [
          Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text(monthStr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary)),
                Text(dayStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appt['consultation_mode']?.toString().toUpperCase() ?? l10n.consultationFallback, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimaryOf(context))),
                const SizedBox(height: 2),
                Text('${appt['duration_minutes'] ?? 30} ${l10n.durationMinUnit}', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: appt['status'] == 'completed'
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              (appt['status'] as String?)?.toUpperCase() ?? '',
              style: TextStyle(
                color: appt['status'] == 'completed' ? AppColors.success : AppColors.warning,
                fontSize: 9, fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
          ),
          if (_canJoinVideo(appt)) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _joinVideoCall(context, appt),
                icon: const Icon(Icons.videocam_rounded, size: 18),
                label: Text(l10n.joinClinicalSessionButton, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _canJoinVideo(Map<String, dynamic> appt) {
    final status = appt['status'] as String?;
    final mode = appt['consultation_mode'] as String?;
    if (mode != 'video') return false;
    return status == 'confirmed' || status == 'rescheduled' || status == 'ongoing' || status == 'emergency_accepted';
  }

  Future<void> _joinVideoCall(BuildContext context, Map<String, dynamic> appt) async {
    final apptId = appt['id'] as String?;
    if (apptId == null) return;
    String patientLabel = 'Patient';
    try {
      final profile = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', patientId)
          .maybeSingle();
      final name = profile?['full_name'] as String?;
      if (name != null && name.trim().isNotEmpty) patientLabel = name.trim();
    } catch (_) {}
    if (!context.mounted) return;
    context.push('/consultation/$apptId', extra: {
      'doctorName': patientLabel,
      'specialty': null,
      'durationMinutes': appt['duration_minutes'] as int?,
    });
  }
}

class _RecordsTab extends ConsumerWidget {
  final String patientId;
  const _RecordsTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(patientRecordsForDoctorProvider(patientId));
    final l10n = AppLocalizations.of(context)!;

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_rounded, size: 48, color: AppColors.textTertiaryOf(context)),
                const SizedBox(height: 16),
                Text(l10n.noSharedRecords, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(l10n.recordsSharedWillAppearHere, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: records.length,
          itemBuilder: (context, index) => _buildRecordItem(context, records[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.couldNotLoadRecords)),
    );
  }

  Widget _buildRecordItem(BuildContext context, Map<String, dynamic> record) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: AppColors.textSecondaryOf(context), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record['title'] ?? l10n.recordLabel, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimaryOf(context))),
                const SizedBox(height: 2),
                Text(record['record_type'] ?? l10n.otherLabel, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_rounded, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.openingRecord)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
