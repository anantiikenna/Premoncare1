import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

import '../../core/app_colors.dart';

class BookingFailedScreen extends StatelessWidget {
  final String? doctorName;
  final String? doctorSpecialty;
  final String? doctorAvatar;
  final String? timeSlot;

  const BookingFailedScreen({
    super.key,
    this.doctorName,
    this.doctorSpecialty,
    this.doctorAvatar,
    this.timeSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOf(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryOf(context), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.bookingFailed,
          style: TextStyle(
            color: AppColors.textPrimaryOf(context),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundOf(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Container(
                      width: 120,
                      height: 130,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.errorLightOf(context),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                          ),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 3,
                              padding: const EdgeInsets.all(12),
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              children: List.generate(6, (index) => Container(
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundOf(context),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.close_rounded, 
                                    size: 10, 
                                    color: AppColors.error.withValues(alpha: 0.2)
                                  ),
                                ),
                              )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 40,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceOf(context), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textInverse,
                        size: 32,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceOf(context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.priority_high_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context)!.bookingFailedDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryOf(context),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.slotUnavailable,
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
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderOf(context)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.bookingDetailsLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          (doctorName ?? '').isNotEmpty
                              ? (doctorName ?? '')[0].toUpperCase()
                              : 'D',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctorName ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                            Text(
                              doctorSpecialty ?? 'General Physician',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                            Text(
                              'MBBS, MD • 8+ Years Exp.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAltOf(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time_rounded, color: AppColors.primaryLight, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.unavailableStatus,
                                  style: TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Today, May 28',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context)),
                          ),
                          Text(
                            '10:30 AM',
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryOf(context)
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorLightOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.errorLightOf(context)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.errorLightOf(context),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.calendar_today_rounded, color: AppColors.error, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.slotNotAvailable,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppLocalizations.of(context)!.slotNotAvailableDescription,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                  height: 1.4,
                                ),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.whatWouldYouLikeToDo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => context.pop(),
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
                    const Icon(Icons.calendar_month_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.chooseAnotherTime,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton(
                onPressed: () => context.go('/doctor-search'),
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
                    const Icon(Icons.group_outlined, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.viewOtherDoctors,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundOf(context),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAltOf(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.headset_mic_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.needHelpFindingSlot,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.supportTeamHelp,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryOf(context),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.contactSupportForAssistance)),
                      );
                    },
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
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: TextButton(
                onPressed: () => context.go('/patient_dashboard'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_outlined, color: AppColors.textPrimaryOf(context), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.backToHomeLabel,
                      style: TextStyle(
                        color: AppColors.textPrimaryOf(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
