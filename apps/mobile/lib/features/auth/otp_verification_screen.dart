import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart'
    show supabase, getUserRole, clearRoleCache, performLogout;
import '../../core/flavor_config.dart';
import '../../core/user_facing_errors.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final bool isEmergency;
  final bool isSignup;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    this.isEmergency = false,
    this.isSignup = false,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    7,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(7, (index) => FocusNode());
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isLoading = false;
  int _attemptsRemaining = 5;
  bool _isLocked = false;
  DateTime? _lockedUntil;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 6) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 7) {
      _verifyOtp();
    }
  }

  void _onPaste(String pasted) {
    final digits = pasted.replaceAll(RegExp(r'[^0-9]'), '').split('');
    for (var i = 0; i < 7 && i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }
    final lastFilled = digits.length.clamp(0, 6);
    _focusNodes[lastFilled].requestFocus();
    if (digits.length >= 7) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 7-digit code')),
      );
      return;
    }

    if (_isLocked) {
      final remaining = _lockedUntil?.difference(DateTime.now()).inMinutes ?? 15;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Too many failed attempts. Try again in $remaining minutes.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: widget.isSignup ? OtpType.signup : OtpType.email,
      );

      // Reset attempts on success (non-blocking)
      try {
        await supabase.rpc('reset_otp_attempts', params: {'p_email': widget.email});
      } catch (_) {}

      if (!mounted) return;

      final role = await getUserRole();

      if (!mounted) return;

      if (role == 'admin') {
        if (FlavorConfig.isAdmin) {
          clearRoleCache();
          if (mounted) {
            context.go('/admin-dashboard');
          }
          return;
        }
        await performLogout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Admin accounts cannot access the patient/doctor app. Please use the Admin app.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          context.go('/login');
        }
        return;
      }

      clearRoleCache();
      if (mounted) {
        context.go(
          role == 'doctor' ? '/doctor_dashboard' : '/patient_dashboard',
        );
      }
    } on AuthException catch (e, stackTrace) {
      logHandledError('OTP verification failed', e, stackTrace);

      // Track failed attempt (non-blocking)
      try {
        final limitResult = await supabase
            .rpc('check_otp_rate_limit', params: {'p_email': widget.email});
        if (limitResult != null && mounted) {
          final remaining = limitResult['attempts_remaining'] as int? ?? 0;
          final locked = limitResult['allowed'] == false;
          setState(() {
            _attemptsRemaining = remaining;
            if (locked) {
              _isLocked = true;
              _lockedUntil = DateTime.tryParse(limitResult['locked_until'] ?? '');
            }
          });
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                e,
                fallback:
                    'That code could not be verified. ${_attemptsRemaining > 0 ? '$_attemptsRemaining attempts remaining.' : 'Account temporarily locked.'}',
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e, stackTrace) {
      logHandledError('OTP verification failed', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -100,
            child: _MeshCircle(
              color: AppColors.primary.withValues(alpha: 0.1),
              size: 500,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _MeshCircle(
              color: AppColors.primary.withValues(alpha: 0.05),
              size: 400,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'IDENTITY VERIFICATION',
                          style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Verify Your Email',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimaryOf(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter the 7-digit code sent to',
                          style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final spacing = 6.0;
                              final boxWidth =
                                  ((availableWidth - (spacing * 6)) / 7)
                                      .floorToDouble()
                                      .clamp(34.0, 54.0);
                              final boxHeight = (boxWidth * 1.35)
                                  .floorToDouble();
                              return Wrap(
                                spacing: spacing,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: List.generate(
                                  7,
                                  (index) => _OTPBox(
                                    index: index,
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    onChanged: (v) => _onOtpChanged(index, v),
                                    onPaste: index == 0 ? _onPaste : null,
                                    boxWidth: boxWidth,
                                    boxHeight: boxHeight,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        _EmailInfoCard(email: widget.email),
                        const SizedBox(height: 12),

                        if (_attemptsRemaining < 5)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _isLocked
                                  ? 'Too many failed attempts. Account temporarily locked.'
                                  : '$_attemptsRemaining attempt${_attemptsRemaining != 1 ? 's' : ''} remaining',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _isLocked ? AppColors.error : AppColors.textSecondaryOf(context),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),

                        _TimerModule(
                          secondsRemaining: _secondsRemaining,
                          onResend: _resendOtp,
                        ),
                        const SizedBox(height: 20),

                        _SecurityNotice(),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _verifyOtp,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: AppColors.textInverse,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Icon(
                                    Icons.verified_user_rounded,
                                    size: 22,
                                  ),
                            label: Text(
                              _isLoading
                                  ? 'VERIFYING...'
                                  : 'AUTHORIZE & CONTINUE',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textInverse,
                              elevation: 10,
                              shadowColor: AppColors.primary.withValues(
                                alpha: 0.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 14,
                              color: AppColors.textTertiaryOf(context),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '256-BIT ENCRYPTED CLINICAL AUTHENTICATION',
                              style: TextStyle(
                                color: AppColors.textTertiaryOf(context),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimaryOf(context),
                size: 20,
              ),
            ),
          ),
          if (widget.isEmergency) _EmergencyBadge(),
        ],
      ),
    );
  }

  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0) return;

    setState(() => _isLoading = true);
    try {
      if (widget.isSignup) {
        await supabase.auth.resend(type: OtpType.signup, email: widget.email);
      } else {
        await supabase.auth.signInWithOtp(
          email: widget.email,
          shouldCreateUser: false,
        );
      }
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A new verification code has been sent'),
          ),
        );
      }
    } on AuthException catch (e, stackTrace) {
      logHandledError('OTP resend failed', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                e,
                fallback:
                    'We could not resend the code. Please wait a moment and try again.',
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _EmailInfoCard extends StatelessWidget {
  final String email;
  const _EmailInfoCard({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              email,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryOf(context),
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'EDIT',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.errorLightOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.errorLight),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'SECURITY PROTOCOL: Do not disclose this clinical access code to any third party.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OTPBox extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final Function(String)? onPaste;
  final double boxWidth;
  final double boxHeight;

  const _OTPBox({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onPaste,
    this.boxWidth = 36,
    this.boxHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    final hasFocus = focusNode.hasFocus;
    final hasValue = controller.text.isNotEmpty;
    return GestureDetector(
      onLongPress: index == 0 && onPaste != null
          ? () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text != null && data!.text!.isNotEmpty) {
                onPaste!(data.text!);
              }
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: boxWidth,
        height: boxHeight,
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFocus
                ? AppColors.primary
                : hasValue
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.slate300,
            width: hasFocus ? 2.5 : 2,
          ),
          boxShadow: hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: TextStyle(
              fontSize: boxWidth * 0.67,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
              hintText: '•',
              hintStyle: TextStyle(color: AppColors.textTertiaryOf(context)),
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _TimerModule extends StatelessWidget {
  final int secondsRemaining;
  final VoidCallback onResend;
  const _TimerModule({required this.secondsRemaining, required this.onResend});

  @override
  Widget build(BuildContext context) {
    final canResend = secondsRemaining == 0;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceAltOf(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_rounded,
                size: 16,
                color: secondsRemaining < 10
                    ? AppColors.error
                    : AppColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 8),
              Text(
                'EXPIRES IN: ${'${secondsRemaining ~/ 60}'.padLeft(2, '0')}:${'${secondsRemaining % 60}'.padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: secondsRemaining < 10
                      ? AppColors.error
                      : AppColors.textPrimaryOf(context),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MISSING THE DISPATCH?',
              style: TextStyle(
                color: AppColors.textSecondaryOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: canResend ? onResend : null,
              child: Text(
                'RESEND CODE',
                style: TextStyle(
                  color: canResend
                      ? AppColors.primary
                      : AppColors.textTertiaryOf(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmergencyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.errorLightOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorLight),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Text(
            'PRIORITY CARE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.error,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeshCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _MeshCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)],
      ),
    );
  }
}
