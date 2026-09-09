import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../core/supabase_locator.dart';
import '../../core/providers.dart';
import '../../shared/widgets/global_user_avatar.dart';

class SettingsPrivacyCenterScreen extends ConsumerStatefulWidget {
  const SettingsPrivacyCenterScreen({super.key});

  @override
  ConsumerState<SettingsPrivacyCenterScreen> createState() =>
      _SettingsPrivacyCenterScreenState();
}

class _SettingsPrivacyCenterScreenState
    extends ConsumerState<SettingsPrivacyCenterScreen> {
  String _currentLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _currentLanguage = prefs.getString('locale_language') ?? 'English';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final userProfile = ref.watch(userProfileProvider);
    final email = user?.email ?? 'patient@premoncare.com';

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildTitleSection(context),
            const SizedBox(height: 24),
            _buildProfileSummary(context, email, userProfile.asData?.value),
            const SizedBox(height: 32),
            _buildSectionHeader(context, AppLocalizations.of(context)!.accountSettingsHeader),
            const SizedBox(height: 12),
            _buildAccountSettings(context),
            const SizedBox(height: 32),
            _buildSectionHeader(context, AppLocalizations.of(context)!.privacyAndDataHeader),
            const SizedBox(height: 12),
            _buildPrivacyDataSettings(context),
            const SizedBox(height: 32),
            _buildSectionHeader(context, AppLocalizations.of(context)!.preferencesHeader),
            const SizedBox(height: 12),
            _buildPreferencesSettings(context),
            const SizedBox(height: 32),
            _buildSectionHeader(context, AppLocalizations.of(context)!.supportAndLegalHeader),
            const SizedBox(height: 12),
            _buildSupportLegalSettings(context),
            const SizedBox(height: 32),
            _buildFooterAlert(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final color = AppColors.textPrimaryOf(context);
    return AppBar(
      backgroundColor: AppColors.surfaceOf(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: color),
        onPressed: () => context.pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/logo-horizontal.png',
            height: 28,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Premon',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Care',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_none_rounded, color: color),
          onPressed: () => context.push('/notifications'),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => context.push('/personal-info'),
          child: const GlobalUserAvatar(radius: 16),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    final color = AppColors.textPrimaryOf(context);
    final secondary = AppColors.textSecondaryOf(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings & Privacy',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.manageYourAccountSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSummary(
    BuildContext context,
    String email,
    Map<String, dynamic>? profile,
  ) {
    final color = AppColors.textPrimaryOf(context);
    final secondary = AppColors.textSecondaryOf(context);
    return GestureDetector(
      onTap: () => context.push('/personal-info'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const GlobalUserAvatar(radius: 20),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceOf(context),
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?['full_name'] ?? 'User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.success,
                          size: 10,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiaryOf(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: AppTypography.labelMediumOf(context).copyWith(
        letterSpacing: -0.3,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    return _buildGroup(context, [
      _SettingsTileData(
        icon: Icons.person_outline_rounded,
        color: AppColors.info,
        title: AppLocalizations.of(context)!.personalInformationTile,
        subtitle: AppLocalizations.of(context)!.updateYourDetails,
        onTap: () => context.push('/personal-info'),
      ),
      _SettingsTileData(
        icon: Icons.lock_outline_rounded,
        color: AppColors.success,
        title: AppLocalizations.of(context)!.loginAndSecurityTile,
        subtitle: AppLocalizations.of(context)!.passwordAndSecuritySettings,
        onTap: () => context.push('/login-security'),
      ),
      _SettingsTileData(
        icon: Icons.notifications_none_rounded,
        color: AppColors.primary,
        title: AppLocalizations.of(context)!.notificationPreferencesTile,
        subtitle: AppLocalizations.of(context)!.chooseNotificationsSubtitle,
        onTap: () => context.push('/notification-preferences'),
      ),
      _SettingsTileData(
        icon: Icons.language_rounded,
        color: AppColors.warning,
        title: AppLocalizations.of(context)!.languageAndRegionTile,
        subtitle: AppLocalizations.of(context)!.languageAndRegionSubtitle,
        trailingText: _currentLanguage,
        onTap: () => context.push('/language-region'),
      ),
    ]);
  }

  Widget _buildPrivacyDataSettings(BuildContext context) {
    return _buildGroup(context, [
      _SettingsTileData(
        icon: Icons.shield_outlined,
        color: AppColors.success,
        title: AppLocalizations.of(context)!.biometricAndPrivacyTile,
        subtitle: AppLocalizations.of(context)!.privacyAndBiometricControls,
        onTap: () => context.push('/biometric-privacy'),
      ),
      _SettingsTileData(
        icon: Icons.medical_information_outlined,
        color: AppColors.info,
        title: AppLocalizations.of(context)!.recordPermissionsTile,
        subtitle: AppLocalizations.of(context)!.manageDoctorAccess,
        onTap: () => context.push('/medical-record-permissions'),
      ),
      _SettingsTileData(
        icon: Icons.devices_rounded,
        color: AppColors.primary,
        title: AppLocalizations.of(context)!.deviceSessionsTile,
        subtitle: AppLocalizations.of(context)!.activeSessionsAndActivity,
        onTap: () => context.push('/device-sessions'),
      ),
      _SettingsTileData(
        icon: Icons.file_download_outlined,
        color: AppColors.warning,
        title: AppLocalizations.of(context)!.downloadMyDataTile,
        subtitle: AppLocalizations.of(context)!.exportYourHealthData,
        onTap: () => context.push('/download-data'),
      ),
      _SettingsTileData(
        icon: Icons.delete_outline_rounded,
        color: AppColors.error,
        title: AppLocalizations.of(context)!.deleteAccountTile,
        subtitle: AppLocalizations.of(context)!.permanentlyDeleteAccount,
        onTap: () => _showDeleteAccountDialog(context),
      ),
    ]);
  }

  Widget _buildPreferencesSettings(BuildContext context) {
    return _buildGroup(context, [
      _SettingsTileData(
        icon: Icons.dark_mode_outlined,
        color: AppColors.success,
        title: AppLocalizations.of(context)!.appearanceTile,
        subtitle: AppLocalizations.of(context)!.chooseLightOrDarkMode,
        onTap: () => context.push('/appearance'),
      ),
      _SettingsTileData(
        icon: Icons.accessibility_new_rounded,
        color: AppColors.info,
        title: AppLocalizations.of(context)!.accessibilityTile,
        subtitle: AppLocalizations.of(context)!.textSizeAndDisplayOptions,
        onTap: () => context.push('/accessibility'),
      ),
      _SettingsTileData(
        icon: Icons.favorite_border_rounded,
        color: AppColors.primary,
        title: AppLocalizations.of(context)!.healthPreferencesTile,
        subtitle: AppLocalizations.of(context)!.unitsAndHealthSettings,
        onTap: () => context.push('/health-preferences'),
      ),
    ]);
  }

  Widget _buildSupportLegalSettings(BuildContext context) {
    return _buildGroup(context, [
      _SettingsTileData(
        icon: Icons.headset_mic_outlined,
        color: AppColors.info,
        title: AppLocalizations.of(context)!.helpSupportTile,
        subtitle: AppLocalizations.of(context)!.faqsAndContactSupport,
        onTap: () => context.push('/help-support'),
      ),
      _SettingsTileData(
        icon: Icons.description_outlined,
        color: AppColors.success,
        title: AppLocalizations.of(context)!.termsOfServiceTile,
        subtitle: AppLocalizations.of(context)!.readOurTerms,
        onTap: () => context.push('/terms-of-service'),
      ),
      _SettingsTileData(
        icon: Icons.verified_user_outlined,
        color: AppColors.primary,
        title: AppLocalizations.of(context)!.privacyPolicyTile,
        subtitle: AppLocalizations.of(context)!.howWeProtectData,
        onTap: () => context.push('/privacy-policy'),
      ),
      _SettingsTileData(
        icon: Icons.info_outline_rounded,
        color: AppColors.warning,
        title: AppLocalizations.of(context)!.aboutPremonCareTile,
        subtitle: AppLocalizations.of(context)!.appVersionLabel,
        onTap: () => context.push('/about'),
      ),
    ]);
  }

  Widget _buildGroup(BuildContext context, List<_SettingsTileData> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final i = entry.key;
          final tile = entry.value;
          return _buildSettingsTile(
            context: context,
            icon: tile.icon,
            color: tile.color,
            title: tile.title,
            subtitle: tile.subtitle,
            trailingText: tile.trailingText,
            isDivider: i > 0,
            onTap: tile.onTap,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? trailingText,
    bool isDivider = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        if (isDivider)
          Divider(
            height: 1,
            indent: 64,
            endIndent: 20,
            color: AppColors.dividerOf(context),
          ),
        ListTile(
          onTap: onTap ?? () {},
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Text(
                  trailingText,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiaryOf(context),
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterAlert(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.success, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.privacyIsPriority,
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.industryStandardEncryption,
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final user = supabase.auth.currentUser;
    final email = user?.email ?? '';
    final deleteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final canDelete = deleteController.text == email;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(ctx),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.borderLightOf(ctx),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: AppColors.error,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        AppLocalizations.of(context)!.deleteAccountDialogTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimaryOf(ctx),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.deleteAccountWarning,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(ctx),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.willPermanentlyDelete,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryOf(ctx),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DeleteSummaryItem(
                    icon: Icons.person_outline_rounded,
                    text: AppLocalizations.of(ctx)!.profileAndPersonalInfo,
                  ),
                  _DeleteSummaryItem(
                    icon: Icons.calendar_today_rounded,
                    text: AppLocalizations.of(ctx)!.allAppointmentsHistory,
                  ),
                  _DeleteSummaryItem(
                    icon: Icons.folder_outlined,
                    text: AppLocalizations.of(ctx)!.medicalRecordsAndDocuments,
                  ),
                  _DeleteSummaryItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    text: AppLocalizations.of(ctx)!.allMessagesAndChatHistory,
                  ),
                  _DeleteSummaryItem(
                    icon: Icons.receipt_long_rounded,
                    text: AppLocalizations.of(ctx)!.paymentRecordsAndHistory,
                  ),
                  _DeleteSummaryItem(
                    icon: Icons.star_border_rounded,
                    text: AppLocalizations.of(ctx)!.reviewsAndRatingsGiven,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.typeEmailToConfirm,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(ctx),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundOf(ctx),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: deleteController.text.isNotEmpty
                            ? (canDelete ? AppColors.success : AppColors.error)
                            : AppColors.borderLightOf(ctx),
                      ),
                    ),
                    child: TextField(
                      controller: deleteController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setModalState(() {}),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryOf(ctx),
                      ),
                      decoration: InputDecoration(
                        hintText: email,
                        hintStyle: TextStyle(
                          color: AppColors.textTertiaryOf(ctx),
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  if (deleteController.text.isNotEmpty && !canDelete)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        AppLocalizations.of(context)!.emailDoesNotMatch,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            deleteController.dispose();
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.borderLightOf(ctx),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(AppLocalizations.of(context)!.cancelLabel, style: TextStyle(
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canDelete
                              ? () async {
                                  Navigator.pop(ctx);
                                  try {
                                    final currentUser =
                                        supabase.auth.currentUser;
                                    if (currentUser != null) {
                                      // Use Supabase RPC for soft-delete
                                      await supabase.rpc(
                                        'soft_delete_user',
                                        params: {
                                          'p_user_id': currentUser.id,
                                          'p_reason':
                                              'User requested account deletion',
                                        },
                                      );
                                    }
                                    await performLogout();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.accountScheduledForDeletion,
                              ),
                            );
                                      context.go('/login');
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            disabledBackgroundColor: AppColors.error.withValues(
                              alpha: 0.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(AppLocalizations.of(context)!.deleteMyAccountButton, style: TextStyle(
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DeleteSummaryItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DeleteSummaryItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.error.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTileData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? trailingText;
  final VoidCallback? onTap;

  const _SettingsTileData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailingText,
    this.onTap,
  });
}
