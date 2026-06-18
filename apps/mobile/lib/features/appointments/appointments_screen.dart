import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'appointment_provider.dart';


class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentsProvider);
    const primaryColor = Color(0xFF0F62FE);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Deep immersive mesh background
          Positioned(
            top: -150,
            left: -100,
            child: _MeshCircle(color: primaryColor.withValues(alpha: 0.08), size: 400),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: _MeshCircle(color: primaryColor.withValues(alpha: 0.03), size: 300),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildTabBar(primaryColor),
                const SizedBox(height: 24),
                Expanded(
                  child: appointmentsAsync.when(
                    data: (appointments) {
                      final upcoming = appointments.where((a) => a.status == AppointmentStatus.pending || a.status == AppointmentStatus.confirmed).toList();
                      final past = appointments.where((a) => a.status == AppointmentStatus.completed || a.status == AppointmentStatus.cancelled).toList();

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAppointmentList(context, upcoming, 'Your health schedule is clear', isPast: false, primaryColor: primaryColor),
                          _buildAppointmentList(context, past, 'No past history found', isPast: true, primaryColor: primaryColor),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3)),
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
          const Text('CLINICAL SESSIONS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Appointments', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1.0)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
    );
  }

  Widget _buildTabBar(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(18)),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))]),
          labelColor: primaryColor,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past Sessions')],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(BuildContext context, List<Appointment> appointments, String emptyTitle, {required bool isPast, required Color primaryColor}) {
    if (appointments.isEmpty) {
      return _buildEmptyState(context, emptyTitle, isPast: isPast, primaryColor: primaryColor);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(context, appointment, primaryColor);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, {required bool isPast, required Color primaryColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(isPast ? Icons.history_rounded : Icons.event_note_rounded, size: 64, color: primaryColor.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 32),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1)),
          const SizedBox(height: 12),
          Text(
            isPast ? 'Your completed clinical records and summaries will appear here.' : 'Schedule a consultation with our verified specialists to begin your care journey.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w500),
          ),
          if (!isPast) ...[
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.push('/doctor-search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 10,
                  shadowColor: primaryColor.withValues(alpha: 0.3),
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

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment, Color primaryColor) {
    final bool isUpcoming = appointment.status == AppointmentStatus.pending || appointment.status == AppointmentStatus.confirmed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                child: Text(
                  appointment.doctorName.isNotEmpty ? appointment.doctorName[0].toUpperCase() : 'D',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0F62FE)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. ${appointment.doctorName}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    const Text('Verified Specialist', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _buildStatusBadge(appointment.status),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF1F5F9))),
            child: Row(
              children: [
                _buildInfoItem(Icons.calendar_today_rounded, '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}'),
                const Spacer(),
                Container(width: 1, height: 16, color: const Color(0xFFE2E8F0)),
                const Spacer(),
                _buildInfoItem(Icons.access_time_rounded, _getTime(appointment.appointmentDate)),
              ],
            ),
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/appointments/${appointment.id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Reschedule', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/appointments/${appointment.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Join Call', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AppointmentStatus status) {
    Color color;
    String label;

    switch (status) {
      case AppointmentStatus.confirmed:
        color = const Color(0xFF10B981);
        label = 'CONFIRMED';
        break;
      case AppointmentStatus.pending:
        color = const Color(0xFFF59E0B);
        label = 'PENDING';
        break;
      case AppointmentStatus.completed:
        color = const Color(0xFF64748B);
        label = 'COMPLETED';
        break;
      case AppointmentStatus.cancelled:
        color = const Color(0xFFEF4444);
        label = 'CANCELLED';
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
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
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

