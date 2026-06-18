import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'appointment_provider.dart';
import 'dart:math' as math;


class AppointmentDetailScreen extends ConsumerWidget {
  final String appointmentId;
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);
    const primaryColor = Color(0xFF0F62FE);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Immersive mesh background
          Positioned(
            top: -150,
            right: -100,
            child: _MeshCircle(color: primaryColor.withValues(alpha: 0.08), size: 500),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _MeshCircle(color: primaryColor.withValues(alpha: 0.03), size: 300),
          ),

          SafeArea(
            child: appointmentsAsync.when(
              data: (appointments) {
                final appointment = appointments.firstWhere(
                  (a) => a.id == appointmentId,
                  orElse: () => throw Exception('Appointment not found'),
                );

                return Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _HeaderSection(appointment: appointment, primaryColor: primaryColor),
                            const SizedBox(height: 32),
                            _buildSectionTitle('SESSION ARCHITECTURE'),
                            const SizedBox(height: 16),
                            _InfoSection(appointment: appointment, primaryColor: primaryColor),
                            const SizedBox(height: 32),
                            _buildSectionTitle('CLINICAL ACTIONS'),
                            const SizedBox(height: 16),
                            if (appointment.status == AppointmentStatus.confirmed && appointment.mode == ConsultationMode.video) _VideoCallAction(appointment: appointment, primaryColor: primaryColor),
                            const SizedBox(height: 16),
                            if (appointment.status == AppointmentStatus.pending || appointment.status == AppointmentStatus.confirmed) _CancelAction(appointmentId: appointment.id),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3)),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))), child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 20)),
          ),
          const Text('Session Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(Icons.download_rounded),
                        title: const Text('Download Summary'),
                        onTap: () => Navigator.pop(ctx),
                      ),
                      ListTile(
                        leading: const Icon(Icons.share_rounded),
                        title: const Text('Share Details'),
                        onTap: () => Navigator.pop(ctx),
                      ),
                      ListTile(
                        leading: const Icon(Icons.flag_rounded, color: Color(0xFFEF4444)),
                        title: const Text('Report Issue', style: TextStyle(color: Color(0xFFEF4444))),
                        onTap: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))), child: const Icon(Icons.more_horiz_rounded, color: Color(0xFF1E293B), size: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }
}

class _HeaderSection extends StatelessWidget {
  final Appointment appointment;
  final Color primaryColor;
  const _HeaderSection({required this.appointment, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: CircleAvatar(radius: 50, backgroundColor: primaryColor.withValues(alpha: 0.15), child: Text(appointment.doctorName.isNotEmpty ? appointment.doctorName[0].toUpperCase() : 'D', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF0F62FE))))),
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF10B981), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16)),
            ],
          ),
          const SizedBox(height: 24),
          Text(appointment.doctorName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1.0)),
          const SizedBox(height: 6),
          Text(appointment.specialty ?? 'Medical Specialist', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)), child: Text('ID: #CON-${math.Random().nextInt(10000)}', style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Appointment appointment;
  final Color primaryColor;
  const _InfoSection({required this.appointment, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final dateStr = '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}';
    final timeStr = TimeOfDay.fromDateTime(appointment.appointmentDate).format(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        children: [
          _InfoRow(icon: Icons.calendar_today_rounded, label: 'SESSION DATE', value: dateStr, color: primaryColor),
          const Divider(height: 48, color: Color(0xFFF1F5F9)),
          _InfoRow(icon: Icons.access_time_filled_rounded, label: 'SESSION TIME', value: timeStr, color: const Color(0xFFF59E0B)),
          const Divider(height: 48, color: Color(0xFFF1F5F9)),
          _InfoRow(icon: Icons.timer_rounded, label: 'DURATION', value: '${appointment.durationMinutes} Minutes', color: const Color(0xFF10B981)),
          const Divider(height: 48, color: Color(0xFFF1F5F9)),
          _InfoRow(icon: Icons.videocam_rounded, label: 'CONSULTATION', value: appointment.mode.name.toUpperCase(), color: const Color(0xFF6366F1)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 18, color: color)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }
}

class _VideoCallAction extends StatelessWidget {
  final Appointment appointment;
  final Color primaryColor;
  const _VideoCallAction({required this.appointment, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: () => _joinMeeting(context),
        icon: const Icon(Icons.videocam_rounded, size: 22),
        label: const Text('JOIN CLINICAL SESSION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  void _joinMeeting(BuildContext context) {
    context.push('/consultation/${appointment.id}');
  }
}

class _CancelAction extends StatelessWidget {
  final String appointmentId;
  const _CancelAction({required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: OutlinedButton(
        onPressed: () => _confirmCancel(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEF4444),
          side: const BorderSide(color: Color(0xFFFEE2E2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('CANCEL SESSION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Confirm Cancellation', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to cancel this session? This action is permanent and the specialist will be notified.', style: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('KEEP SESSION', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B)))),
          TextButton(
            onPressed: () async {
              await AppointmentService.cancelAppointment(appointmentId);
              if (context.mounted) {
                Navigator.pop(context);
                context.pop();
              }
            },
            child: const Text('CONFIRM CANCEL', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
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
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)],
      ),
    );
  }
}

