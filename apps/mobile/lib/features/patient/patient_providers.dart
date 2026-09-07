import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_locator.dart';

/// Provider for the list of doctors for manual payment selection
final availableDoctorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase
      .from('profiles')
      .select('id, full_name, consultation_fee, payment_instructions, specializations_list, hourly_rate')
      .eq('role', 'doctor')
      .order('full_name');
  
  return List<Map<String, dynamic>>.from(data);
});

/// Provider for searchable doctor list with all profile fields
final searchableDoctorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase
      .from('profiles')
      .select('id, full_name, title, specialty, consultation_fee, is_online, is_emergency')
      .eq('role', 'doctor')
      .order('full_name');
  
  return List<Map<String, dynamic>>.from(data);
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
            .select('id, full_name, title, specialty, hourly_rate, verification_status, avatar_url')
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
