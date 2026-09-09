import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';

class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAltOf(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(Icons.shield_rounded, size: 180, color: AppColors.primary.withValues(alpha: 0.1)),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(Icons.lock_rounded, color: AppColors.textInverse, size: 60),
                    ),
                    Positioned(
                      bottom: 40,
                      right: 40,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLightOf(context),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surfaceOf(context), width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(Icons.access_time_filled_rounded, color: AppColors.error, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Text(
                AppLocalizations.of(context)!.sessionExpired,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.sessionExpiredDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondaryOf(context),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAltOf(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderLightOf(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLightOf(context)),
                      ),
                      child: Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.sessionTimedOut,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.sessionTimeoutDescription,
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
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textInverse,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.signInAgain,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: OutlinedButton(
                  onPressed: () => context.go('/'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.borderOf(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.home_outlined, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.goToHome,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAltOf(context),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.borderLightOf(context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.headset_mic_outlined,
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
                            AppLocalizations.of(context)!.needHelp,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.supportTeam247,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context)),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.contactSupportEmail))),
                      child: Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.contactSupport,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: AppColors.textTertiaryOf(context), size: 14),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.dataSafeWithUs,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryOf(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      AppLocalizations.of(context)!.industryStandardSecurity,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiaryOf(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
