import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../core/user_facing_errors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _submitted = false;

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score.clamp(0, 4);
  }

  String _getPasswordStrengthLabel(int strength) {
    switch (strength) {
      case 0: return '';
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Strong';
      default: return '';
    }
  }

  Color _getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0: return AppColors.border;
      case 1: return AppColors.error;
      case 2: return AppColors.warning;
      case 3: return AppColors.info;
      case 4: return AppColors.success;
      default: return AppColors.border;
    }
  }

  bool get _passwordsMatch {
    return _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
  }

  bool get _passwordsMismatch {
    return _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text;
  }

  void _nextPage() {
    setState(() => _submitted = true);

    if (_currentStep == 0) {
      if (_fullNameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
        return;
      }
      if (_passwordController.text.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 8 characters')));
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    } else if (_currentStep == 1) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to the Terms of Service')));
        return;
      }
      _register();
    }
  }

  void _previousPage() {
    _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _fullNameController.text.trim(),
          'requested_role': 'patient',
        }
      );

      if (res.user != null) {
        if (mounted) {
          context.push('/otp-verification', extra: {
            'email': _emailController.text.trim(),
            'role': 'patient',
            'isSignup': true,
          });
        }
      }
    } catch (e, stackTrace) {
      logHandledError('Registration failed', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(e, fallback: 'We could not complete registration. Please review your details and try again.')), backgroundColor: AppColors.error),
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
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) => setState(() => _currentStep = index),
                      children: [
                        _buildStepIdentity(context),
                        _buildStepTerms(context),
                      ],
                    ),
                  ),
                  _buildBottomBar(context),
                ],
              ),
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
            onTap: () => _currentStep > 0 ? _previousPage() : context.go('/onboarding'),
            child: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderOf(context))), child: Icon(_currentStep > 0 ? Icons.arrow_back_rounded : Icons.close_rounded, color: AppColors.textPrimaryOf(context), size: 20)),
          ),
          _buildStepIndicator(context),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IndicatorDot(isActive: _currentStep >= 0),
        Container(width: 30, height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: _currentStep >= 1 ? AppColors.primary : AppColors.borderOf(context), borderRadius: BorderRadius.circular(2))),
        _IndicatorDot(isActive: _currentStep >= 1),
      ],
    );
  }

  Widget _buildStepIdentity(BuildContext context) {
    final strength = _getPasswordStrength(_passwordController.text);
    final strengthLabel = _getPasswordStrengthLabel(strength);
    final strengthColor = _getPasswordStrengthColor(strength);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('CLINICAL IDENTITY', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text('Your Identity', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0)),
          const SizedBox(height: 8),
          Text('Join the Premoncare ecosystem and access\nworld-class clinical specialists.', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14, fontWeight: FontWeight.w600, height: 1.5)),
          const SizedBox(height: 40),

          _ClinicalInput(controller: _fullNameController, hint: 'Full Legal Name', icon: Icons.person_rounded),
          const SizedBox(height: 16),

          _ClinicalInput(controller: _emailController, hint: 'Clinical Email Address', icon: Icons.mail_rounded, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),

          Text('PASSWORD', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          _ClinicalInput(
            key: ValueKey('password_$_isPasswordVisible'),
            controller: _passwordController,
            hint: 'Create Password',
            icon: Icons.lock_rounded,
            isPassword: true,
            obscureText: !_isPasswordVisible,
            suffixIcon: Icon(_isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textTertiaryOf(context), size: 20),
            onSuffixTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            onChanged: (_) => setState(() {}),
          ),

          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: List.generate(4, (i) {
                      final isActive = strength > i;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: isActive ? strengthColor : AppColors.borderOf(context),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Text(strengthLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: strengthColor)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Min 8 characters. Use uppercase, numbers & symbols for a stronger password.', style: TextStyle(fontSize: 10, color: strength >= 3 ? AppColors.success : AppColors.textTertiaryOf(context), fontWeight: FontWeight.w600)),
          ],

          const SizedBox(height: 16),

          Text('CONFIRM PASSWORD', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          _ClinicalInput(
            key: ValueKey('confirmPassword_$_isConfirmPasswordVisible'),
            controller: _confirmPasswordController,
            hint: 'Re-enter Password',
            icon: Icons.verified_user_rounded,
            isPassword: true,
            obscureText: !_isConfirmPasswordVisible,
            suffixIcon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textTertiaryOf(context), size: 20),
            onSuffixTap: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            onChanged: (_) => setState(() {}),
            hasError: _passwordsMismatch && _submitted,
          ),

          if (_confirmPasswordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _passwordsMatch ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 16,
                  color: _passwordsMatch ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 6),
                Text(
                  _passwordsMatch ? 'Passwords match' : 'Passwords do not match',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _passwordsMatch ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStepTerms(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('LEGAL FRAMEWORK', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text('Our Terms', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0)),
          const SizedBox(height: 8),
          Text('Review our clinical commitments and data\nsecurity protocols before proceeding.', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14, fontWeight: FontWeight.w600, height: 1.5)),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.borderLightOf(context))),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TermItem('1. Terms & Clinical Quality', 'By using Premoncare, you agree to supply correct clinical histories and behave respectfully during telehealth appointments.'),
                SizedBox(height: 24),
                _TermItem('2. HIPAA Data Privacy', 'Your clinical records are AES-256 encrypted. We strictly follow HIPAA rules and never share medical data without explicit consent.'),
                SizedBox(height: 24),
                _TermItem('3. Reciprocal NDA Agreement', 'To safeguard diagnostic confidentiality, you enter into a binding reciprocal NDA. You agree not to record, screenshot, or distribute consultations or messages.'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Semantics(
            label: 'I acknowledge the Terms & Conditions, HIPAA Privacy Policy, and Non-Disclosure Agreement (NDA)',
            checked: _agreeToTerms,
            value: _agreeToTerms ? 'Agreed' : 'Not agreed',
            hint: 'Double tap to toggle agreement',
            child: GestureDetector(
              onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
              child: Row(
                children: [
                  Container(width: 24, height: 24, decoration: BoxDecoration(color: _agreeToTerms ? AppColors.primary : AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(8), border: Border.all(color: _agreeToTerms ? AppColors.primary : AppColors.borderOf(context))),                       child: _agreeToTerms ? Icon(Icons.check_rounded, color: AppColors.textInverse, size: 16) : null),
                  const SizedBox(width: 16),
                  Expanded(child: Text('I acknowledge the Terms & Conditions, HIPAA Privacy Policy, and Non-Disclosure Agreement (NDA)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context)))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 30, offset: const Offset(0, -10))]),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textInverse,
            elevation: 10,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: _isLoading ? const CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 3) : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_currentStep == 1 ? 'AUTHORIZE & FINALIZE' : 'CONTINUE', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermItem extends StatelessWidget {
  final String title;
  final String description;
  const _TermItem(this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimaryOf(context))),
        const SizedBox(height: 8),
        Text(description, style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context), height: 1.5, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  final bool isActive;
  const _IndicatorDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(width: 12, height: 12, decoration: BoxDecoration(color: isActive ? AppColors.primary : AppColors.borderOf(context), shape: BoxShape.circle, border: Border.all(color: isActive ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent, width: 4)));
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
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool hasError;

  const _ClinicalInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? AppColors.error : AppColors.borderLightOf(context);

    return Semantics(
      label: hint,
      textField: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: hasError ? 1.5 : 1),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
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
