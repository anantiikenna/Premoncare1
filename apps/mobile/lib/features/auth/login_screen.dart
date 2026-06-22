import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../core/services/notification_service.dart';
import '../../core/user_facing_errors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailTab = true;
  bool _isPasswordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 1.0, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic)));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your credentials')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());

      final role = await getUserRole();
      if (!mounted) return;

      if (role == 'admin') {
        await supabase.auth.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Admin accounts cannot access the patient/doctor app. Please use the Admin app.'), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      await NotificationService().syncToken();
      if (mounted) context.go('/');
    } catch (e, stackTrace) {
      logHandledError('Login failed', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(e, fallback: 'We could not sign you in. Please check your details and try again.')), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email address')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithOtp(email: email);
      if (mounted) {
        context.push('/otp-verification', extra: {
          'email': email,
          'isEmergency': false,
          'isSignup': false,
        });
      }
    } catch (e, stackTrace) {
      logHandledError('OTP send failed', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(e, fallback: 'We could not send the verification code. Please try again.')), backgroundColor: AppColors.error),
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
          Positioned(top: -150, right: -100, child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.1), size: 500)),
          Positioned(bottom: -100, left: -50, child: _MeshCircle(color: AppColors.primary.withValues(alpha: 0.05), size: 400)),

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
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.health_and_safety_rounded, size: 80, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text('SECURE CLINICAL ECOSYSTEM', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(height: 36),

                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.surfaceAltOf(context), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            _TabButton(label: 'EMAIL ACCESS', isSelected: _isEmailTab, onTap: () => setState(() => _isEmailTab = true)),
                            _TabButton(label: 'SECURE OTP', isSelected: !_isEmailTab, onTap: () => setState(() => _isEmailTab = false)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _ClinicalInput(controller: _emailController, hint: _isEmailTab ? 'Clinical Email or Phone' : 'Clinical Email Address', icon: Icons.person_rounded),
                      const SizedBox(height: 16),
                      if (_isEmailTab) ...
                      [
                        _ClinicalInput(
                          key: ValueKey('loginPassword_$_isPasswordVisible'),
                          controller: _passwordController,
                          hint: 'Access Password',
                          icon: Icons.lock_rounded,
                          isPassword: true,
                          obscureText: !_isPasswordVisible,
                          suffixIcon: Icon(
                            _isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: AppColors.textTertiaryOf(context),
                            size: 20,
                          ),
                          onSuffixTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.push('/forgot-password'), child: Text('FORGOT ACCESS KEY?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)))),
                      ]
                      else ...
                      [
                        const SizedBox(height: 4),
                        Text(
                          'We\'ll send a one-time code to your email to log you in securely.',
                          style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.w600, height: 1.5),
                        ),
                      ],

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : (_isEmailTab ? _login : _loginWithOtp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textInverse,
                            elevation: 10,
                            shadowColor: AppColors.primary.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: _isLoading ? const CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 3) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_isEmailTab ? 'INITIATE SESSION' : 'SEND OTP CODE', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)), const SizedBox(width: 12), const Icon(Icons.arrow_forward_rounded, size: 20)]),
                        ),
                      ),

                      const SizedBox(height: 32),
                      _SectionDivider(label: 'SECURE SOCIAL SYNC'),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(child: _SocialSyncCard(icon: Icons.g_mobiledata_rounded, label: 'GOOGLE', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-In will be available in the next update. Use email sign-in to continue.'))))),
                          const SizedBox(width: 16),
                          Expanded(child: _SocialSyncCard(icon: Icons.apple_rounded, label: 'APPLE', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Apple Sign-In will be available in the next update. Use email sign-in to continue.'))))),
                        ],
                      ),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("NO CLINICAL ACCOUNT? ", style: TextStyle(color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w800, fontSize: 12)),
                          GestureDetector(onTap: () => context.push('/register'), child: Text('CREATE ACCESS', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12))),
                        ],
                      ),

                      const SizedBox(height: 32),

                      _EmergencyBanner(),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user_rounded, size: 16, color: AppColors.success),
                          const SizedBox(width: 10),
                          Text('HIPAA COMPLIANT & AES-256 ENCRYPTED', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              child: Icon(Icons.bolt_rounded, color: AppColors.textInverse, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EMERGENCY ACCESS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Text('Need urgent care? Skip login.', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.error),
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
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(label, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1))),
        Expanded(child: Divider(color: AppColors.borderOf(context))),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? AppColors.surfaceOf(context) : Colors.transparent, borderRadius: BorderRadius.circular(14), boxShadow: isSelected ? [BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4))] : []),
          child: Center(child: Text(label, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textSecondaryOf(context), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5))),
        ),
      ),
    );
  }
}

class _ClinicalInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixTap;

  const _ClinicalInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderLightOf(context))),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        obscuringCharacter: '●',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimaryOf(context)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14, fontWeight: FontWeight.w600),
          prefixIcon: Container(padding: const EdgeInsets.all(12), child: Icon(icon, color: AppColors.primary.withValues(alpha: 0.6), size: 20)),
          suffixIcon: suffixIcon != null
              ? GestureDetector(onTap: onSuffixTap, child: Container(padding: const EdgeInsets.all(12), alignment: Alignment.center, child: suffixIcon))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
      ),
    );
  }
}

class _SocialSyncCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialSyncCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderLightOf(context))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimaryOf(context), size: 24),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: AppColors.textPrimaryOf(context))),
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
