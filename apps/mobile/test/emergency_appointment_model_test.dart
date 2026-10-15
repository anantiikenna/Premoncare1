import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/appointments/appointment_provider.dart';

Map<String, dynamic> rawAppointment({
  String status = 'emergency_request',
  String? paymentStatus = 'pending',
}) {
  return {
    'id': 'apt-1',
    'patient_id': 'pat-1',
    'doctor_id': 'doc-1',
    'doctor': {'full_name': 'Dr. Alpha', 'title': 'MD', 'specialty': 'Cardiology'},
    'appointment_date': '2026-10-20T10:00:00Z',
    'status': status,
    'reason': 'Chest pain',
    'consultation_mode': 'video',
    'duration_minutes': 30,
    'payment_status': paymentStatus,
  };
}

void main() {
  group('Appointment emergency status mapping (DB contract)', () {
    test('emergency_request maps to emergencyRequest', () {
      final apt = Appointment.fromJson(rawAppointment(status: 'emergency_request'));
      expect(apt.status, AppointmentStatus.emergencyRequest);
    });

    test('emergency_accepted maps to emergencyAccepted', () {
      final apt = Appointment.fromJson(rawAppointment(status: 'emergency_accepted'));
      expect(apt.status, AppointmentStatus.emergencyAccepted);
    });

    test('emergency_declined maps to emergencyDeclined', () {
      final apt = Appointment.fromJson(rawAppointment(status: 'emergency_declined'));
      expect(apt.status, AppointmentStatus.emergencyDeclined);
    });

    test('ongoing and in_progress both map to ongoing', () {
      expect(Appointment.fromJson(rawAppointment(status: 'ongoing')).status,
          AppointmentStatus.ongoing);
      expect(Appointment.fromJson(rawAppointment(status: 'in_progress')).status,
          AppointmentStatus.ongoing);
    });

    test('canceled (double-l) and cancelled map to cancelled', () {
      expect(Appointment.fromJson(rawAppointment(status: 'canceled')).status,
          AppointmentStatus.cancelled);
      expect(Appointment.fromJson(rawAppointment(status: 'cancelled')).status,
          AppointmentStatus.cancelled);
    });

    test('unknown status falls back to pending', () {
      expect(Appointment.fromJson(rawAppointment(status: 'weird_status')).status,
          AppointmentStatus.pending);
    });
  });

  group('Payment gate fields', () {
    test('payment_status is preserved (emergency_accepted + completed gates the join CTA)', () {
      final apt = Appointment.fromJson(
          rawAppointment(status: 'emergency_accepted', paymentStatus: 'completed'));
      expect(apt.status, AppointmentStatus.emergencyAccepted);
      expect(apt.paymentStatus, 'completed');
    });

    test('missing payment_status defaults to pending (join stays gated)', () {
      final raw = rawAppointment(status: 'emergency_accepted');
      raw.remove('payment_status');
      final apt = Appointment.fromJson(raw);
      expect(apt.paymentStatus, 'pending');
    });
  });

  group('Consultation mode mapping', () {
    test('in_person maps to inPerson', () {
      final raw = rawAppointment();
      raw['consultation_mode'] = 'in_person';
      expect(Appointment.fromJson(raw).mode, ConsultationMode.inPerson);
    });

    test('unknown mode falls back to text', () {
      final raw = rawAppointment();
      raw['consultation_mode'] = 'carrier_pigeon';
      expect(Appointment.fromJson(raw).mode, ConsultationMode.text);
    });
  });
}
