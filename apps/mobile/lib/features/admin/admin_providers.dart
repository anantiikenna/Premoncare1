import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/admin_service.dart';

final adminServiceProvider = Provider((ref) => AdminService());

final adminFinancialStatsProvider = FutureProvider((ref) async {
  final service = ref.watch(adminServiceProvider);
  return service.getFinancialStats();
});

final pendingVerificationsProvider = StreamProvider((ref) {
  return Stream.value([]); // In real implementation, return Supabase stream
});

final notificationChannelsProvider = StreamProvider((ref) {
  return Stream.value([]); // In real implementation, return Supabase stream
});
