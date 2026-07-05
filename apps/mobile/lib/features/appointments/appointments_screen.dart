import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import 'appointment_provider.dart';


class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            left: -100,
            child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.08), size: 400),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.03), size: 300),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildTabBar(),
                const SizedBox(height: 24),
                Expanded(
                  child: appointmentsAsync.when(
                    data: (appointments) {
                      final upcoming = appointments.where((a) => a.status == AppointmentStatus.pending || a.status == AppointmentStatus.confirmed).toList();
                      final past = appointments.where((a) => a.status == AppointmentStatus.completed || a.status == AppointmentStatus.cancelled).toList();

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAppointmentList(context, upcoming, 'Your health schedule is clear', isPast: false),
                          _buildAppointmentList(context, past, 'No past history found', isPast: true),
                        ],
                      );
                    },
                    loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CLINICAL SESSIONS', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Appointments', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0)),
              _buildHeaderAction(Icons.calendar_today_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderOf(context))),
      child: Icon(icon, color: AppColors.textPrimaryOf(context), size: 20),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: AppColors.borderLightOf(context), borderRadius: BorderRadius.circular(18)),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 2))]),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryOf(context),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Completed')],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(BuildContext context, List<Appointment> appointments, String emptyTitle, {required bool isPast}) {
    if (appointments.isEmpty) {
      return _buildEmptyState(context, emptyTitle, isPast: isPast);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(context, appointment);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, {required bool isPast}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(isPast ? Icons.history_rounded : Icons.event_note_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 32),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1)),
          const SizedBox(height: 12),
          Text(
            isPast ? 'Your completed clinical records and summaries will appear here.' : 'Schedule a consultation with our verified specialists to begin your care journey.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondaryOf(context), height: 1.5, fontWeight: FontWeight.w500),
          ),
          if (!isPast) ...[
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.push('/doctor-search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  elevation: 10,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment) {
    final bool isUpcoming = appointment.status == AppointmentStatus.pending || appointment.status == AppointmentStatus.confirmed;
    final bool isConfirmed = appointment.status == AppointmentStatus.confirmed;
    final now = DateTime.now().toUtc();
    final appointmentTime = appointment.appointmentDate.toUtc();
    final isPast = appointmentTime.isBefore(now);
    final isJoinable = isConfirmed && appointmentTime.isBefore(now.add(const Duration(minutes: 30)));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderLightOf(context)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  appointment.doctorName.isNotEmpty ? appointment.doctorName[0].toUpperCase() : 'D',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. ${appointment.doctorName}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.textPrimaryOf(context))),
                    const SizedBox(height: 4),
                    Text('Verified Specialist', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _buildStatusBadge(appointment.status),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceAltOf(context), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderLightOf(context))),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildInfoItem(Icons.calendar_today_rounded, '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}'),
                    const Spacer(),
                    Container(width: 1, height: 16, color: AppColors.borderOf(context)),
                    const Spacer(),
                    _buildInfoItem(Icons.access_time_rounded, _getTime(appointment.appointmentDate)),
                    const Spacer(),
                    Container(width: 1, height: 16, color: AppColors.borderOf(context)),
                    const Spacer(),
                    _buildInfoItem(Icons.videocam_rounded, '${appointment.durationMinutes} mins'),
                  ],
                ),
                if (isUpcoming && !isPast) ...[
                  const SizedBox(height: 12),
                  _buildCountdown(appointment.appointmentDate),
                ],
              ],
            ),
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/appointments/${appointment.id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondaryOf(context),
                      side: BorderSide(color: AppColors.borderOf(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Reschedule', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isJoinable ? () => context.push('/appointments/${appointment.id}') : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textInverse,
                      disabledBackgroundColor: AppColors.textTertiaryOf(context).withValues(alpha: 0.3),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Join Consultation', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
          if (appointment.status == AppointmentStatus.completed) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/appointments/${appointment.id}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('View Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdown(DateTime appointmentTime) {
    final now = DateTime.now().toUtc();
    final diff = appointmentTime.difference(now);
    if (diff.isNegative) return const SizedBox.shrink();

    final hours = diff.inHours;
    final mins = diff.inMinutes.remainder(60);
    final secs = diff.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Starts in ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondaryOf(context))),
          Text(
            '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AppointmentStatus status) {
    Color color;
    String label;

    switch (status) {
      case AppointmentStatus.confirmed:
        color = AppColors.success;
        label = 'CONFIRMED';
        break;
      case AppointmentStatus.pending:
        color = AppColors.warning;
        label = 'SCHEDULED';
        break;
      case AppointmentStatus.completed:
        color = AppColors.slate500;
        label = 'COMPLETED';
        break;
      case AppointmentStatus.cancelled:
        color = AppColors.error;
        label = 'CANCELLED';
        break;
      case AppointmentStatus.ongoing:
        color = AppColors.info;
        label = 'ONGOING';
        break;
      case AppointmentStatus.emergency_request:
        color = AppColors.error;
        label = 'EMERGENCY';
        break;
      case AppointmentStatus.emergency_accepted:
        color = AppColors.success;
        label = 'ACCEPTED';
        break;
      case AppointmentStatus.emergency_declined:
        color = AppColors.error;
        label = 'DECLINED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiaryOf(context)),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimaryOf(context))),
      ],
    );
  }

  String _getTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final p = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
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
