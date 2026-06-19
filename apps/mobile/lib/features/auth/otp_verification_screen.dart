import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_locator.dart';
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
  final List<TextEditingController> _controllers = List.generate(8, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(8, (index) => FocusNode());
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus first box after frame renders
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
    _secondsRemaining = 30;
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
    if (value.isNotEmpty && index < 7) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-submit when all 8 digits are filled
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 8) {
      _verifyOtp();
    }
  }

  void _onPaste(String pasted) {
    final digits = pasted.replaceAll(RegExp(r'[^0-9]'), '').split('');
    for (var i = 0; i < 8 && i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }
    // Focus last filled box or last box
    final lastFilled = digits.length.clamp(0, 7);
    _focusNodes[lastFilled].requestFocus();
    // Auto-submit if all 8 pasted
    if (digits.length >= 8) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 8-digit code')),
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
      if (mounted) {
        // Let the router's redirect handle role-based navigation
        context.go('/');
      }
    } on AuthException catch (e, stackTrace) {
      logHandledError('OTP verification failed', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFacingError(e, fallback: 'That code could not be verified. Please check it and try again.')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      logHandledError('OTP verification failed', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Immersive clinical mesh background
          Positioned(top: -150, right: -100, child: _MeshCircle(color: primaryColor.withValues(alpha: 0.1), size: 500)),
          Positioned(bottom: -100, left: -50, child: _MeshCircle(color: primaryColor.withValues(alpha: 0.05), size: 400)),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        const Text('IDENTITY VERIFICATION', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        const Text('Verify Your Email', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1.0)),
                        const SizedBox(height: 8),
                        const Text('An 8-digit clinical access code has been dispatched to your registered email address.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600, height: 1.5)),
                        const SizedBox(height: 32),

                        _EmailInfoCard(email: widget.email, primaryColor: primaryColor),
                        const SizedBox(height: 32),

                        _SecurityNotice(),
                        const SizedBox(height: 48),

                        // OTP Input Hub
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(8, (index) => _OTPBox(
                            index: index,
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            onChanged: (v) => _onOtpChanged(index, v),
                            onPaste: index == 0 ? _onPaste : null,
                            primaryColor: primaryColor,
                          )),
                        ),
                        const SizedBox(height: 48),

                        _TimerModule(secondsRemaining: _secondsRemaining, onResend: _resendOtp),
                        const SizedBox(height: 48),

                        _HelpModule(email: widget.email),
                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _verifyOtp,
                            icon: _isLoading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                : const Icon(Icons.verified_user_rounded, size: 22),
                            label: Text(
                              _isLoading ? 'VERIFYING...' : 'AUTHORIZE & CONTINUE',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 10,
                              shadowColor: primaryColor.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_rounded, size: 14, color: Color(0xFF94A3B8)),
                            SizedBox(width: 10),
                            Text('256-BIT ENCRYPTED CLINICAL AUTHENTICATION', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
            child: Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))), child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 20)),
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
        await supabase.auth.resend(
          type: OtpType.signup,
          email: widget.email,
        );
      } else {
        await supabase.auth.signInWithOtp(email: widget.email);
      }
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new verification code has been sent')),
        );
      }
    } on AuthException catch (e, stackTrace) {
      logHandledError('OTP resend failed', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(e, fallback: 'We could not resend the code. Please wait a moment and try again.')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _EmailInfoCard extends StatelessWidget {
  final String email;
  final Color primaryColor;
  const _EmailInfoCard({required this.email, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.mail_outline_rounded, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(email, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.3), overflow: TextOverflow.ellipsis),
          ),
          TextButton(onPressed: () => context.pop(), child: Text('EDIT', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5))),
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
      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFECACA))),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 12),
          const Expanded(child: Text('SECURITY PROTOCOL: Do not disclose this clinical access code to any third party.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C), height: 1.4))),
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
  final Color primaryColor;

  const _OTPBox({required this.index, required this.controller, required this.focusNode, required this.onChanged, required this.primaryColor, this.onPaste});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: index == 0 && onPaste != null
          ? () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text != null && data!.text!.isNotEmpty) {
                onPaste!(data.text!);
              }
            }
          : null,
      child: Container(
        width: 50,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: focusNode.hasFocus ? primaryColor : const Color(0xFFE2E8F0), width: 2),
          boxShadow: focusNode.hasFocus ? [BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Center(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            decoration: const InputDecoration(counterText: '', border: InputBorder.none, hintText: '•', hintStyle: TextStyle(color: Color(0xFFCBD5E1))),
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
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_rounded, size: 16, color: secondsRemaining < 10 ? const Color(0xFFEF4444) : const Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text('EXPIRES IN: 00:${secondsRemaining.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: secondsRemaining < 10 ? const Color(0xFFEF4444) : const Color(0xFF1E293B), letterSpacing: 0.5)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('MISSING THE DISPATCH?', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: canResend ? onResend : null,
              child: Text('RESEND CODE', style: TextStyle(color: canResend ? const Color(0xFF0F62FE) : const Color(0xFFCBD5E1), fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}

class _HelpModule extends StatelessWidget {
  final String email;
  const _HelpModule({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle), child: const Icon(Icons.support_agent_rounded, color: Color(0xFF64748B), size: 24)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NEED ASSISTANCE?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text('Ensure $email is correct or contact our clinical support infrastructure.', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
      child: const Row(
        children: [
          Icon(Icons.bolt_rounded, color: Color(0xFFEF4444), size: 16),
          SizedBox(width: 8),
          Text('PRIORITY CARE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFB91C1C), letterSpacing: 0.5)),
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
