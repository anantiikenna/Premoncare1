import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
}

final supabase = Supabase.instance.client;

// In-memory cache for user role to avoid querying on every navigation
String? _cachedRole;
String? _cachedUserId;

Future<String> getUserRole() async {
  final user = supabase.auth.currentUser;
  if (user == null) return 'patient';
  
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
    return 'patient';
  }
}

/// Clear cached role (call on logout)
void clearRoleCache() {
  _cachedRole = null;
  _cachedUserId = null;
}

