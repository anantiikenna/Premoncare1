import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_locator.dart';
import '../../core/user_facing_errors.dart';

class AccountConversionScreen extends StatefulWidget {
  const AccountConversionScreen({super.key});

  @override
  State<AccountConversionScreen> createState() => _AccountConversionScreenState();
}

class _AccountConversionScreenState extends State<AccountConversionScreen> {
  int _currentStep = 1;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  int _resendSeconds = 60;
  String? _conversionEmail;
  Timer? _resendTimer;

  // Controllers & Form States
  final List<TextEditingController> _otpControllers = List.generate(8, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(8, (index) => FocusNode());
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendSeconds > 0) {
            _resendSeconds--;
          } else {
            _resendTimer?.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSendingOtp = true);
    try {
      await supabase.auth.signInWithOtp(email: email);
      _conversionEmail = email;
      if (mounted) {
        setState(() => _currentStep = 3);
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent to $email'), backgroundColor: const Color(0xFF10B981)),
        );
      }
    } catch (e, st) {
      logHandledError('Send OTP failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(e, fallback: 'Failed to send OTP. Please try again.')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
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
    setState(() => _isVerifyingOtp = true);
    try {
      await supabase.auth.verifyOTP(
        email: _conversionEmail ?? _emailController.text.trim(),
        token: otp,
        type: OtpType.email,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully'), backgroundColor: Color(0xFF10B981)),
        );
        _nextStep();
      }
    } on AuthException catch (e, st) {
      logHandledError('OTP verify failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(e, fallback: 'Invalid code. Please try again.')), backgroundColor: Colors.red),
        );
      }
    } catch (e, st) {
      logHandledError('OTP verify failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification failed. Please try again.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  List<TextEditingController> get _controllers => _otpControllers;

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 7) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 20),
              onPressed: () {
                if (_currentStep > 1) {
                  _prevStep();
                } else {
                  context.pop();
                }
              },
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF0F62FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.healing_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            const Text(
              'Premon Care',
              style: TextStyle(
                color: Color(0xFF0F62FE),
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)),
                onPressed: () => context.push('/notifications'),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: const Text(
                    '8',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 8),
            child: Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF0F62FE),
                    child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Title & Subtitle + Illustration Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentStep == 2 
                              ? 'Verify Your Number' 
                              : (_currentStep == 3 
                                  ? 'Create Your Profile' 
                                  : (_currentStep == 4 ? 'Account Created\nSuccessfully!' : 'Emergency Guest\nConversion Flow')),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            height: 1.2,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentStep == 2 
                              ? 'Verify your phone number to continue and secure your emergency care.'
                              : (_currentStep == 3 
                                  ? 'Tell us a bit about yourself to personalize your healthcare experience.'
                                  : (_currentStep == 4 
                                      ? 'Welcome to Premon Care. You can now access all features, track your health and manage your care.'
                                      : 'Convert emergency guest users to verified accounts for continuity of care and better support.')),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_currentStep == 2) 
                    const _VerifyIllustration() 
                  else if (_currentStep == 3) 
                    const _ProfileIllustration() 
                  else if (_currentStep == 4)
                    const _CompleteIllustration()
                  else 
                    const _HeroIllustration(),
                ],
              ),
              const SizedBox(height: 32),

              // 4-Step Stepper
              _ConversionStepper(currentStep: _currentStep),
              const SizedBox(height: 32),

              // Animated Transition Container for Steps
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: _buildStepContent(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Start();
      case 2:
        return _buildStep2Verify();
      case 3:
        return _buildStep3Profile();
      case 4:
        return _buildStep4Complete();
      default:
        return _buildStep1Start();
    }
  }

  // STEP 1: START
  Widget _buildStep1Start() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF3B82F6), size: 30),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '!',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Guest Emergency Session\nDetected',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This user accessed emergency care as a guest.\nComplete a few quick steps to create an account.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session ID',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'EMG-2025-0518-7821',
                      style: TextStyle(color: Color(0xFF1E293B), fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Access Time',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '18 May 2025, 10:24 AM',
                      style: TextStyle(color: Color(0xFF1E293B), fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Reason',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Critical Condition',
                        style: TextStyle(color: Color(0xFFEF4444), fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: _FeatureColumn(
                  icon: Icons.favorite_rounded,
                  color: Color(0xFF3B82F6),
                  title: 'Continue Care',
                  description: 'Access your medical history anytime',
                ),
              ),
              Container(width: 1, height: 60, color: const Color(0xFFE2E8F0)),
              const Expanded(
                child: _FeatureColumn(
                  icon: Icons.lock_rounded,
                  color: Color(0xFF10B981),
                  title: 'Secure & Private',
                  description: 'Your data is encrypted and protected',
                ),
              ),
              Container(width: 1, height: 60, color: const Color(0xFFE2E8F0)),
              const Expanded(
                child: _FeatureColumn(
                  icon: Icons.history_rounded,
                  color: Color(0xFF8B5CF6),
                  title: 'Faster Next Time',
                  description: 'Skip long forms and get help quicker',
                ),
              ),
              Container(width: 1, height: 60, color: const Color(0xFFE2E8F0)),
              const Expanded(
                child: _FeatureColumn(
                  icon: Icons.headset_mic_rounded,
                  color: Color(0xFFF59E0B),
                  title: 'Better Support',
                  description: 'We can support you more efficiently',
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F62FE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 20),
                  Text(
                    'Continue to Create Account',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2),
                  ),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: VERIFY (Matching design exactly)
  Widget _buildStep2Verify() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Green Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Session Completed Successfully',
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Continue creating your secure healthcare account to get the best care experience.',
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Phone Number Row Box
        const Text(
          'Phone Number',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Image.network(
                'https://flagcdn.com/w40/ng.png',
                width: 24,
                height: 16,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 24),
              ),
              const SizedBox(width: 8),
              const Text(
                '+234',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 16),
              const SizedBox(width: 12),
              Container(width: 1, height: 20, color: const Color(0xFFCBD5E1)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Check your email for the verification code',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Enter Verification Code Title
        const Text(
          'Enter Verification Code',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // 8 OTP Box Inputs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(8, (index) {
            final isActive = _otpFocusNodes[index].hasFocus;

            return Container(
              width: 38,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? const Color(0xFF0F62FE) : const Color(0xFFE2E8F0),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Center(
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '',
                  ),
                  onChanged: (v) => _onOtpChanged(index, v),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Resend Timer Row
        Center(
          child: Column(
            children: [
              Text(
                _resendSeconds > 0
                    ? 'Resend code in ${(_resendSeconds ~/ 60).toString().padLeft(2, '0')}:${(_resendSeconds % 60).toString().padLeft(2, '0')}'
                    : 'Code expired',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Didn\'t receive code? ', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _resendSeconds > 0 ? null : _sendOtp,
                    child: Text(
                      'Resend Code',
                      style: TextStyle(
                        color: _resendSeconds > 0 ? const Color(0xFF94A3B8) : const Color(0xFF0F62FE),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Why verify your number section
        const Text(
          'Why verify your number?',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _VerifyBenefitColumn(
                icon: Icons.local_hospital_rounded,
                color: Color(0xFF10B981),
                title: 'Continue Care',
                description: 'Access your emergency consultation history.',
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: _VerifyBenefitColumn(
                icon: Icons.notifications_rounded,
                color: Color(0xFF8B5CF6),
                title: 'Follow-up Updates',
                description: 'Receive doctor updates and appointment alerts.',
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: _VerifyBenefitColumn(
                icon: Icons.security_rounded,
                color: Color(0xFF3B82F6),
                title: 'Secure Records',
                description: 'Protect your medical information.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Verify & Continue Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSendingOtp || _isVerifyingOtp ? null : (_currentStep == 2 ? _sendOtp : _verifyOtp),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSendingOtp || _isVerifyingOtp
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 2 ? 'Send Verification Code' : 'Verify & Continue',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Skip Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _nextStep,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F62FE),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Skip For Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),

        // Warning Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFEF3C7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                child: const Icon(Icons.priority_high_rounded, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Skipping verification may limit access to your consultation records and future healthcare services.',
                  style: TextStyle(color: Color(0xFF92400E), fontSize: 11, fontWeight: FontWeight.bold, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Privacy note
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shield_outlined, color: Color(0xFF64748B), size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your information is encrypted and protected under healthcare privacy standards.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 3: CREATE PROFILE (Matching Step 3 Mockup exactly)
  Widget _buildStep3Profile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Blue Info Alert Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You’re almost there!',
                      style: TextStyle(
                        color: Color(0xFF1E40AF),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Just a few more details to create your secure account.',
                      style: TextStyle(
                        color: Color(0xFF1E40AF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Main Personal Information Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Full Name
              const Text('Full Name', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
              const SizedBox(height: 16),

              // Date of Birth & Gender Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date of Birth', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _dobController,
                          readOnly: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gender', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          items: const [
                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedGender = v);
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 16),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email Address
              const Text('Email Address (Optional)', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'We\'ll use this for important updates and notifications.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),

              // Location Section
              const Text(
                'Location',
                style: TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // City
              const Text('City', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),
              const SizedBox(height: 16),

              // Emergency Contact (Optional)
              const Text('Emergency Contact (Optional)', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('+234', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _emergencyPhoneController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Health data protected banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your health data is protected',
                            style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'We use advanced encryption to keep your information safe and private.',
                            style: TextStyle(color: Color(0xFF065F46), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Continue Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continue', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Skip/Do this later button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _nextStep,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F62FE),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('I\'ll Do This Later', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),

        // Bottom privacy note
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 14),
            SizedBox(width: 6),
            Text(
              'You can update this information anytime in your profile settings.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 4: COMPLETE (Matching Step 4 Mockup exactly!)
  Widget _buildStep4Complete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Your Account is Ready Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD1FAE5), width: 1.5), // green outline
            boxShadow: [
              BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 14),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Your Account is Ready',
                          style: TextStyle(color: Color(0xFF065F46), fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Phone row
                    _buildAccountSummaryItem(
                      icon: Icons.phone_outlined,
                      label: 'Phone Number',
                      value: _phoneController.text.isNotEmpty ? _phoneController.text : 'Not provided',
                      tagText: 'Verified',
                    ),
                    const SizedBox(height: 16),

                    // Email row
                    _buildAccountSummaryItem(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email Address',
                      value: _emailController.text.isNotEmpty ? _emailController.text : 'Not provided',
                      tagText: 'Added',
                    ),
                    const SizedBox(height: 16),

                    // Location row
                    _buildAccountSummaryItem(
                      icon: Icons.location_on_outlined,
                      label: 'Full Name',
                      value: _nameController.text.isNotEmpty ? _nameController.text : 'Not provided',
                      tagText: 'Saved',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right side shield column
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 65,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.security_rounded, color: Color(0xFF3B82F6), size: 36),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your information is\nsecure and encrypted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // What you can do next Section
        const Text(
          'What you can do next',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: _NextActionCard(
                icon: Icons.folder_shared_outlined,
                color: Color(0xFF10B981),
                title: 'View Health\nRecords',
                description: 'Access your emergency consultation and health history.',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _NextActionCard(
                icon: Icons.calendar_today_outlined,
                color: Color(0xFF8B5CF6),
                title: 'Book\nAppointments',
                description: 'Schedule consultations with trusted doctors.',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _NextActionCard(
                icon: Icons.notifications_none_rounded,
                color: Color(0xFFF59E0B),
                title: 'Get Health\nReminders',
                description: 'Receive medication reminders and follow-ups.',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _NextActionCard(
                icon: Icons.chat_bubble_outline_rounded,
                color: Color(0xFF3B82F6),
                title: 'Chat with\nDoctors',
                description: 'Connect with doctors anytime for follow-up care.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Your Health Matters Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFF0F62FE), shape: BoxShape.circle),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Health Matters',
                      style: TextStyle(color: Color(0xFF0F62FE), fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'We\'re here to support you on your health journey. Thank you for choosing Premon Care.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Hand heart small icon
              const Icon(Icons.healing_rounded, color: Color(0xFFBFDBFE), size: 36),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Go to Dashboard Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/patient_dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Go to Dashboard', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // View My Health Record Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.push('/vault'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F62FE),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('View My Health Record', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),

        // Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shield_outlined, color: Color(0xFF64748B), size: 16),
            SizedBox(width: 8),
            Text(
              'Your health. Your data. Always protected.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required String tagText,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: '$label:  '),
                TextSpan(text: value, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tagText,
            style: const TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 55,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: const Icon(Icons.add_moderator_rounded, color: Color(0xFF0F62FE), size: 28),
            ),
          ),
          Positioned(
            right: 15,
            top: 0,
            child: Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 16,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(width: 32, height: 3, decoration: BoxDecoration(color: const Color(0xFF0F62FE).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(1.5))),
                  const SizedBox(height: 4),
                  Container(width: 20, height: 3, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(1.5))),
                  const SizedBox(height: 4),
                  Container(width: 26, height: 3, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(1.5))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                        child: const Icon(Icons.person_rounded, size: 8, color: Color(0xFF0F62FE)),
                      ),
                      const SizedBox(width: 4),
                      Container(width: 12, height: 2, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(1))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF10B981), size: 16),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyIllustration extends StatelessWidget {
  const _VerifyIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 15,
            top: 0,
            child: Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Container(width: 12, height: 3, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(1.5))),
                  const Spacer(),
                  Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(1))),
                  const SizedBox(height: 3),
                ],
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 15,
            child: Container(
              width: 38,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0F62FE),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0F62FE).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
            ),
          ),
          Positioned(
            right: 0,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '****',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 5,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF3B82F6), size: 14),
                ),
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIllustration extends StatelessWidget {
  const _ProfileIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 10,
            top: 5,
            child: Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF3B82F6)),
                  ),
                  const SizedBox(height: 8),
                  Container(width: 32, height: 3, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(1.5))),
                  const SizedBox(height: 4),
                  Container(width: 24, height: 3, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(1.5))),
                  const SizedBox(height: 4),
                  Container(width: 28, height: 3, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(1.5))),
                ],
              ),
            ),
          ),
          Positioned(
            left: 25,
            top: 0,
            child: Container(
              width: 20,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF94A3B8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            right: 15,
            bottom: 10,
            child: Container(
              width: 34,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteIllustration extends StatelessWidget {
  const _CompleteIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
          ),
          Positioned(
            left: 10, top: 10,
            child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
          ),
          Positioned(
            right: 15, top: 5,
            child: Container(width: 6, height: 10, decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(2))),
          ),
          Positioned(
            left: 15, bottom: 15,
            child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
          ),
          Positioned(
            right: 10, bottom: 20,
            child: Container(width: 8, height: 4, decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(1))),
          ),
        ],
      ),
    );
  }
}

class _ConversionStepper extends StatelessWidget {
  final int currentStep;
  const _ConversionStepper({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData(label: 'Completed'),
      _StepData(label: 'Verified'),
      _StepData(label: 'Profile'),
      _StepData(label: 'Complete'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final stepNum = index + 1;
        final isActive = stepNum == currentStep;
        final isCompleted = stepNum < currentStep;

        final bubbleColor = isCompleted 
            ? const Color(0xFF10B981) 
            : (isActive ? const Color(0xFF0F62FE) : Colors.white);
            
        final iconColor = (isActive || isCompleted) ? Colors.white : const Color(0xFF64748B);
        
        final textColor = isCompleted 
            ? const Color(0xFF10B981) 
            : (isActive ? const Color(0xFF0F62FE) : const Color(0xFF64748B));

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted 
                              ? const Color(0xFF10B981) 
                              : (isActive ? const Color(0xFF0F62FE) : const Color(0xFFE2E8F0)),
                          width: 2,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0F62FE).withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                            : Text(
                                '$stepNum',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: iconColor,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index].label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Container(
                  width: 24,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 24),
                  color: (index + 1) < currentStep ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _StepData {
  final String label;
  const _StepData({required this.label});
}

class _FeatureColumn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureColumn({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _VerifyBenefitColumn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _VerifyBenefitColumn({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _NextActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _NextActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 8, color: Color(0xFF64748B), height: 1.4, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
