import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_locator.dart';

enum AppointmentStatus { pending, confirmed, ongoing, cancelled, completed, emergencyRequest, emergencyAccepted, emergencyDeclined, rescheduled }

enum ConsultationMode { video, audio, text, inPerson }

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String? doctorTitle;
  final String? doctorAvatar;
  final String? specialty;
  final DateTime appointmentDate;
  final AppointmentStatus status;
  final String? reason;
  final ConsultationMode mode;
  final int durationMinutes;
  final String? meetingLink;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    this.doctorTitle,
    this.doctorAvatar,
    this.specialty,
    required this.appointmentDate,
    required this.status,
    this.reason,
    required this.mode,
    required this.durationMinutes,
    this.meetingLink,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      doctorName: json['doctor']?['full_name'] ?? 'Unknown Doctor',
      doctorTitle: json['doctor']?['title'] as String?,
      doctorAvatar: json['doctor']?['avatar_url'],
      specialty: json['doctor']?['specialty'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      status: _statusFromDb(json['status']),
      reason: json['reason'],
      mode: _modeFromDb(json['consultation_mode']),
      durationMinutes: json['duration_minutes'] ?? 15,
      meetingLink: json['meeting_link'],
    );
  }

  static AppointmentStatus _statusFromDb(String? raw) {
    switch (raw) {
      case 'emergency_request':
        return AppointmentStatus.emergencyRequest;
      case 'emergency_accepted':
        return AppointmentStatus.emergencyAccepted;
      case 'emergency_declined':
        return AppointmentStatus.emergencyDeclined;
      case 'in_progress':
      case 'ongoing':
        return AppointmentStatus.ongoing;
      case 'pending':
        return AppointmentStatus.pending;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
      case 'canceled':
        return AppointmentStatus.cancelled;
      case 'rescheduled':
        return AppointmentStatus.rescheduled;
      default:
        return AppointmentStatus.pending;
    }
  }

  static ConsultationMode _modeFromDb(String? raw) {
    switch (raw) {
      case 'video':
        return ConsultationMode.video;
      case 'audio':
        return ConsultationMode.audio;
      case 'in_person':
        return ConsultationMode.inPerson;
      case 'text':
        return ConsultationMode.text;
      default:
        return ConsultationMode.text;
    }
  }
}

/// Provider for a user's appointments (works for both patients and doctors)
final appointmentsProvider = StreamProvider<List<Appointment>>((ref) async* {
  final user = supabase.auth.currentUser;
  if (user == null) {
    yield [];
    return;
  }

  // Get user role once to determine query
  String role;
  try {
    final roleResponse = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
    role = roleResponse['role'] as String? ?? 'patient';
  } catch (_) {
    role = 'patient';
  }
  final isDoctor = role == 'doctor';

  final stream = supabase
      .from('appointments')
      .stream(primaryKey: ['id'])
      .order('appointment_date', ascending: false);

  await for (final data in stream) {
    if (data.isEmpty) {
      yield [];
      continue;
    }

    // Since stream doesn't support .select('..., doctor:profiles(full_name)') easily 
    // with real-time updates for nested fields in all cases, we enrich the data
    final records = data.map((json) => json).toList();
    
    // Fetch doctor/patient profiles to enrich the list
    final partnerIds = records
        .map((r) => isDoctor ? r['patient_id'] : r['doctor_id'])
        .toList();
    
    final profilesResponse = await supabase
        .from('profiles')
        .select('id, full_name, avatar_url, specialty')
        .inFilter('id', partnerIds);
    
    final profileMap = {
      for (var p in profilesResponse) p['id']: p
    };

    yield records.map((r) {
      final partnerId = isDoctor ? r['patient_id'] : r['doctor_id'];
      return Appointment.fromJson({
        ...r,
        'doctor': profileMap[partnerId], // In "Doctor" mode, this is actually the patient, but we name it doctor for the UI model simplicity or we can refactor
      });
    }).toList();
  }
});

class AppointmentService {
  static Future<void> cancelAppointment(String id) async {
    await supabase
        .from('appointments')
        .update({'status': 'cancelled'})
        .eq('id', id);
    
    // Create notification for the other party
    try {
      final res = await supabase
          .from('appointments')
          .select('patient_id, doctor_id')
          .eq('id', id)
          .single();

      final user = supabase.auth.currentUser;
      final otherPartyId = user?.id == res['patient_id'] ? res['doctor_id'] : res['patient_id'];

      await supabase.from('notifications').insert({
        'user_id': otherPartyId,
        'title': 'Appointment Cancelled',
        'message': 'An appointment has been cancelled.',
        'type': 'appointment',
      });
    } catch (_) {}
  }

  static Future<void> rescheduleAppointment(String id, DateTime newDate) async {
    await supabase
        .from('appointments')
        .update({
          'appointment_date': newDate.toIso8601String(),
          'status': 'rescheduled',
        })
        .eq('id', id);

    try {
      final res = await supabase
          .from('appointments')
          .select('patient_id, doctor_id')
          .eq('id', id)
          .single();

      final user = supabase.auth.currentUser;
      final otherPartyId = user?.id == res['patient_id'] ? res['doctor_id'] : res['patient_id'];
      final role = user?.id == res['patient_id'] ? 'Patient' : 'Doctor';

      final dateStr = '${newDate.day}/${newDate.month}/${newDate.year} at ${newDate.hour}:${newDate.minute.toString().padLeft(2, '0')}';

      await supabase.from('notifications').insert({
        'user_id': otherPartyId,
        'title': 'Appointment Rescheduled',
        'message': 'The $role has rescheduled the appointment to $dateStr.',
        'type': 'appointment',
      });
    } catch (_) {}
  }

  static Future<void> bookAppointment({
    required String doctorId,
    required DateTime date,
    required ConsultationMode mode,
    required int duration,
    String? reason,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('appointments').insert({
      'patient_id': user.id,
      'doctor_id': doctorId,
      'appointment_date': date.toIso8601String(),
      'consultation_mode': mode.name,
      'duration_minutes': duration,
      'reason': reason,
      'status': 'pending',
    });
  }
}
