import 'dart:async';
import 'package:flutter/material.dart';
import '../supabase_locator.dart';
import '../router.dart';

class InactivityDetector extends StatefulWidget {
  final Widget child;

  const InactivityDetector({super.key, required this.child});

  @override
  State<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends State<InactivityDetector> {
  Timer? _inactivityTimer;
  // 15 minutes timeout
  static const _timeoutDuration = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    _startTimer();
    
    // Listen for auth state changes to start/stop timer based on login status
    supabase.auth.onAuthStateChange.listen((event) {
      if (event.session != null) {
        _startTimer();
      } else {
        _cancelTimer();
      }
    });
  }

  void _startTimer() {
    _cancelTimer();
    // Only run the timer if the user is currently logged in
    if (supabase.auth.currentSession != null) {
      _inactivityTimer = Timer(_timeoutDuration, _handleInactivity);
    }
  }

  void _cancelTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _handleUserInteraction([_]) {
    _startTimer();
  }

  Future<void> _handleInactivity() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      await performLogout();
      goRouter.go('/session-expired');
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      child: widget.child,
    );
  }
}
