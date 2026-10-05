import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:collection/collection.dart';
import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'appointment_provider.dart';


class AppointmentDetailScreen extends ConsumerWidget {
  final String appointmentId;
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.08), size: 500),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.03), size: 300),
          ),

          SafeArea(
            child: appointmentsAsync.when(
              data: (appointments) {
                final appointment = appointments.firstWhereOrNull((a) => a.id == appointmentId);
                if (appointment == null) {
                  return const Scaffold(body: Center(child: Text('Appointment not found')));
                }

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
                            _HeaderSection(appointment: appointment),
                            const SizedBox(height: 32),
                            _buildSectionTitle(context, 'SESSION ARCHITECTURE'),
                            const SizedBox(height: 16),
                            _InfoSection(appointment: appointment),
                            const SizedBox(height: 32),
                            _buildSectionTitle(context, 'CLINICAL ACTIONS'),
                            const SizedBox(height: 16),
                            if ((appointment.status == AppointmentStatus.confirmed ||
                                    appointment.status == AppointmentStatus.rescheduled ||
                                    appointment.status == AppointmentStatus.ongoing ||
                                    appointment.status == AppointmentStatus.completed ||
                                    (appointment.status == AppointmentStatus.emergencyAccepted &&
                                        appointment.paymentStatus == 'completed')) &&
                                appointment.mode == ConsultationMode.video) _VideoCallAction(appointment: appointment),
                            const SizedBox(height: 16),
                            if (appointment.status == AppointmentStatus.pending || appointment.status == AppointmentStatus.confirmed || appointment.status == AppointmentStatus.rescheduled) _RescheduleAction(appointment: appointment),
                            const SizedBox(height: 16),
                            if (appointment.status == AppointmentStatus.pending || appointment.status == AppointmentStatus.confirmed || appointment.status == AppointmentStatus.rescheduled) _CancelAction(appointmentId: appointment.id),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)),
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
            child: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderOf(context))), child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context), size: 20)),
          ),
          Text('Session Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5)),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.surfaceOf(context),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderOf(context), borderRadius: BorderRadius.circular(2))),
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
                        leading: Icon(Icons.flag_rounded, color: AppColors.error),
                        title: Text('Report Issue', style: TextStyle(color: AppColors.error)),
                        onTap: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderOf(context))), child: Icon(Icons.more_horiz_rounded, color: AppColors.textPrimaryOf(context), size: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }
}

class _HeaderSection extends StatelessWidget {
  final Appointment appointment;
  const _HeaderSection({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context)), boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: CircleAvatar(radius: 50, backgroundColor: AppColors.primary.withValues(alpha: 0.15), child: Text(appointment.doctorName.isNotEmpty ? appointment.doctorName[0].toUpperCase() : 'D', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.primary)))),
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: AppColors.surfaceOf(context), width: 3)), child: Icon(Icons.verified_rounded, color: AppColors.textInverse, size: 16)),
            ],
          ),
          const SizedBox(height: 24),
          Text(appointment.doctorName, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0)),
          const SizedBox(height: 6),
          Text(appointment.specialty ?? 'Medical Specialist', style: TextStyle(fontSize: 14, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)), child: Text('ID: #CON-${appointment.id.substring(0, appointment.id.length > 8 ? 8 : appointment.id.length)}', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Appointment appointment;
  const _InfoSection({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final dateStr = '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}';
    final timeStr = TimeOfDay.fromDateTime(appointment.appointmentDate).format(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Column(
        children: [
          _InfoRow(icon: Icons.calendar_today_rounded, label: 'SESSION DATE', value: dateStr, color: AppColors.primary),
          Divider(height: 48, color: AppColors.borderLightOf(context)),
          _InfoRow(icon: Icons.access_time_filled_rounded, label: 'SESSION TIME', value: timeStr, color: AppColors.warning),
          Divider(height: 48, color: AppColors.borderLightOf(context)),
          _InfoRow(icon: Icons.timer_rounded, label: 'DURATION', value: '${appointment.durationMinutes} Minutes', color: AppColors.success),
          Divider(height: 48, color: AppColors.borderLightOf(context)),
          _InfoRow(icon: Icons.videocam_rounded, label: 'CONSULTATION', value: appointment.mode.name.toUpperCase(), color: AppColors.primary),
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
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.textTertiaryOf(context), letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimaryOf(context))),
          ],
        ),
      ],
    );
  }
}

class _VideoCallAction extends StatelessWidget {
  final Appointment appointment;
  const _VideoCallAction({required this.appointment});

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
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          elevation: 10,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  void _joinMeeting(BuildContext context) {
    context.push('/consultation/${appointment.id}', extra: {
      'doctorName': appointment.doctorName,
      'specialty': appointment.specialty,
      'durationMinutes': appointment.durationMinutes,
    });
  }
}

class _RescheduleAction extends StatelessWidget {
  final Appointment appointment;
  const _RescheduleAction({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: OutlinedButton.icon(
        onPressed: () => _showReschedulePicker(context),
        icon: const Icon(Icons.schedule_rounded, size: 20),
        label: const Text('RESCHEDULE SESSION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.info,
          side: BorderSide(color: AppColors.infoLightOf(context)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  void _showReschedulePicker(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: appointment.appointmentDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appointment.appointmentDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime == null || !context.mounted) return;

    final newDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm Reschedule', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          'Reschedule this session to ${pickedDate.day}/${pickedDate.month}/${pickedDate.year} at ${pickedTime.format(context)}? The other party will be notified.',
          style: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.textSecondaryOf(context)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textSecondaryOf(context)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary))),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await AppointmentService.rescheduleAppointment(appointment.id, newDate);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Session rescheduled successfully'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
        context.pop();
      }
    }
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
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.errorLightOf(context)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm Cancellation', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to cancel this session? This action is permanent and the specialist will be notified.', style: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.textSecondaryOf(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('KEEP SESSION', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textSecondaryOf(context)))),
          TextButton(
            onPressed: () async {
              await AppointmentService.cancelAppointment(appointmentId);
              if (context.mounted) {
                Navigator.pop(context);
                context.pop();
              }
            },
            child: Text('CONFIRM CANCEL', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.error)),
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
