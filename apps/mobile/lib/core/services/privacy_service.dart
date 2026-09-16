import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../supabase_locator.dart';

class PrivacyService {
  /// Sync privacy preferences to the Supabase profiles table
  Future<void> syncToServer() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final isProfileVisible = prefs.getBool('privacy_profile_visible') ?? true;
    final showOnlineStatus = prefs.getBool('privacy_online_status') ?? true;

    try {
      await supabase.from('profiles').update({
        'is_profile_visible': isProfileVisible,
        'is_showing_online_status': showOnlineStatus,
      }).eq('id', userId);
    } catch (e) {
      if (kDebugMode) debugPrint('PrivacyService sync error (non-critical): $e');
    }
  }

  /// Check if the current user's profile should be visible to doctors
  Future<bool> isProfileVisible() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('privacy_profile_visible') ?? true;
  }

  /// Check if the current user wants to show online status
  Future<bool> shouldShowOnlineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('privacy_online_status') ?? true;
  }
}
