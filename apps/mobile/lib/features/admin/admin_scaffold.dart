import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/providers.dart';
import '../../core/supabase_locator.dart';
import '../../shared/widgets/global_user_avatar.dart';
import 'admin_dashboard.dart';
import 'user_management_panel.dart';
import 'doctor_verification_panel.dart';
import 'forum_moderation_panel.dart';

class AdminScaffold extends ConsumerStatefulWidget {
  final Widget? body;
  final int selectedIndex;

  const AdminScaffold({super.key, this.body, this.selectedIndex = 0});

  @override
  ConsumerState<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends ConsumerState<AdminScaffold> {
  int _currentIndex = 0;

  bool get _isShell => widget.body == null;

  final List<Widget> _tabScreens = [
    const AdminDashboard(),
    const UserManagementPanel(),
    const DoctorVerificationPanel(),
    const ForumModerationPanel(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant AdminScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isShell && oldWidget.selectedIndex != widget.selectedIndex) {
      _currentIndex = widget.selectedIndex;
    }
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.accountSectionLabel,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.person_rounded, color: AppColors.primary),
              title: Text(
                AppLocalizations.of(context)!.adminProfile,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.adminProfileDeveloped,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.primary,
              ),
              title: Text(
                AppLocalizations.of(context)!.permissionsRole,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings-privacy');
              },
            ),
            ListTile(
              leading: Icon(Icons.security_rounded, color: AppColors.primary),
              title: Text(
                AppLocalizations.of(context)!.securitySettings,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings-privacy');
              },
            ),
            ListTile(
              leading: Icon(Icons.devices_rounded, color: AppColors.primary),
              title: Text(
                AppLocalizations.of(context)!.deviceSessionsTile,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/audit-timeline');
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.help_center_rounded,
                color: AppColors.primary,
              ),
              title: Text(
                AppLocalizations.of(context)!.helpAndSupport,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.contactSupportPremoncare),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text(
                AppLocalizations.of(context)!.logoutLabel,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.logOut),
                    content: Text(AppLocalizations.of(context)!.areYouSureLogOut),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(AppLocalizations.of(context)!.cancelLabel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: Text(AppLocalizations.of(context)!.logOutLabel),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.textInverse,
                      ),
                    ),
                  );
                  await performLogout();
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                    context.go('/admin-login');
                  }
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.operationalModules,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 16),
              _buildMoreTile(
                context,
                Icons.analytics_outlined,
                AppLocalizations.of(context)!.reportsAndInsights,
                '/admin/reports',
              ),
              _buildMoreTile(
                context,
                Icons.monetization_on_outlined,
                AppLocalizations.of(context)!.p2pMonitoring,
                '/admin/p2p-monitoring',
              ),
              _buildMoreTile(
                context,
                Icons.notifications_outlined,
                AppLocalizations.of(context)!.notificationControl,
                '/admin/notifications',
              ),
              _buildMoreTile(
                context,
                Icons.person_add_alt_1_outlined,
                AppLocalizations.of(context)!.doctorSubscriptions,
                '/admin/doctor-subscriptions',
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreTile(
    BuildContext context,
    IconData icon,
    String title,
    String? route,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () {
        Navigator.pop(context);
        if (route != null) context.push(route);
      },
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route, {
    bool isCurrent = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isCurrent
            ? AppColors.primary
            : AppColors.textSecondaryOf(context),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
          color: isCurrent
              ? AppColors.primary
              : AppColors.textPrimaryOf(context),
        ),
      ),
      selected: isCurrent,
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _isShell ? _currentIndex : widget.selectedIndex;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: AppColors.textPrimaryOf(context),
              size: 28,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.premonCareAdmin,
          style: TextStyle(
            color: AppColors.textPrimaryOf(context),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimaryOf(context),
              size: 28,
            ),
            onPressed: () => context.push('/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: GestureDetector(
              onTap: () => _showProfileSheet(context),
              child: const GlobalUserAvatar(radius: 16),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/logo-symbol.png',
                      height: 48,
                      errorBuilder: (_, _, _) => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.shield_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.appTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.adminPortal,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(
                      context,
                      Icons.dashboard_outlined,
                      AppLocalizations.of(context)!.dashboardLabel,
                      '/admin-dashboard',
                      isCurrent: activeIndex == 0,
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.people_outline,
                      AppLocalizations.of(context)!.userManagement,
                      '/admin/user-management',
                      isCurrent: activeIndex == 1,
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.verified_user_outlined,
                      AppLocalizations.of(context)!.doctorVerification,
                      '/admin/doctor-verification',
                      isCurrent: activeIndex == 2,
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.account_balance_wallet_outlined,
                      AppLocalizations.of(context)!.financialModeration,
                      '/admin/financial',
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.monetization_on_outlined,
                      AppLocalizations.of(context)!.p2pMonitoring,
                      '/admin/p2p-monitoring',
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.emergency_outlined,
                      AppLocalizations.of(context)!.emergencyQueueLabel,
                      '/admin/emergency-queue',
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.forum_outlined,
                      AppLocalizations.of(context)!.forumModeration,
                      '/admin/forum-moderation',
                      isCurrent: activeIndex == 3,
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.analytics_outlined,
                      AppLocalizations.of(context)!.reportsLabel,
                      '/admin/reports',
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.history_outlined,
                      AppLocalizations.of(context)!.auditTimeline,
                      '/admin/audit-timeline',
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.card_membership_outlined,
                      AppLocalizations.of(context)!.subscriptionPlans,
                      '/admin/subscription-control',
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.gavel_outlined,
                      AppLocalizations.of(context)!.disputeResolution,
                      '/admin/disputes',
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.settings_outlined,
                      AppLocalizations.of(context)!.platformSettings,
                      '/settings-privacy',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isShell
          ? IndexedStack(index: _currentIndex, children: _tabScreens)
          : widget.body!,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          border: Border(
            top: BorderSide(color: AppColors.borderLightOf(context)),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                Icons.home_rounded,
                AppLocalizations.of(context)!.dashboardLabel,
                isSelected: activeIndex == 0,
                activeColor: AppColors.primary,
                onTap: () {
                  if (_isShell) {
                    setState(() => _currentIndex = 0);
                  } else {
                    context.go('/admin-dashboard');
                  }
                },
              ),
              _buildNavItem(
                context,
                Icons.people_alt_rounded,
                AppLocalizations.of(context)!.usersLabel,
                isSelected: activeIndex == 1,
                activeColor: AppColors.primary,
                onTap: () {
                  if (_isShell) {
                    setState(() => _currentIndex = 1);
                  } else {
                    context.go('/admin/user-management');
                  }
                },
              ),
              _buildNavItem(
                context,
                Icons.medical_services_rounded,
                AppLocalizations.of(context)!.doctorsLabel,
                isSelected: activeIndex == 2,
                activeColor: AppColors.primary,
                badgeCount:
                    ref
                        .watch(pendingVerificationsProvider)
                        .whenOrNull(data: (v) => v) ??
                    0,
                onTap: () {
                  if (_isShell) {
                    setState(() => _currentIndex = 2);
                  } else {
                    context.go('/admin/doctor-verification');
                  }
                },
              ),
              _buildNavItem(
                context,
                Icons.forum_rounded,
                AppLocalizations.of(context)!.forumLabel,
                isSelected: activeIndex == 3,
                activeColor: AppColors.primary,
                onTap: () {
                  if (_isShell) {
                    setState(() => _currentIndex = 3);
                  } else {
                    context.go('/admin/forum-moderation');
                  }
                },
              ),
              _buildNavItem(
                context,
                Icons.more_horiz_rounded,
                AppLocalizations.of(context)!.moreLabel,
                isSelected: activeIndex == 4,
                activeColor: AppColors.primary,
                onTap: () => _showMoreSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label, {
    required bool isSelected,
    required Color activeColor,
    VoidCallback? onTap,
    int? badgeCount,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? activeColor
                    : AppColors.textTertiaryOf(context),
                size: 26,
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? activeColor
                  : AppColors.textTertiaryOf(context),
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
