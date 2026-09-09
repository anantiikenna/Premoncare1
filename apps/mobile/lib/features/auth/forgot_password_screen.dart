import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../core/user_facing_errors.dart';
import '../../l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterEmail)),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await supabase.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.resetLinkSentCheckInbox),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e, stackTrace) {
      logHandledError('Password reset request failed', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFacingError(e, fallback: AppLocalizations.of(context)!.couldNotSendResetLink)),
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
      backgroundColor: AppColors.surfaceOf(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context)),
                    onPressed: () => context.pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceOf(context),
                      side: BorderSide(color: AppColors.borderOf(context)),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const _EmergencyBadge(),
                ],
              ),
              const SizedBox(height: 32),

              Text(
                AppLocalizations.of(context)!.forgotPassword,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.forgotPasswordDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryOf(context),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),

              const Center(child: _ForgotIllustration()),
              const SizedBox(height: 40),

              Text(
                AppLocalizations.of(context)!.emailAddress,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterYourEmail,
                    hintStyle: TextStyle(
                      color: AppColors.textTertiaryOf(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAltOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLightOf(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.surfaceOf(context).withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.yourSecurityImportant,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.secureResetLinkDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryOf(context),
                              height: 1.4,
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
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendResetLink,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 3))
                      : const Icon(Icons.mail_outline_rounded, size: 20),
                  label: Text(_isLoading ? AppLocalizations.of(context)!.sending : AppLocalizations.of(context)!.sendResetLink),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textInverse,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.borderOf(context))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppLocalizations.of(context)!.orLabel,
                      style: TextStyle(
                        color: AppColors.textTertiaryOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.borderOf(context))),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.phoneResetUnavailable))),
                  icon: const Icon(Icons.phone_outlined, size: 20),
                  label: Text(AppLocalizations.of(context)!.resetWithPhoneNumber),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    AppLocalizations.of(context)!.backToSignIn,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: AppColors.textSecondaryOf(context)),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.informationSecureEncrypted,
                    style: TextStyle(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyBadge extends StatelessWidget {
  const _EmergencyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.errorLightOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.errorLightOf(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emergency_rounded, color: AppColors.error, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.emergencyCare,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.error,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.fiveXPriorityAccess,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ForgotIllustration extends StatelessWidget {
  const _ForgotIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20,
            top: 40,
            child: Icon(Icons.star_rounded, color: AppColors.primary.withValues(alpha: 0.1), size: 24),
          ),
          Positioned(
            right: 40,
            bottom: 30,
            child: Icon(Icons.star_rounded, color: AppColors.primary.withValues(alpha: 0.1), size: 20),
          ),
          Positioned(
            left: 40,
            bottom: 40,
            child: CircleAvatar(radius: 4, backgroundColor: AppColors.primary.withValues(alpha: 0.1)),
          ),

          Positioned(
            right: 20,
            top: 20,
            child: Transform.rotate(
              angle: -0.2,
              child: const Icon(Icons.send_rounded, color: AppColors.primaryLight, size: 40),
            ),
          ),

          Container(
            width: 140,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(140, 50),
                  painter: _EnvelopeFlapPainter(),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: AppColors.textInverse, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvelopeFlapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
