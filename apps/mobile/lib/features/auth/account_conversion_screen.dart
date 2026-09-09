import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../core/user_facing_errors.dart';
import '../../l10n/app_localizations.dart';

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

  final List<TextEditingController> _otpControllers = List.generate(7, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(7, (index) => FocusNode());
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _cityController = TextEditingController();
  String _selectedGender = '';

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
    _dobController.dispose();
    _cityController.dispose();
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
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterValidEmail), backgroundColor: AppColors.error),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.otpSentTo(email)), backgroundColor: AppColors.success),
        );
      }
    } catch (e, st) {
      logHandledError('Send OTP failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(e, fallback: AppLocalizations.of(context)!.failedToSendOtp)), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnter7DigitCode)),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.emailVerifiedSuccessfully), backgroundColor: AppColors.success),
        );
        _nextStep();
      }
    } on AuthException catch (e, st) {
      logHandledError('OTP verify failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(e, fallback: AppLocalizations.of(context)!.invalidCode)), backgroundColor: AppColors.error),
        );
      }
    } catch (e, st) {
      logHandledError('OTP verify failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.verificationFailed), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  List<TextEditingController> get _controllers => _otpControllers;

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 6) {
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
      // Link guest appointment when completing profile (step 3 → 4)
      if (_currentStep == 4) {
        _linkGuestAppointment();
      }
    }
  }

  Future<void> _linkGuestAppointment() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final prefs = await SharedPreferences.getInstance();
      final guestToken = prefs.getString('premon_guest_token');
      if (guestToken == null || guestToken.isEmpty) return;
      await supabase
          .from('appointments')
          .update({'patient_id': user.id})
          .eq('metadata->>guest_token', guestToken)
          .isFilter('patient_id', null);
    } catch (_) {}
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
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundOf(context),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context), size: 20),
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
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.healing_rounded, color: AppColors.textInverse, size: 14),
            ),
            const SizedBox(width: 8),
            const Text(
              'Premon Care',
              style: TextStyle(
                color: AppColors.primary,
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
                icon: Icon(Icons.notifications_outlined, color: AppColors.textSecondaryOf(context)),
                onPressed: () => context.push('/notifications'),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: const Text(
                    '8',
                    style: TextStyle(color: AppColors.textInverse, fontSize: 8, fontWeight: FontWeight.bold),
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
                    backgroundColor: AppColors.primary,
                    child: Text('S', style: TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.textInverse, width: 1.5),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentStep == 2 
                              ? AppLocalizations.of(context)!.verifyYourNumber 
                              : (_currentStep == 3 
                                  ? AppLocalizations.of(context)!.createYourProfile 
                                  : (_currentStep == 4 ? AppLocalizations.of(context)!.accountCreatedSuccessfully : AppLocalizations.of(context)!.emergencyGuestConversionFlow)),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimaryOf(context),
                            height: 1.2,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentStep == 2 
                              ? AppLocalizations.of(context)!.verifyPhoneNumberDescription
                              : (_currentStep == 3 
                                  ? AppLocalizations.of(context)!.tellUsAboutYourself
                                  : (_currentStep == 4 
                                      ? AppLocalizations.of(context)!.welcomeToPremonCare
                                      : AppLocalizations.of(context)!.convertGuestUsersDescription)),
                          style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
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
              _ConversionStepper(currentStep: _currentStep),
              const SizedBox(height: 32),
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

  Widget _buildStep1Start() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
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
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.person_rounded, color: AppColors.info, size: 30),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '!',
                        style: TextStyle(color: AppColors.textInverse, fontSize: 12, fontWeight: FontWeight.w900),
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
                    Text(
                      AppLocalizations.of(context)!.guestEmergencySessionDetected,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimaryOf(context),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.guestEmergencyDescription,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondaryOf(context),
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
                    Text(
                      AppLocalizations.of(context)!.sessionId,
                      style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'EMG-2025-0518-7821',
                      style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.accessTime,
                      style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '18 May 2025, 10:24 AM',
                      style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.reasonLabel,
                      style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.errorLightOf(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.criticalCondition,
                        style: TextStyle(color: AppColors.error, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: AppColors.borderOf(context), height: 1),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FeatureColumn(
                  icon: Icons.favorite_rounded,
                  color: AppColors.info,
                  title: AppLocalizations.of(context)!.continueCare,
                  description: AppLocalizations.of(context)!.accessMedicalHistory,
                ),
              ),
              Container(width: 1, height: 60, color: AppColors.borderOf(context)),
              Expanded(
                child: _FeatureColumn(
                  icon: Icons.lock_rounded,
                  color: AppColors.success,
                  title: AppLocalizations.of(context)!.secureAndPrivate,
                  description: AppLocalizations.of(context)!.dataEncryptedProtected,
                ),
              ),
              Container(width: 1, height: 60, color: AppColors.borderOf(context)),
              Expanded(
                child: _FeatureColumn(
                  icon: Icons.history_rounded,
                  color: AppColors.primary,
                  title: AppLocalizations.of(context)!.fasterNextTime,
                  description: AppLocalizations.of(context)!.skipLongForms,
                ),
              ),
              Container(width: 1, height: 60, color: AppColors.borderOf(context)),
              Expanded(
                child: _FeatureColumn(
                  icon: Icons.headset_mic_rounded,
                  color: AppColors.warning,
                  title: AppLocalizations.of(context)!.betterSupport,
                  description: AppLocalizations.of(context)!.supportEfficiently,
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
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 20),
                  Text(
                    AppLocalizations.of(context)!.continueToCreateAccount,
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

  Widget _buildStep2Verify() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.successLightOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.successLightOf(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: AppColors.textInverse, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.emergencySessionCompleted,
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.continueCreatingAccount,
                      style: TextStyle(
                        color: AppColors.success,
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
        Text(
          'Phone Number',
          style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderOf(context)),
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
              Text(
                '+234',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context)),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondaryOf(context), size: 16),
              const SizedBox(width: 12),
              Container(width: 1, height: 20, color: AppColors.borderOf(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.checkEmailVerificationCode,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryOf(context)),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.successLightOf(context), shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, color: AppColors.success, size: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.enterVerificationCode,
          style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final spacing = 6.0;
              final boxWidth = ((availableWidth - (spacing * 6)) / 7).floorToDouble().clamp(34.0, 54.0);
              final boxHeight = (boxWidth * 1.35).floorToDouble();
              return Wrap(
                spacing: spacing,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: List.generate(7, (index) {
                  final isActive = _otpFocusNodes[index].hasFocus;
                  return Container(
                    width: boxWidth,
                    height: boxHeight,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.borderOf(context),
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
                        style: TextStyle(fontSize: boxWidth * 0.53, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context)),
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
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Text(
                _resendSeconds > 0
                    ? 'Resend code in ${(_resendSeconds ~/ 60).toString().padLeft(2, '0')}:${(_resendSeconds % 60).toString().padLeft(2, '0')}'
                    : AppLocalizations.of(context)!.codeExpired,
                style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${AppLocalizations.of(context)!.didntReceiveCode} ', style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12, fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _resendSeconds > 0 ? null : _sendOtp,
                    child: Text(
                      'Resend Code',
                      style: TextStyle(
                        color: _resendSeconds > 0 ? AppColors.textTertiaryOf(context) : AppColors.primary,
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
        Text(
          AppLocalizations.of(context)!.whyVerifyNumber,
          style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _VerifyBenefitColumn(
                icon: Icons.local_hospital_rounded,
                color: AppColors.success,
                title: AppLocalizations.of(context)!.continueCare,
                description: AppLocalizations.of(context)!.continueCareDescription,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _VerifyBenefitColumn(
                icon: Icons.notifications_rounded,
                color: AppColors.primary,
                title: AppLocalizations.of(context)!.followUpUpdates,
                description: AppLocalizations.of(context)!.receiveDoctorUpdates,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _VerifyBenefitColumn(
                icon: Icons.security_rounded,
                color: AppColors.info,
                title: AppLocalizations.of(context)!.secureRecords,
                description: AppLocalizations.of(context)!.protectMedicalInfo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSendingOtp || _isVerifyingOtp ? null : (_currentStep == 2 ? _sendOtp : _verifyOtp),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSendingOtp || _isVerifyingOtp
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 2 ? AppLocalizations.of(context)!.sendVerificationCode : AppLocalizations.of(context)!.verifyAndContinue,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _nextStep,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.borderOf(context)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(AppLocalizations.of(context)!.skipForNow, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warningLightOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warningLightOf(context)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                child: Icon(Icons.priority_high_rounded, color: AppColors.textInverse, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.skippingVerificationWarning,
                  style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, color: AppColors.textSecondaryOf(context), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.informationEncryptedProtected,
                style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Profile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.infoLightOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.infoLightOf(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.info,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline_rounded, color: AppColors.textInverse, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.almostThere,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.fewMoreDetails,
                      style: TextStyle(
                        color: AppColors.primary,
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
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.personalInformation,
                style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.fullName, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderOf(context))),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.dateOfBirth, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _dobController,
                          readOnly: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderOf(context))),
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
                        Text(AppLocalizations.of(context)!.gender, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender.isEmpty ? null : _selectedGender,
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderOf(context))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.emailAddressOptional, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderOf(context))),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.importantUpdatesDescription,
                style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.locationLabel,
                style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.city, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderOf(context))),
                ),
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.emergencyContactOptional, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundOf(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('+234', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context))),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderOf(context))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successLightOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.successLightOf(context)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_rounded, color: AppColors.success, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.yourHealthDataProtected,
                            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(context)!.advancedEncryptionDescription,
                            style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold),
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.continueLabel, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _nextStep,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.borderOf(context)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(AppLocalizations.of(context)!.iIllDoThisLater, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, color: AppColors.textSecondaryOf(context), size: 14),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context)!.youCanUpdateLater,
              style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4Complete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.successLightOf(context), width: 1.5),
            boxShadow: [
              BoxShadow(color: AppColors.success.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 8)),
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
                          decoration: BoxDecoration(color: AppColors.successLightOf(context), shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded, color: AppColors.success, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.yourAccountIsReady,
                          style: TextStyle(color: AppColors.success, fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildAccountSummaryItem(
                      icon: Icons.phone_outlined,
                      label: AppLocalizations.of(context)!.phoneLabel,
                      value: _phoneController.text.isNotEmpty ? _phoneController.text : AppLocalizations.of(context)!.notProvided,
                      tagText: AppLocalizations.of(context)!.verifiedLabelCustom,
                    ),
                    const SizedBox(height: 16),
                    _buildAccountSummaryItem(
                      icon: Icons.mail_outline_rounded,
                      label: AppLocalizations.of(context)!.emailLabel,
                      value: _emailController.text.isNotEmpty ? _emailController.text : AppLocalizations.of(context)!.notProvided,
                      tagText: AppLocalizations.of(context)!.addedLabel,
                    ),
                    const SizedBox(height: 16),
                    _buildAccountSummaryItem(
                      icon: Icons.location_on_outlined,
                      label: AppLocalizations.of(context)!.fullNameLabel,
                      value: _nameController.text.isNotEmpty ? _nameController.text : AppLocalizations.of(context)!.notProvided,
                      tagText: AppLocalizations.of(context)!.savedLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 65,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.infoLightOf(context),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(color: AppColors.info.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Icon(Icons.security_rounded, color: AppColors.info, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.informationSecureEncryptedSmall,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 9, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          AppLocalizations.of(context)!.whatYouCanDoNext,
          style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NextActionCard(
                icon: Icons.folder_shared_outlined,
                color: AppColors.success,
                title: AppLocalizations.of(context)!.viewHealthRecords,
                description: AppLocalizations.of(context)!.viewHealthRecordsDescription,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _NextActionCard(
                icon: Icons.calendar_today_outlined,
                color: AppColors.primary,
                title: AppLocalizations.of(context)!.bookAppointments,
                description: AppLocalizations.of(context)!.bookAppointmentsDescription,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _NextActionCard(
                icon: Icons.notifications_none_rounded,
                color: AppColors.warning,
                title: AppLocalizations.of(context)!.getHealthReminders,
                description: AppLocalizations.of(context)!.getHealthRemindersDescription,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _NextActionCard(
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.info,
                title: AppLocalizations.of(context)!.chatWithDoctors,
                description: AppLocalizations.of(context)!.chatWithDoctorsDescription,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.infoLightOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.infoLightOf(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.favorite_rounded, color: AppColors.textInverse, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.yourHealthMatters,
                      style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.healthJourneySupportMessage,
                      style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.bold, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.healing_rounded, color: AppColors.infoLightOf(context), size: 36),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/patient_dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.backToDashboard, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.push('/vault'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.borderOf(context)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(AppLocalizations.of(context)!.viewMyHealthRecord, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, color: AppColors.textSecondaryOf(context), size: 16),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.healthDataAlwaysProtected,
              style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.bold),
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
        Icon(icon, size: 16, color: AppColors.textSecondaryOf(context)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: '$label:  '),
                TextSpan(text: value, style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.successLightOf(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tagText,
            style: TextStyle(color: AppColors.success, fontSize: 8, fontWeight: FontWeight.w900),
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Icon(Icons.add_moderator_rounded, color: AppColors.primary, size: 28),
            ),
          ),
          Positioned(
            right: 15,
            top: 0,
            child: Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderOf(context), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
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
                        color: AppColors.textTertiaryOf(context),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(width: 32, height: 3, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(1.5))),
                  const SizedBox(height: 4),
                  Container(width: 20, height: 3, decoration: BoxDecoration(color: AppColors.borderOf(context), borderRadius: BorderRadius.circular(1.5))),
                  const SizedBox(height: 4),
                  Container(width: 26, height: 3, decoration: BoxDecoration(color: AppColors.borderOf(context), borderRadius: BorderRadius.circular(1.5))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.person_rounded, size: 8, color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      Container(width: 12, height: 2, decoration: BoxDecoration(color: AppColors.borderOf(context), borderRadius: BorderRadius.circular(1))),
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
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textInverse, width: 2),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.success, size: 16),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: AppColors.textInverse, size: 7),
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
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderOf(context), width: 1.5),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Container(width: 12, height: 3, decoration: BoxDecoration(color: AppColors.borderOf(context), borderRadius: BorderRadius.circular(1.5))),
                  const Spacer(),
                  Container(width: 18, height: 2, decoration: BoxDecoration(color: AppColors.borderOf(context), borderRadius: BorderRadius.circular(1))),
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
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.shield_rounded, color: AppColors.textInverse, size: 20),
            ),
          ),
          Positioned(
            right: 0,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: const BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: const Text(
                '****',
                style: TextStyle(color: AppColors.textInverse, fontSize: 10, fontWeight: FontWeight.bold),
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
                    color: AppColors.infoLightOf(context),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.textInverse, width: 1.5),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.info, size: 14),
                ),
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: AppColors.textInverse, size: 6),
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
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderOf(context), width: 1.5),
                boxShadow: [
                  BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.infoLightOf(context), shape: BoxShape.circle)),
                  const SizedBox(height: 8),
                  Container(width: 32, height: 3, decoration: BoxDecoration(color: AppColors.borderOf(context), borderRadius: BorderRadius.circular(1.5))),
                  const SizedBox(height: 4),
                  Container(width: 24, height: 3, decoration: BoxDecoration(color: AppColors.borderOf(context), borderRadius: BorderRadius.circular(1.5))),
                  const SizedBox(height: 4),
                  Container(width: 28, height: 3, decoration: BoxDecoration(color: AppColors.borderOf(context), borderRadius: BorderRadius.circular(1.5))),
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
                color: AppColors.textTertiaryOf(context),
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
                color: AppColors.info,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
                boxShadow: [
                  BoxShadow(color: AppColors.info.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3)),
                ],
              ),
              child: Icon(Icons.add, color: AppColors.textInverse, size: 18),
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
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(Icons.check_rounded, color: AppColors.textInverse, size: 30),
          ),
          Positioned(
            left: 10, top: 10,
            child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
          ),
          Positioned(
            right: 15, top: 5,
            child: Container(width: 6, height: 10, decoration: BoxDecoration(color: AppColors.info, borderRadius: BorderRadius.circular(2))),
          ),
          Positioned(
            left: 15, bottom: 15,
            child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
          ),
          Positioned(
            right: 10, bottom: 20,
            child: Container(width: 8, height: 4, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(1))),
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
            ? AppColors.success
            : (isActive ? AppColors.primary : AppColors.surfaceOf(context));
            
        final iconColor = (isActive || isCompleted) ? AppColors.textInverse : AppColors.textSecondaryOf(context);
        
        final textColor = isCompleted 
            ? AppColors.success
            : (isActive ? AppColors.primary : AppColors.textSecondaryOf(context));

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
                              ? AppColors.success
                              : (isActive ? AppColors.primary : AppColors.borderOf(context)),
                          width: 2,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, color: AppColors.textInverse, size: 20)
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
                  color: (index + 1) < currentStep ? AppColors.success : AppColors.borderOf(context),
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
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryOf(context),
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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 9, color: AppColors.textSecondaryOf(context), height: 1.3),
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
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLightOf(context)),
        boxShadow: [
          BoxShadow(color: AppColors.shadowLight, blurRadius: 10, offset: const Offset(0, 4)),
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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 8, color: AppColors.textSecondaryOf(context), height: 1.4, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
