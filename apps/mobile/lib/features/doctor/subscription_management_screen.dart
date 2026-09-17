import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  bool isExploring = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryOf(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.subscriptionManagementLabel,
          style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline_rounded, color: AppColors.textPrimaryOf(context)),
            onPressed: () => context.push('/help-support'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              if (isExploring) _buildExploreView() else _buildManageView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageView() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            l10n.managePlanBillingBenefits,
            style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 24),
        
        _buildPlanHeroCard(),
        const SizedBox(height: 20),

        _buildFeaturesRow(),
        const SizedBox(height: 32),

        _buildSectionHeader(l10n.billingAndPayment, trailing: l10n.viewHistory),
        const SizedBox(height: 16),
        _buildBillingInfo(),
        const SizedBox(height: 32),

        _buildSectionHeader(l10n.yourPlanUsage, trailing: l10n.resetsOn15June2025),
        const SizedBox(height: 20),
        _buildUsageGrid(),
        const SizedBox(height: 32),

        _buildSectionHeader(l10n.manageSubscription),
        const SizedBox(height: 16),
        _buildActionTile(Icons.upgrade_rounded, l10n.upgradePlan, l10n.getMoreBenefitsFeatures, AppColors.primary, () => setState(() => isExploring = true)),
        _buildActionTile(Icons.pause_circle_outline_rounded, l10n.pauseSubscription, l10n.pauseYourPlanForAWhile, AppColors.primary, () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.pauseSubscription),
              content: Text(l10n.areYouSurePauseSubscription),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancelLabel)),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.subscriptionPaused)));
                  },
                  child: Text(l10n.pauseLabel),
                ),
              ],
            ),
          );
        }),
        _buildActionTile(Icons.cancel_outlined, l10n.cancelSubscription, l10n.cancelYourPlan, AppColors.error, () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.cancelSubscription),
              content: Text(l10n.areYouSureCancelSubscription),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancelLabel)),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.subscriptionCancelled)));
                  },
                  child: Text(l10n.confirmLabel),
                ),
              ],
            ),
          );
        }, isLast: true),
        
        const SizedBox(height: 32),
        _buildSupportCard(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPlanHeroCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.info],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: Text(l10n.currentPlanLabel, style: const TextStyle(color: AppColors.textInverse, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(l10n.premiumPlanLabel, style: const TextStyle(color: AppColors.textInverse, fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              Text(l10n.allInOnePremiumHealthcare, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              const SizedBox(height: 24),
              Text(l10n.priceLabel, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(l10n.pricePerMonth, style: const TextStyle(color: AppColors.textInverse, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppColors.textInverse, size: 14),
                    const SizedBox(width: 8),
                    Text(l10n.nextBillingDate, style: const TextStyle(color: AppColors.textInverse, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: -10,
            top: 10,
            child: _buildShieldIcon(),
          ),
        ],
      ),
    );
  }

  Widget _buildShieldIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shield_rounded, size: 90, color: Colors.white24),
            const Text('P', style: TextStyle(color: AppColors.textInverse, fontSize: 40, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesRow() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildFeatureItem(Icons.videocam_rounded, l10n.unlimitedLabel, l10n.videoConsults),
        _buildFeatureItem(Icons.chat_bubble_rounded, l10n.priorityLabel, l10n.supportLabel),
        _buildFeatureItem(Icons.security_rounded, l10n.secureHealthData, ''),
        _buildFeatureItem(Icons.local_offer_rounded, l10n.exclusiveDiscounts, ''),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String sub) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 11, fontWeight: FontWeight.w800)),
          if (sub.isNotEmpty) Text(sub, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 9, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 15, fontWeight: FontWeight.w800)),
        if (trailing != null)
          Text(trailing, style: TextStyle(color: trailing.contains('History') ? AppColors.primary : AppColors.textTertiaryOf(context), fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildBillingInfo() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Column(
        children: [
          _buildBillingRow(Icons.description_outlined, l10n.billingCycle, l10n.monthlyValue, amount: '₦15,000'),
          Divider(height: 32, color: AppColors.borderLightOf(context)),
          _buildBillingRow(Icons.credit_card_rounded, l10n.paymentMethodLabel, '•••• 4242', isDefault: true, trailingIcon: Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  Widget _buildBillingRow(IconData icon, String label, String value, {String? amount, bool isDefault = false, IconData? trailingIcon}) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.borderLightOf(context), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primary, size: 20)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(value, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w800)),
                if (isDefault) ...[
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.successLightOf(context), borderRadius: BorderRadius.circular(8)), child: Text(l10n.defaultLabel, style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold))),
                ]
              ],
            ),
          ],
        ),
        const Spacer(),
        if (amount != null) Text(amount, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w900)),
        if (trailingIcon != null) Icon(trailingIcon, color: AppColors.textTertiaryOf(context), size: 20),
      ],
    );
  }

  Widget _buildUsageGrid() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: _buildUsageItem(0.65, Icons.videocam_rounded, '12 / ∞', l10n.videoConsults, l10n.unlimitedLabel)),
        Expanded(child: _buildUsageItem(0.4, Icons.chat_bubble_rounded, '28 / ∞', l10n.chatConsults, l10n.unlimitedLabel)),
        Expanded(child: _buildUsageItem(0.4, Icons.description_rounded, '8 / 20', l10n.healthRecords, l10n.fortyPercentUsed)),
        Expanded(child: _buildUsageItem(0.3, Icons.file_download_rounded, '3 / 10', l10n.reportsLabel, l10n.thirtyPercentUsed)),
      ],
    );
  }

  Widget _buildUsageItem(double progress, IconData icon, String val, String label, String sub) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: AppColors.borderLightOf(context),
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            Icon(icon, color: AppColors.primary, size: 18),
          ],
        ),
        const SizedBox(height: 12),
        Text(val, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 9, fontWeight: FontWeight.w600)),
        Text(sub, style: TextStyle(color: sub.contains('Unlimited') ? AppColors.success : AppColors.textTertiaryOf(context), fontSize: 8, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, String sub, Color color, VoidCallback onTap, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          tileColor: AppColors.surfaceOf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          title: Text(title, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 14, fontWeight: FontWeight.w800)),
          subtitle: Text(sub, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w500)),
          trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryOf(context)),
        ),
        if (!isLast) const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSupportCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.successLightOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.successLightOf(context))),
      child: Row(
        children: [
          Icon(Icons.headset_mic_rounded, color: AppColors.success, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.needHelpLabel, style: TextStyle(color: AppColors.success, fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(l10n.supportTeamHereToHelp, style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.emailAdminForSubscription)));
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.infoLightOf(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.contactAdmin, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.contactSupportEmail)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceOf(context), foregroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.success, width: 1))),
            child: Text(l10n.contactSupportLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreView() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            l10n.choosePlanWorksBest,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 24),
        
        Text(l10n.currentPlanLabel, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _buildCurrentPlanExploreCard(),
        
        const SizedBox(height: 32),
        Text(l10n.choosePlanLabel, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _buildPlansCarousel(),
        
        const SizedBox(height: 32),
        _buildSecurityFooter(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCurrentPlanExploreCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLightOf(context))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.info]),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: AppColors.textInverse, size: 20),
                const SizedBox(width: 8),
                Text(l10n.premiumPlanLabel, style: const TextStyle(color: AppColors.textInverse, fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text(l10n.activeLabel, style: const TextStyle(color: AppColors.textInverse, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.pricePerMonth, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(l10n.renewsOnMay25, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTick(l10n.unlimitedConsultations),
                    _buildTick(l10n.prioritySupport),
                    _buildTick(l10n.timeCreditsIncluded),
                    _buildTick(l10n.familyAccountUpTo5),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTick(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_rounded, color: AppColors.primary, size: 14),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPlansCarousel() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPlanCard(l10n.basicPlan, '₦5,000', Icons.send_rounded, [
            l10n.tenConsultationsPerMonth,
            l10n.standardSupport,
            l10n.timeCreditsNaira2000,
            l10n.familyAccountNA,
          ], isPopular: false),
          _buildPlanCard(l10n.premiumPlanLabel, '₦15,000', Icons.diamond_rounded, [
            l10n.unlimitedConsultations,
            l10n.prioritySupport,
            l10n.timeCreditsNaira7500,
            l10n.familyAccountUpTo5,
          ], isPopular: true, isCurrent: true),
          _buildPlanCard(l10n.proPlan, '₦30,000', Icons.rocket_launch_rounded, [
            l10n.unlimitedConsultations,
            l10n.vipSupport,
            l10n.timeCreditsNaira20000,
            l10n.familyAccountUpTo10,
          ], isPopular: false),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String name, String price, IconData icon, List<String> perks, {bool isPopular = false, bool isCurrent = false}) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isPopular ? AppColors.primary : AppColors.borderLightOf(context), width: isPopular ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.info, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.textInverse, size: 10),
                    const SizedBox(width: 4),
                    Text(l10n.mostPopularLabel, style: const TextStyle(color: AppColors.textInverse, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: AppColors.primary, size: 20)),
          const SizedBox(height: 16),
          Text(name, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('$price / month', style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          ...perks.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: p.contains('N/A') ? AppColors.textTertiaryOf(context) : AppColors.success, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(p, style: TextStyle(color: p.contains('N/A') ? AppColors.textTertiaryOf(context) : AppColors.textSecondaryOf(context), fontSize: 9, fontWeight: FontWeight.w600))),
              ],
            ),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent ? () => setState(() => isExploring = false) : () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.planSelectedContactSupport)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? AppColors.primary : AppColors.surfaceOf(context),
                foregroundColor: isCurrent ? AppColors.textInverse : AppColors.primary,
                elevation: 0,
                side: BorderSide(color: isCurrent ? Colors.transparent : AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isCurrent ? l10n.currentPlanButton : l10n.choosePlanButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.successLightOf(context), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          _buildShieldWithLock(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.secureAndHassleFree, style: TextStyle(color: AppColors.success, fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(l10n.paymentEncryptedDataProtected, style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShieldWithLock() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 50, height: 50, decoration: BoxDecoration(color: AppColors.successLightOf(context), shape: BoxShape.circle)),
        Icon(Icons.shield_rounded, color: AppColors.success, size: 30),
        const Icon(Icons.lock_rounded, color: AppColors.textInverse, size: 12),
      ],
    );
  }
}
