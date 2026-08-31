import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../app_colors.dart';

class BiometricGate extends StatefulWidget {
  final Widget child;
  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate> with WidgetsBindingObserver {
  final _biometricService = BiometricService();
  bool _isLocked = true;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBiometric();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBiometric();
    } else if (state == AppLifecycleState.paused) {
      setState(() => _isLocked = true);
    }
  }

  Future<void> _checkBiometric() async {
    final enabled = await _biometricService.isEnabled();
    if (!enabled) {
      setState(() { _isLocked = false; _checking = false; });
      return;
    }

    final available = await _biometricService.isAvailable();
    if (!available) {
      setState(() { _isLocked = false; _checking = false; });
      return;
    }

    final authenticated = await _biometricService.authenticate();
    if (mounted) {
      setState(() { _isLocked = !authenticated; _checking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (_isLocked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, color: AppColors.primary, size: 64),
                const SizedBox(height: 24),
                const Text('App Locked', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Authenticate to continue', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _checkBiometric,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Unlock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
