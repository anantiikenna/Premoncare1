import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

String userFacingError(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
  final raw = error is AuthException ? error.message : error.toString();
  final text = raw.toLowerCase();

  if (text.contains('otp') || text.contains('token') || text.contains('code')) {
    if (text.contains('expired')) return 'That code has expired. Request a new code and try again.';
    if (text.contains('invalid')) return 'That code is incorrect. Please check the digits and try again.';
  }
  if (text.contains('email not confirmed')) {
    return 'Please verify your email address before signing in.';
  }
  if (text.contains('already registered') || text.contains('already exists') || text.contains('duplicate')) {
    return 'An account already exists for this email. Please sign in with your email code.';
  }
  if (text.contains('rate limit') || text.contains('too many') || text.contains('429')) {
    return 'Too many attempts. Please wait a moment before trying again.';
  }
  if (text.contains('socket') || text.contains('network') || text.contains('timeout') || text.contains('failed host lookup')) {
    return 'We could not reach Premon Care. Check your connection and try again.';
  }
  if (text.contains('permission denied') || text.contains('42501') || text.contains('row-level security')) {
    return 'You do not have permission to complete this action. Please contact support if this seems wrong.';
  }

  return fallback;
}

void logHandledError(String context, Object error, [StackTrace? stackTrace]) {
  developer.log(context, error: error, stackTrace: stackTrace, name: 'PremonCare');
}
