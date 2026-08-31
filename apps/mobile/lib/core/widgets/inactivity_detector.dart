import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;
import '../app_colors.dart';
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
  Timer? _warningTimer;
  Timer? _countdownTimer;
  StreamSubscription<AuthState>? _authSubscription;
  int _remainingSeconds = 60;
  bool _showWarning = false;

  static const _warningDuration = Duration(minutes: 14);
  static const _logoutDuration = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    _startTimers();

    _authSubscription = supabase.auth.onAuthStateChange.listen((event) {
      if (event.session != null) {
        _startTimers();
      } else {
        _cancelAllTimers();
      }
    });
  }

  void _startTimers() {
    _cancelAllTimers();
    if (supabase.auth.currentSession == null) return;

    _remainingSeconds = 60;
    _showWarning = false;

    _warningTimer = Timer(_warningDuration, _showInactivityWarning);

    _inactivityTimer = Timer(_logoutDuration, _handleInactivity);
  }

  void _cancelAllTimers() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    _countdownTimer?.cancel();
    _inactivityTimer = null;
    _warningTimer = null;
    _countdownTimer = null;
  }

  void _resetTimers() {
    _cancelAllTimers();
    if (mounted) setState(() => _showWarning = false);
    _startTimers();
  }

  void _showInactivityWarning() {
    if (!mounted) return;
    setState(() {
      _showWarning = true;
      _remainingSeconds = 60;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _handleInactivity();
        return;
      }
      if (mounted) setState(() => _remainingSeconds--);
    });
  }

  void _handleUserInteraction([_]) {
    if (_showWarning) return;
    _startTimers();
  }

  void _handleStayLoggedIn() {
    _countdownTimer?.cancel();
    _resetTimers();
  }

  Future<void> _handleInactivity() async {
    _cancelAllTimers();
    if (mounted) setState(() => _showWarning = false);
    final session = supabase.auth.currentSession;
    if (session != null) {
      await performLogout();
      goRouter.go('/session-expired');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelAllTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      child: Stack(
        children: [
          widget.child,
          if (_showWarning)
            GestureDetector(
              onTap: () {},
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.warningLightOf(context),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.access_time_filled_rounded,
                                color: AppColors.warning,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Session Expiring Soon',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimaryOf(context),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'For your security, you will be logged out in',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondaryOf(context),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$_remainingSeconds seconds',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: _remainingSeconds <= 15
                                    ? AppColors.error
                                    : AppColors.primary,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _handleStayLoggedIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textInverse,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Stay Logged In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
