import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(height: 60),
              const _SuccessIllustration(),
              const SizedBox(height: 40),
              Text(
                AppLocalizations.of(context)!.passwordResetSuccess,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.passwordResetDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryOf(context),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.successLightOf(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.successLightOf(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.accountSecure,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.confirmationEmailSent,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
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
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: Text(AppLocalizations.of(context)!.goToSignIn),
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
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_outlined, size: 20),
                label: Text(AppLocalizations.of(context)!.backToHome),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAltOf(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.didntReceiveEmail,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            AppLocalizations.of(context)!.checkSpamFolder,
                            style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.resetEmailResent)));
                        Future.delayed(const Duration(seconds: 2), () {
                          if (context.mounted) context.go('/login');
                        });
                      },
                      child: Row(
                        children: [
                          Text(AppLocalizations.of(context)!.resendEmail, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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

class _SuccessIllustration extends StatelessWidget {
  const _SuccessIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 40,
            top: 40,
            child: Icon(Icons.auto_awesome_rounded, color: AppColors.success.withValues(alpha: 0.3), size: 24),
          ),
          Positioned(
            right: 40,
            top: 50,
            child: Icon(Icons.auto_awesome_rounded, color: AppColors.success.withValues(alpha: 0.3), size: 20),
          ),
          Positioned(
            left: 50,
            bottom: 30,
            child: Icon(Icons.star_rounded, color: AppColors.primary.withValues(alpha: 0.2), size: 16),
          ),
          Positioned(
            right: 60,
            bottom: 40,
            child: CircleAvatar(radius: 3, backgroundColor: AppColors.warning.withValues(alpha: 0.3)),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.successLightOf(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.successLightOf(context),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.textInverse,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }
}
