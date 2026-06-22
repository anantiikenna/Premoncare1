import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';

final patientDetailsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, patientId) async {
  final data = await supabase
      .from('profiles')
      .select('full_name, avatar_url, phone')
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

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          patientAsync.when(
            data: (patient) => _buildPatientHeader(context, patient),
            loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
            error: (_, _) => const SizedBox(height: 100, child: Center(child: Text('Could not load patient'))),
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
    return AppBar(
      backgroundColor: AppColors.surfaceOf(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context)),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Patient Details',
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.message_rounded, color: AppColors.success),
                title: const Text('Send Message', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/chat/${widget.patientId}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_rounded, color: AppColors.error),
                title: const Text('Block Patient', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block Patient'),
        content: const Text('Are you sure you want to block this patient? They won\'t be able to book consultations with you.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
                    const SnackBar(content: Text('Patient blocked')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to block: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Block', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientHeader(BuildContext context, Map<String, dynamic>? patient) {
    final name = patient?['full_name'] as String? ?? 'Patient';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

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
                Text('Patient ID: ${widget.patientId.substring(0, 8)}...', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
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
        tabs: const [
          Tab(text: 'OVERVIEW'),
          Tab(text: 'CONSULTATIONS'),
          Tab(text: 'RECORDS'),
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
            loading: () => const _SectionCard(title: 'Appointment Summary', child: SizedBox(height: 40, child: Center(child: CircularProgressIndicator()))),
            error: (_, _) => const _SectionCard(title: 'Appointment Summary', child: Text('Could not load data')),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentSummary(BuildContext context, int total, int completed, int pending) {
    return _SectionCard(
      title: 'Appointment Summary',
      child: Column(
        children: [
          _buildSummaryRow(context, 'Total Appointments', total.toString()),
          const SizedBox(height: 12),
          _buildSummaryRow(context, 'Completed', completed.toString()),
          const SizedBox(height: 12),
          _buildSummaryRow(context, 'Pending', pending.toString()),
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

    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_rounded, size: 48, color: AppColors.textTertiaryOf(context)),
                const SizedBox(height: 16),
                Text('No consultations yet', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 16, fontWeight: FontWeight.w600)),
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
      error: (_, _) => const Center(child: Text('Could not load consultations')),
    );
  }

  Widget _buildAppointmentItem(BuildContext context, Map<String, dynamic> appt) {
    final date = appt['appointment_date'] != null ? DateTime.parse(appt['appointment_date']) : null;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = date != null ? months[date.month - 1] : '';
    final dayStr = date != null ? date.day.toString() : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Row(
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
                Text(appt['consultation_mode']?.toString().toUpperCase() ?? 'Consultation', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimaryOf(context))),
                const SizedBox(height: 2),
                Text('${appt['duration_minutes'] ?? 30} min', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11, fontWeight: FontWeight.w600)),
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
    );
  }
}

class _RecordsTab extends ConsumerWidget {
  final String patientId;
  const _RecordsTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(patientRecordsForDoctorProvider(patientId));

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_rounded, size: 48, color: AppColors.textTertiaryOf(context)),
                const SizedBox(height: 16),
                Text('No shared records', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Records shared by the patient will appear here.', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 13)),
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
      error: (_, _) => const Center(child: Text('Could not load records')),
    );
  }

  Widget _buildRecordItem(BuildContext context, Map<String, dynamic> record) {
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
                Text(record['title'] ?? 'Record', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimaryOf(context))),
                const SizedBox(height: 2),
                Text(record['record_type'] ?? 'Other', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_rounded, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening record...')),
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
