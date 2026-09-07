import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> initSupabase() async {
  final url = dotenv.env['SUPABASE_URL'];
  final key = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty || key == null || key.isEmpty) {
    throw Exception(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file. '
      'Copy .env.sample to .env and fill in your credentials.',
    );
  }

  await Supabase.initialize(url: url, publishableKey: key);
}

final supabase = Supabase.instance.client;

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
    debugPrint('getUserRole error (non-fatal): $e');
    return _cachedRole ?? 'denied';
  }
}

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

