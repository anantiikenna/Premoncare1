import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_locator.dart';

Stream<List<Map<String, dynamic>>> _watchApprovedDoctors({
  required String select,
  required String channelName,
  required Ref ref,
}) {
  final controller = StreamController<List<Map<String, dynamic>>>();

  Future<void> load() async {
    try {
      final data = await supabase
          .from('profiles')
          .select(select)
          .eq('role', 'doctor')
          .eq('verification_status', 'approved')
          .order('is_online', ascending: false)
          .order('full_name');
      if (!controller.isClosed) {
        controller.add(List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }

  load();

  final channel = supabase
      .channel(channelName)
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        filter: const PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'role',
          value: 'doctor',
        ),
        callback: (_) => load(),
      )
      ..subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
}

/// Live list of approved doctors for manual payment / record sharing
final availableDoctorsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return _watchApprovedDoctors(
    select:
        'id, full_name, consultation_fee, payment_instructions, specializations_list, hourly_rate, is_online',
    channelName: 'available-doctors-live',
    ref: ref,
  );
});

/// Live searchable list of approved doctors (online first)
final searchableDoctorsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return _watchApprovedDoctors(
        select: 'id, full_name, specialty, consultation_fee, is_online, is_emergency',
    channelName: 'searchable-doctors-live',
    ref: ref,
  );
});

/// Provider for patient's personal payment history
final patientPaymentsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('payments')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .map((data) => data);
});

/// Provider for patient's appointments (for review purposes)
final patientAppointmentsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('appointments')
      .stream(primaryKey: ['id'])
      .eq('patient_id', user.id)
      .order('appointment_date', ascending: false)
      .asyncMap((data) async {
        if (data.isEmpty) return [];

        // Batch fetch all doctor profiles in one query
        final doctorIds = data.map((e) => e['doctor_id'] as String).toSet().toList();
        final doctorsResult = await supabase
            .from('profiles')
            .select('id, full_name')
            .inFilter('id', doctorIds);

        final doctorMap = {
          for (final d in doctorsResult as List) d['id'] as String: d,
        };

        return data.map((item) {
          final doctorData = doctorMap[item['doctor_id'] as String];
          return {...item, 'doctor_name': doctorData?['full_name'] ?? 'Unknown'};
        }).toList();
      });
});

/// Provider for patient's detailed consultation credits by doctor.
/// NOTE: Use core/providers.dart patientCreditsProvider for the total int balance
/// shown on the dashboard. This provider is used by credits_screen.dart for
/// per-doctor breakdowns.
final patientDetailedCreditsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('time_balances')
      .stream(primaryKey: ['patient_id', 'doctor_id'])
      .eq('patient_id', user.id)
      .asyncMap((balances) async {
        if (balances.isEmpty) return [];

        // Batch fetch all doctor profiles in one query
        final doctorIds = balances.map((b) => b['doctor_id'] as String).toSet().toList();
        final doctorsResult = await supabase
            .from('profiles')
            .select('id, full_name, specialty, hourly_rate, verification_status, avatar_url')
            .inFilter('id', doctorIds);

        final doctorMap = {
          for (final d in doctorsResult as List) d['id'] as String: d,
        };

        return balances.map((balance) {
          final doctorId = balance['doctor_id'] as String;
          final docProfile = doctorMap[doctorId];
          return {
            'doctor_id': doctorId,
            'minutes_remaining': balance['minutes_remaining'],
            'doctor_name': docProfile?['full_name'] ?? 'Unknown Doctor',
            'specialty': docProfile?['specialty'] ?? 'Specialist',
            'hourly_rate': docProfile?['hourly_rate'] ?? 200,
            'verification_status': docProfile?['verification_status'] ?? 'approved',
            'avatar_url': docProfile?['avatar_url'],
          };
        }).toList();
      });
});

class PatientPaymentService {
  static Future<void> uploadReceipt({
    required String doctorId,
    required double amount,
    required File receiptFile,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Upload to storage
    final fileExt = receiptFile.path.split('.').last;
    final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    
    await supabase.storage.from('payment-receipts').upload(
      fileName,
      receiptFile,
    );

    final publicUrl = supabase.storage.from('payment-receipts').getPublicUrl(fileName);

    // 2. Insert payment record
    await supabase.from('payments').insert({
      'user_id': user.id,
      'recipient_id': doctorId,
      'amount': amount,
      'method': 'manual',
      'receipt_url': publicUrl,
      'status': 'pending',
    });
  }
}

/// Provider for consultation summary data (prescriptions + consultation notes)
final consultationSummaryProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, appointmentId) async {
  final prescriptions = await supabase
      .from('prescriptions')
      .select('id, medication_name, dosage, frequency, duration, instructions')
      .eq('appointment_id', appointmentId)
      .order('created_at');

  final notes = await supabase
      .from('consultation_notes')
      .select('id, observations, follow_up_days, created_at')
      .eq('appointment_id', appointmentId)
      .order('created_at')
      .maybeSingle();

  return {
    'prescriptions': List<Map<String, dynamic>>.from(prescriptions),
    'notes': notes,
  };
});
