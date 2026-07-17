import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_locator.dart';

/// Provider for the current user's role
final userRoleProvider = FutureProvider<String>((ref) async {
  return await getUserRole();
});

/// Provider for pending payments streaming for doctors
final pendingPaymentsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);
  
  return supabase
      .from('pending_payments_view')
      .stream(primaryKey: ['id'])
      .eq('recipient_id', user.id)
      .map((data) => data);
});

/// Provider for the current user's profile data
final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value(null);

  return supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map((data) => data.isNotEmpty ? data.first : null);
});

/// Provider for the current patient's consultation credits (time balance)
final patientCreditsProvider = StreamProvider.autoDispose<int>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value(0);

  return supabase
      .from('time_balances')
      .stream(primaryKey: ['patient_id', 'doctor_id'])
      .eq('patient_id', user.id)
      .map((balances) {
        int totalMinutes = 0;
        for (var balance in balances) {
          totalMinutes += (balance['minutes_remaining'] as num?)?.toInt() ?? 0;
        }
        return totalMinutes;
      });
});

// Removed: use availableDoctorsProvider in features/patient/patient_providers.dart instead

// Removed: doctorMetricsProvider — use userProfileProvider instead

/// Provider for the doctor's upcoming appointments (excludes emergency requests)
final upcomingAppointmentsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('appointments')
      .stream(primaryKey: ['id'])
      .eq('doctor_id', user.id)
      .order('appointment_date', ascending: true)
      .limit(10)
      .map((data) => data.where((a) => a['status'] != 'emergency_request').toList());
});

/// Provider for the doctor's incoming emergency requests (status = emergency_request)
final emergencyRequestsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('appointments')
      .stream(primaryKey: ['id'])
      .eq('doctor_id', user.id)
      .order('created_at', ascending: false)
      .map((data) => data.where((a) => a['status'] == 'emergency_request').toList());
});

/// Provider for the doctor's revenue
final doctorRevenueProvider = StreamProvider.autoDispose<num>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value(0);

  return supabase
      .from('payments')
      .stream(primaryKey: ['id'])
      .eq('recipient_id', user.id)
      .map((payments) {
        num total = 0;
        for (var p in payments) {
          if (p['status'] == 'approved') {
            total += (p['amount'] as num?) ?? 0;
          }
        }
        return total;
      });
});

// Removed: use patientAppointmentsProvider in features/patient/patient_providers.dart instead

/// Provider for the patient's medical records
final patientMedicalRecordsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('medical_records')
      .stream(primaryKey: ['id'])
      .eq('patient_id', user.id)
      .map((data) => data);
});

// ─── Admin Providers ────────────────────────────────────────────────

/// Provider for admin dashboard stats (total users, doctors, appointments, revenue)
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final usersResult = await supabase.from('profiles').select('id').count();
  final doctorsResult = await supabase.from('profiles').select('id').eq('role', 'doctor').eq('verification_status', 'approved').count();
  final appointmentsResult = await supabase.from('appointments').select('id').gte('appointment_date', DateTime.now().toIso8601String()).count();
  final payments = await supabase.from('payments').select('amount').eq('status', 'approved');

  num totalRevenue = 0;
  for (var p in payments) {
    totalRevenue += (p['amount'] as num?) ?? 0;
  }

  return {
    'totalUsers': usersResult.count,
    'verifiedDoctors': doctorsResult.count,
    'todayAppointments': appointmentsResult.count,
    'totalRevenue': totalRevenue,
  };
});

/// Provider for pending doctor verifications count
final pendingVerificationsProvider = FutureProvider<int>((ref) async {
  final result = await supabase
      .from('profiles')
      .select('id')
      .eq('role', 'doctor')
      .eq('verification_status', 'pending')
      .count();
  return result.count;
});

/// Provider for pending payment disputes count
final pendingDisputesProvider = FutureProvider<int>((ref) async {
  final result = await supabase
      .from('payments')
      .select('id')
      .eq('status', 'disputed')
      .count();
  return result.count;
});

/// Provider for recent doctor applications (pending verification)
final recentDoctorApplicationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await supabase
      .from('profiles')
      .select('id, full_name, email, created_at, specialty, avatar_url')
      .eq('role', 'doctor')
      .eq('verification_status', 'pending')
      .order('created_at', ascending: false)
      .limit(5);
  return List<Map<String, dynamic>>.from(response);
});

/// Provider for recent transactions
final recentTransactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await supabase
      .from('payments')
      .select('id, amount, status, created_at, user_id, recipient_id')
      .order('created_at', ascending: false)
      .limit(5);
  return List<Map<String, dynamic>>.from(response);
});

// Removed: PaymentService was never used — use the version in admin/financial features if needed
