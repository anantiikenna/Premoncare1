import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
}

final supabase = Supabase.instance.client;

Future<String> getUserRole() async {
  final user = supabase.auth.currentUser;
  if (user == null) return 'patient';
  
  try {
    final response = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
    return response['role'] as String? ?? 'patient';
  } catch (e) {
    return 'patient';
  }
}

