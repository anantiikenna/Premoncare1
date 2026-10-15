import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> initSupabase() async {
  if (_supabaseUrl.isEmpty || _supabaseKey.isEmpty) {
    throw Exception(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
      'Pass them via --dart-define or --dart-define-from-file=dev.json '
      '(copy dev.json.sample to dev.json).',
    );
  }

  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
}

SupabaseClient? _debugSupabaseOverride;

@visibleForTesting
set debugSupabaseOverride(SupabaseClient? client) => _debugSupabaseOverride = client;

SupabaseClient get supabase => _debugSupabaseOverride ?? Supabase.instance.client;

// In-memory cache for user role to avoid querying on every navigation
String? _cachedRole;
String? _cachedUserId;

Future<String> getUserRole() async {
  final user = supabase.auth.currentUser;
  if (user == null) return 'denied';
  
  // Return cached role if same user
  if (_cachedUserId == user.id && _cachedRole != null) {
    return _cachedRole!;
  }
  
  try {
    final response = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
    final role = response['role'] as String? ?? 'patient';
    _cachedUserId = user.id;
    _cachedRole = role;
    return role;
  } catch (e) {
    if (kDebugMode) debugPrint('getUserRole error (non-fatal): $e');
    return _cachedRole ?? 'denied';
  }
}

/// Synchronous getter for cached role — safe to call in builders after redirect.
String? getCachedRole() => _cachedRole;

/// Clear cached role (call on logout)
void clearRoleCache() {
  _cachedRole = null;
  _cachedUserId = null;
}

/// Clear cached role for a specific user (call after profile updates,
/// verification status changes, etc.)
void clearRoleCacheForUser(String userId) {
  if (_cachedUserId == userId) {
    _cachedRole = null;
    _cachedUserId = null;
  }
}

/// Centralized logout: unsubscribe all Realtime channels, clear cache, sign out.
Future<void> performLogout() async {
  try {
    supabase.removeAllChannels();
  } catch (_) {}
  clearRoleCache();
  await supabase.auth.signOut();
}

