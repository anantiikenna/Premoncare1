import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      await NotificationService().syncToken();
      if (mounted) context.go('/');
    } catch (e, stackTrace) {
      logHandledError('Login failed', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(e, fallback: 'We could not sign you in. Please check your details and try again.')), backgroundColor: Colors.red),
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
          SnackBar(content: Text(userFacingError(e, fallback: 'We could not send the verification code. Please try again.')), backgroundColor: Colors.red),
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
                      // Brand Identity Hub
                      Image.asset(
                        'assets/logo.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      const Text('SECURE CLINICAL ECOSYSTEM', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(height: 36),

                      // Mode Switcher
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            _TabButton(label: 'EMAIL ACCESS', isSelected: _isEmailTab, onTap: () => setState(() => _isEmailTab = true), primaryColor: primaryColor),
                            _TabButton(label: 'SECURE OTP', isSelected: !_isEmailTab, onTap: () => setState(() => _isEmailTab = false), primaryColor: primaryColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _ClinicalInput(controller: _emailController, hint: _isEmailTab ? 'Clinical Email or Phone' : 'Clinical Email Address', icon: Icons.person_rounded, primaryColor: primaryColor),
                      const SizedBox(height: 16),
                      if (_isEmailTab) ...
                      [
                        _ClinicalInput(controller: _passwordController, hint: 'Access Password', icon: Icons.lock_rounded, isPassword: true, isPasswordVisible: _isPasswordVisible, onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible), primaryColor: primaryColor),
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.push('/forgot-password'), child: Text('FORGOT ACCESS KEY?', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)))),
                      ]
                      else ...
                      [
                        const SizedBox(height: 4),
                        Text(
                          'We\'ll send a one-time code to your email to log you in securely.',
                          style: TextStyle(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600, height: 1.5),
                        ),
                      ],

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : (_isEmailTab ? _login : _loginWithOtp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 10,
                            shadowColor: primaryColor.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_isEmailTab ? 'INITIATE SESSION' : 'SEND OTP CODE', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)), const SizedBox(width: 12), const Icon(Icons.arrow_forward_rounded, size: 20)]),
                        ),
                      ),

                      const SizedBox(height: 32),
                      _SectionDivider(label: 'SECURE SOCIAL SYNC'),
                      const SizedBox(height: 24),

                      Row(
                        children: [
      Expanded(child: _SocialSyncCard(icon: Icons.g_mobiledata_rounded, label: 'GOOGLE', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-In coming soon'))))),
                           const SizedBox(width: 16),
                           Expanded(child: _SocialSyncCard(icon: Icons.apple_rounded, label: 'APPLE', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Apple Sign-In coming soon'))))),
                        ],
                      ),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("NO CLINICAL ACCOUNT? ", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 12)),
                          GestureDetector(onTap: () => context.push('/register'), child: Text('CREATE ACCESS', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 12))),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Emergency access — compact banner at bottom
                      _EmergencyBanner(primaryColor: primaryColor),

                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 10),
                          const Text('HIPAA COMPLIANT & AES-256 ENCRYPTED', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
  final Color primaryColor;
  const _EmergencyBanner({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/doctor-search?emergency=true'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EMERGENCY ACCESS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.3)),
                  SizedBox(height: 2),
                  Text('Need urgent care? Skip login.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFEF4444)),
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
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1))),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;

  const _TabButton({required this.label, required this.isSelected, required this.onTap, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(14), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))] : []),
          child: Center(child: Text(label, style: TextStyle(color: isSelected ? primaryColor : const Color(0xFF64748B), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5))),
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
  final bool isPasswordVisible;
  final VoidCallback? onToggleVisibility;
  final Color primaryColor;

  const _ClinicalInput({required this.controller, required this.hint, required this.icon, this.isPassword = false, this.isPasswordVisible = false, this.onToggleVisibility, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w600),
          prefixIcon: Container(padding: const EdgeInsets.all(12), child: Icon(icon, color: primaryColor.withValues(alpha: 0.6), size: 20)),
          suffixIcon: isPassword ? IconButton(icon: Icon(isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8), size: 20), onPressed: onToggleVisibility) : null,
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1E293B), size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: Color(0xFF1E293B))),
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

