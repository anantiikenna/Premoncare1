import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_service.dart';
import '../app_colors.dart';
import '../theme_provider.dart';

class BiometricGate extends ConsumerStatefulWidget {
  final Widget child;
  const BiometricGate({super.key, required this.child});

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate>
    with WidgetsBindingObserver {
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
      if (mounted) setState(() => _isLocked = true);
    }
  }

  Future<void> _checkBiometric() async {
    final enabled = await _biometricService.isEnabled();
    if (!enabled) {
      if (mounted) setState(() {
        _isLocked = false;
        _checking = false;
      });
      return;
    }

    final available = await _biometricService.isAvailable();
    if (!available) {
      if (mounted) setState(() {
        _isLocked = false;
        _checking = false;
      });
      return;
    }

    final authenticated = await _biometricService.authenticate();
    if (mounted) {
      setState(() {
        _isLocked = !authenticated;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);

    if (_checking) {
      return Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_isLocked) {
      return Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.primary, size: 64),
              const SizedBox(height: 24),
              Text(
                'App Locked',
                style: TextStyle(
                  color: AppColors.textPrimaryOf(context),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Authenticate to continue',
                style: TextStyle(
                  color: AppColors.textSecondaryOf(context),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _checkBiometric,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Unlock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
