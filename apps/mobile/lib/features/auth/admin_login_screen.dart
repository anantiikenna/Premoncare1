import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../core/user_facing_errors.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your admin email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('email', email)
          .maybeSingle();

      if (!mounted) return;

      if (profile == null) {
        setState(() {
          _errorMessage = 'No account found with this email. Please contact the platform administrator.';
          _isLoading = false;
        });
        return;
      }

      if (profile['role'] != 'admin') {
        setState(() {
          _errorMessage = 'Access denied. This account does not have admin privileges.';
          _isLoading = false;
        });
        return;
      }

      // Check rate limit before sending OTP (non-blocking if table doesn't exist)
      try {
        final limitResult = await supabase
            .rpc('check_otp_rate_limit', params: {'p_email': email});
        if (limitResult != null && limitResult['allowed'] == false) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Too many failed attempts. Please try again later.';
              _isLoading = false;
            });
          }
          return;
        }
      } catch (_) {
        // Rate limit table may not exist yet — proceed with OTP anyway
      }

      // Record the attempt (non-blocking)
      try {
        await supabase.rpc('record_otp_attempt', params: {'p_email': email});
      } catch (_) {}

      await supabase.auth.signInWithOtp(email: email, shouldCreateUser: false);
      if (mounted) {
        context.push(
          '/otp-verification',
          extra: {'email': email, 'isEmergency': false, 'isSignup': false},
        );
      }
    } catch (e, stackTrace) {
      logHandledError('Admin OTP send failed', e, stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = userFacingError(e, fallback: 'We could not send the verification code. Please try again.');
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(top: -120, right: -80, child: _DecorCircle(color: AppColors.primary.withValues(alpha: 0.07), size: 420)),
          Positioned(bottom: -80, left: -40, child: _DecorCircle(color: AppColors.primary.withValues(alpha: 0.04), size: 320)),

          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 32),

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.admin_panel_settings_rounded, size: 40, color: AppColors.primary),
                            ),
                            const SizedBox(height: 20),

                            Text(
                              'Premon Admin',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Administrative Access Portal',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryOf(context)),
                            ),
                            const SizedBox(height: 36),

                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.errorLightOf(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            _AdminInput(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              hint: 'Admin Email',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _sendOtp(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'We\'ll send a seven digit verification code to your email.',
                              style: TextStyle(
                                color: AppColors.textSecondaryOf(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 28),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textInverse,
                                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                                  elevation: 6,
                                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 2.5),
                                      )
                                    : const Text(
                                        'Send Admin Code',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 48),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield_rounded, size: 14, color: AppColors.textTertiaryOf(context)),
                                const SizedBox(width: 6),
                                Text(
                                  'SECURED ADMINISTRATIVE SESSION',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: AppColors.textTertiaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
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

class _AdminInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _AdminInput({
    required this.controller,
    this.focusNode,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimaryOf(context)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: Icon(icon, color: AppColors.textTertiaryOf(context), size: 19)),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _DecorCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 30)]),
    );
  }
}
