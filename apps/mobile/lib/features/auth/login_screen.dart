import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart' show supabase;
import '../../core/user_facing_errors.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loginWithOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterEmail)),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('email', email)
          .maybeSingle();

      if (!mounted) return;

      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.noAccountFound,
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (profile['role'] == 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.noAccountFound,
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Check rate limit before sending OTP (non-blocking if table doesn't exist)
      try {
        final limitResult = await supabase
            .rpc('check_otp_rate_limit', params: {'p_email': email});
        if (limitResult != null && limitResult['allowed'] == false) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Too many failed attempts. Please try again later.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      } catch (_) {}

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
      logHandledError('OTP send failed', e, stackTrace);
      final message = userFacingError(
        e,
        fallback: 'We could not send the verification code. Please try again.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$message\n(${e.toString().replaceAll('Exception: ', '')})',
            ),
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
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Image.asset(
                          'assets/logo.png',
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.health_and_safety_rounded,
                            size: 80,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.secureClinicalEcosystem,
                          style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),

                        _ClinicalInput(
                          controller: _emailController,
                          hint: AppLocalizations.of(context)!.clinicalEmailAddress,
                          icon: Icons.person_rounded,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.otpLoginDescription,
                          style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginWithOtp,
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
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: AppColors.textInverse,
                                    strokeWidth: 3,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.sendOtpCode,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        _SectionDivider(label: AppLocalizations.of(context)!.secureSocialSync),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: _SocialSyncCard(
                                icon: Icons.g_mobiledata_rounded,
                                label: AppLocalizations.of(context)!.google,
                                onTap: () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(context)!.googleSignInUnavailable,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SocialSyncCard(
                                icon: Icons.apple_rounded,
                                label: AppLocalizations.of(context)!.apple,
                                onTap: () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(context)!.appleSignInUnavailable,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.noClinicalAccount,
                              style: TextStyle(
                                color: AppColors.textSecondaryOf(context),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/register'),
                              child: Text(
                                AppLocalizations.of(context)!.createAccess,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        _EmergencyBanner(),

                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 16,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)!.hipaaCompliantAesEncrypted,
                              style: TextStyle(
                                color: AppColors.textTertiaryOf(context),
                                fontSize: 12,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/doctor-search?emergency=true'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.errorLightOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: AppColors.textInverse,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.emergencyAccess,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimaryOf(context),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.needUrgentCareSkipLogin,
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;

  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.borderOf(context))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textTertiaryOf(context),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.borderOf(context))),
      ],
    );
  }
}

class _ClinicalInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _ClinicalInput({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppColors.textPrimaryOf(context),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textTertiaryOf(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: AppColors.primary.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}

class _SocialSyncCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialSyncCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimaryOf(context), size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
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
