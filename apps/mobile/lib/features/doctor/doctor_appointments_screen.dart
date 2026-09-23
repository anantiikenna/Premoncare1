import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../l10n/app_localizations.dart';

final doctorAppointmentsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('appointments')
      .stream(primaryKey: ['id'])
      .eq('doctor_id', user.id)
      .order('appointment_date', ascending: false)
      .asyncMap((data) async {
        if (data.isEmpty) return <Map<String, dynamic>>[];

        final patientIds = data.map((e) => e['patient_id'] as String?).whereType<String>().toSet().toList();
        if (patientIds.isEmpty) return data;

        final patientsResult = await supabase
            .from('profiles')
            .select('id, full_name, avatar_url, is_profile_visible')
            .inFilter('id', patientIds);

        final patientMap = {for (final p in patientsResult) p['id'] as String: p};

        return data.map((item) {
          final patientData = patientMap[item['patient_id'] as String?] as Map<String, dynamic>?;
          final isProfileVisible = (patientData?['is_profile_visible'] as bool?) ?? true;
          final patientName = isProfileVisible
              ? (patientData?['full_name'] as String? ?? 'Guest')
              : 'Patient (Hidden)';
          return <String, dynamic>{
            ...item,
            'patient_name': patientName,
            'patient_avatar':
                isProfileVisible ? (patientData?['avatar_url'] as String?) : null,
          };
        }).toList();
      });
});

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends ConsumerState<DoctorAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _previousDay() => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
  void _nextDay() => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(top: -150, right: -100, child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.08), size: 500)),
          Positioned(bottom: -100, left: -50, child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.03), size: 300)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 32),
                Expanded(
                  child: appointmentsAsync.when(
                    data: (appointments) {
                      final today = DateTime.now();
                      final todayAppts = appointments.where((a) {
                        final d = DateTime.parse(a['appointment_date']);
                        return d.year == today.year && d.month == today.month && d.day == today.day;
                      }).toList();
                      final pending = appointments.where((a) => a['status'] == 'pending' || a['status'] == 'emergency_request').toList();

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsHeader(todayCount: todayAppts.length, pendingCount: pending.length),
                            const SizedBox(height: 32),
                            _buildSectionTitle(AppLocalizations.of(context)!.scheduleNavigation),
                            const SizedBox(height: 16),
                            _buildTabNavigation(),
                            const SizedBox(height: 32),
                            _buildDateSelector(),
                            const SizedBox(height: 24),
                            _buildTimeline(appointments),
                            const SizedBox(height: 32),
                            _buildPerformanceCard(appointments),
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: AppColors.error))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.clinicalOperations, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.appointmentsLabel, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0)),
            ],
          ),
          const Spacer(),
          _buildSearchButton(context),
        ],
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSearchDialog(context),
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderOf(context))),
        child: Icon(Icons.search_rounded, color: AppColors.textPrimaryOf(context), size: 20),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(AppLocalizations.of(context)!.searchAppointments),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchByPatientName,
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Searching for "${_searchController.text}"...')),
              );
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader({required int todayCount, required int pendingCount}) {
    return Row(
      children: [
        _buildStatCard('TODAY', '$todayCount', AppColors.primary, Icons.calendar_today_rounded),
        const SizedBox(width: 16),
        _buildStatCard('PENDING', '$pendingCount', AppColors.warning, Icons.hourglass_empty_rounded),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLightOf(context)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 20),
            Text(label, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 28, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AppColors.borderLightOf(context), borderRadius: BorderRadius.circular(20)),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.textPrimaryOf(context).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondaryOf(context),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
        tabs: [Tab(text: AppLocalizations.of(context)!.today), Tab(text: AppLocalizations.of(context)!.upcomingTab), Tab(text: AppLocalizations.of(context)!.pendingTab), Tab(text: AppLocalizations.of(context)!.past)],
      ),
    );
  }

  Widget _buildDateSelector() {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final dateStr = '${months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle(AppLocalizations.of(context)!.clinicalTimeline),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderOf(context))),
          child: Row(
            children: [
              GestureDetector(onTap: _previousDay, child: Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.textPrimaryOf(context))),
              const SizedBox(width: 12),
              Text(dateStr, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 12, fontWeight: FontWeight.w900)),
              const SizedBox(width: 12),
              GestureDetector(onTap: _nextDay, child: Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textPrimaryOf(context))),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h12:$m $period';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return AppColors.success;
      case 'confirmed': return AppColors.primary;
      case 'ongoing': return AppColors.info;
      case 'pending': return AppColors.warning;
      case 'emergency_request': return AppColors.error;
      case 'emergency_accepted': return AppColors.success;
      case 'emergency_declined': return AppColors.error;
      case 'cancelled': return AppColors.textTertiaryOf(context);
      case 'rescheduled': return AppColors.info;
      default: return AppColors.textSecondaryOf(context);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed': return 'COMPLETED';
      case 'confirmed': return 'CONFIRMED';
      case 'ongoing': return 'ONGOING';
      case 'pending': return 'PENDING';
      case 'emergency_request': return 'EMERGENCY';
      case 'emergency_accepted': return 'ACCEPTED';
      case 'emergency_declined': return 'DECLINED';
      case 'cancelled': return 'CANCELLED';
      case 'rescheduled': return 'RESCHEDULED';
      default: return status.toUpperCase();
    }
  }

  Widget _buildTimeline(List<Map<String, dynamic>> allAppointments) {
    List<Map<String, dynamic>> filtered = allAppointments.where((a) {
      final d = DateTime.parse(a['appointment_date']);
      final matchesDate = d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
      if (_tabController.index == 0) return matchesDate; // TODAY
      if (_tabController.index == 1) {
        // UPCOMING: future dates
        return d.isAfter(DateTime.now());
      }
      if (_tabController.index == 2) {
        // PENDING
        return a['status'] == 'pending' || a['status'] == 'emergency_request' || a['status'] == 'rescheduled';
      }
      if (_tabController.index == 3) {
        // PAST
        return a['status'] == 'completed' || a['status'] == 'cancelled';
      }
      return matchesDate;
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_available_rounded, size: 48, color: AppColors.textTertiaryOf(context)),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.noAppointmentsForThisDay, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Column(
        children: [
          for (int i = 0; i < filtered.length; i++)
            _buildTimelineItem(
              _formatTime(DateTime.parse(filtered[i]['appointment_date'])),
              filtered[i]['patient_name'] ?? 'Guest',
              filtered[i]['consultation_mode'] ?? 'consultation',
              filtered[i]['status'],
              _statusColor(filtered[i]['status']),
              appointmentId: filtered[i]['id'],
              isFirst: i == 0,
              isLast: i == filtered.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String time, String name, String type, String status, Color color, {String? appointmentId, bool isFirst = false, bool isLast = false}) {
    final statusLabel = _statusLabel(status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 65, child: Text(time, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11, fontWeight: FontWeight.w800))),
        Column(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.surfaceOf(context), shape: BoxShape.circle, border: Border.all(color: color, width: 3))),
            if (!isLast) Container(width: 2, height: 90, color: AppColors.borderLightOf(context)),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (appointmentId != null) {
                context.push('/appointments/$appointmentId');
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceAltOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLightOf(context))),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimaryOf(context))),
                        const SizedBox(height: 2),
                        Text(type.toUpperCase(), style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(statusLabel, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(List<Map<String, dynamic>> allAppointments) {
    final total = allAppointments.length;
    final completed = allAppointments.where((a) => a['status'] == 'completed').length;
    final pct = total > 0 ? ((completed / total) * 100).round() : 0;
    final remaining = total - completed;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: AppColors.slate800, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: AppColors.slate800.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAILY PROGRESS', style: TextStyle(color: AppColors.textInverse.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text('${pct}% Completed', style: TextStyle(color: AppColors.textInverse, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  remaining > 0 ? AppLocalizations.of(context)!.keepGoingMoreSessions(remaining) : AppLocalizations.of(context)!.allSessionsCompletedToday,
                  style: TextStyle(color: AppColors.textInverse.withValues(alpha: 0.6), fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70, height: 70,
                child: CircularProgressIndicator(
                  value: total > 0 ? completed / total : 0,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text('$pct%', style: TextStyle(color: AppColors.textInverse, fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
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
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)]),
    );
  }
}
