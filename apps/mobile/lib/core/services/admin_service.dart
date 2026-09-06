import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  // Verification
  Future<void> updateVerificationStatus(String userId, String status, {String? reason}) async {
    final Map<String, dynamic> updates = {
      'verification_status': status,
      'verified_by': _client.auth.currentUser?.id,
    };
    if (reason != null) updates['rejection_reason'] = reason;

    // Promote to doctor role on approval (matching web doctor-management.tsx behavior)
    // Guard: only promote if not already 'doctor' — preserves unified account switching
    if (status == 'approved') {
      final current = await _client.from('profiles').select('role').eq('id', userId).single();
      if (current['role'] != 'doctor') {
        updates['role'] = 'doctor';
      }
    }

    await _client.from('profiles').update(updates).eq('id', userId);

    // Send notification to the user
    try {
      final title = status == 'approved'
          ? 'Account Verified'
          : status == 'rejected'
              ? 'Verification Update'
              : 'Verification Under Review';
      final message = status == 'approved'
          ? 'Congratulations! Your professional account has been verified. You now have access to the Doctor Dashboard. Please negotiate your platform fee with the admin to unlock full features.'
          : status == 'rejected'
              ? 'Your verification was not approved. ${reason ?? "Please contact support for details."}'
              : 'Your verification is being reviewed. We will update you soon.';

      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': 'system',
        'is_read': false,
      });
    } catch (_) {}
  }

  Future<void> resetVerification(String userId) async {
    await _client.from('profiles').update({
      'verification_status': 'unsubmitted',
      'rejection_reason': null,
      'verified_by': null,
    }).eq('id', userId);
  }

  // Financials
  Future<Map<String, dynamic>> getFinancialStats() async {
    final response = await _client.rpc('get_admin_financial_stats');
    return response as Map<String, dynamic>;
  }

  Future<void> approvePayout(String payoutId) async {
    await _client.from('payouts').update({
      'status': 'approved',
      'processed_at': DateTime.now().toIso8601String(),
      'processed_by': _client.auth.currentUser?.id,
    }).eq('id', payoutId);
  }

  Future<void> processRefund(String refundId, String status) async {
    await _client.from('refunds').update({
      'status': status,
      'processed_at': DateTime.now().toIso8601String(),
      'processed_by': _client.auth.currentUser?.id,
    }).eq('id', refundId);
  }

  // Monitoring & User Management
  Future<void> blockUser(String userId, String reason) async {
    await _client.from('blocked_users').insert({
      'user_id': userId,
      'reason': reason,
      'blocked_by': _client.auth.currentUser?.id,
    });
  }

  Future<List<Map<String, dynamic>>> getUsers({
    String? role,
    String? status,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client.from('profiles').select();

    if (role != null && role != 'all') {
      query = query.eq('role', role.toLowerCase());
    }

    if (status != null && status != 'all') {
      query = query.eq('account_status', status.toLowerCase());
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final sanitized = searchQuery.replaceAll('%', '\\%').replaceAll('_', '\\_');
      query = query.or('full_name.ilike.%$sanitized%,email.ilike.%$sanitized%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getUserManagementStats() async {
    // In production, use a dedicated RPC or view. Here we query totals.
    final total = await _client.from('profiles').count(CountOption.exact);
    final doctors = await _client.from('profiles').select('id').eq('role', 'doctor').count(CountOption.exact);
    final patients = await _client.from('profiles').select('id').eq('role', 'patient').count(CountOption.exact);
    final suspended = await _client.from('profiles').select('id').eq('account_status', 'suspended').count(CountOption.exact);
    final pending = await _client.from('profiles').select('id').eq('verification_status', 'pending').count(CountOption.exact);

    return {
      'total': total,
      'doctors': doctors,
      'patients': patients,
      'pending': pending,
      'suspended': suspended,
    };
  }

  Future<void> updateUserAccountStatus(String userId, String status) async {
    await _client.from('profiles').update({
      'account_status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateUserProfileAdmin(String userId, Map<String, dynamic> updates) async {
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  // Notifications
  Future<void> updateChannelConfig(String channelId, bool isEnabled) async {
    await _client.from('notification_channels_config').update({
      'is_enabled': isEnabled,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', channelId);
  }

  Future<void> sendSystemNotification({
    required String title,
    required String message,
    required String targetRole, // 'all', 'patient', 'doctor'
  }) async {
    // First, insert notifications into DB for in-app display
    final query = _client.from('profiles').select('id');
    if (targetRole != 'all') {
      query.eq('role', targetRole);
    }
    
    final users = await query;
    final List<Map<String, dynamic>> notifications = users.map((u) => {
      'user_id': u['id'],
      'title': title,
      'message': message,
      'type': 'system',
    }).toList();

    await _client.from('notifications').insert(notifications);

    // Dispatch FCM push to each user via web API
    try {
      final session = _client.auth.currentSession;
      final siteUrl = const String.fromEnvironment('NEXT_PUBLIC_SITE_URL', defaultValue: 'https://premoncare.com');
      for (final user in users) {
        try {
          await http.post(
            Uri.parse('$siteUrl/api/notifications/dispatch'),
            headers: {
              'Content-Type': 'application/json',
              if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
            },
            body: jsonEncode({
              'userId': user['id'],
              'title': title,
              'message': message,
              'type': 'system',
            }),
          );
        } catch (_) {}
      }
    } catch (_) {}
  }
}
