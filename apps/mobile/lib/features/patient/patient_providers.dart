import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_locator.dart';

/// Provider for the list of doctors for manual payment selection
final availableDoctorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase
      .from('profiles')
      .select('id, full_name, consultation_fee, payment_instructions')
      .eq('role', 'doctor')
      .order('full_name');
  
  return List<Map<String, dynamic>>.from(data);
});

/// Provider for patient's personal payment history
final patientPaymentsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
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
final patientAppointmentsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('appointments')
      .stream(primaryKey: ['id'])
      .eq('patient_id', user.id)
      .order('appointment_date', ascending: false)
      .asyncMap((data) async {
        final appointments = <Map<String, dynamic>>[];
        for (final item in data) {
          final doctorData = await supabase
              .from('profiles')
              .select('full_name')
              .eq('id', item['doctor_id'])
              .single();
          appointments.add({...item, 'doctor_name': doctorData['full_name']});
        }
        return appointments;
      });
});

/// Provider for patient's detailed consultation credits by doctor.
/// NOTE: Use core/providers.dart patientCreditsProvider for the total int balance
/// shown on the dashboard. This provider is used by credits_screen.dart for
/// per-doctor breakdowns.
final patientDetailedCreditsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('time_balances')
      .stream(primaryKey: ['patient_id', 'doctor_id'])
      .eq('patient_id', user.id)
      .asyncMap((balances) async {
        final List<Map<String, dynamic>> results = [];
        for (final balance in balances) {
          final doctorId = balance['doctor_id'];
          final minutes = balance['minutes_remaining'];
          
          try {
            final docProfile = await supabase
                .from('profiles')
                .select('full_name, specialty, hourly_rate, verification_status, avatar_url')
                .eq('id', doctorId)
                .single();
                
            results.add({
              'doctor_id': doctorId,
              'minutes_remaining': minutes,
              'doctor_name': docProfile['full_name'],
              'specialty': docProfile['specialty'] ?? 'Specialist',
              'hourly_rate': docProfile['hourly_rate'] ?? 200,
              'verification_status': docProfile['verification_status'],
              'avatar_url': docProfile['avatar_url'],
            });
          } catch (e) {
            results.add({
              'doctor_id': doctorId,
              'minutes_remaining': minutes,
              'doctor_name': 'Unknown Doctor',
              'specialty': 'Specialist',
              'hourly_rate': 200,
              'verification_status': 'approved',
              'avatar_url': null,
            });
          }
        }
        return results;
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
