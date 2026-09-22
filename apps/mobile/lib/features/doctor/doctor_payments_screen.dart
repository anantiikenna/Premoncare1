import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/providers.dart';
import '../../core/supabase_locator.dart';
import '../../l10n/app_localizations.dart';

class DoctorPaymentsScreen extends ConsumerWidget {
  const DoctorPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(pendingPaymentsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.paymentApprovalsLabel, style: TextStyle(color: AppColors.textPrimaryOf(context), fontWeight: FontWeight.w800, fontSize: 20)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryOf(context)),
          onPressed: () => context.pop(),
        ),
      ),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments_rounded, size: 64, color: AppColors.textTertiaryOf(context)),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.noPendingPayments, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimaryOf(context))),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.paymentsSentWillAppearHere, style: TextStyle(color: AppColors.textSecondaryOf(context))),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) => _buildPaymentCard(context, ref, payments[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: AppColors.error))),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, WidgetRef ref, Map<String, dynamic> payment) {
    final amount = payment['amount'] ?? 0;
    final status = payment['status'] ?? 'pending';
    final patientName = payment['patient_name'] ?? 'Patient';
    final paymentId = payment['id'] as String?;
    final isPending = status == 'pending';

    Future<void> handleApprove() async {
      if (paymentId == null) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        final user = supabase.auth.currentUser;
        if (user == null) throw Exception('Not signed in');
        final { error } = await supabase.rpc(
          'approve_payment',
          params: {'p_payment_id': paymentId, 'p_processor_id': user.id},
        );
        if (error != null) throw error;
        messenger.showSnackBar(
          const SnackBar(content: Text('Payment approved'), backgroundColor: AppColors.success),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    }

    Future<void> handleReject() async {
      if (paymentId == null) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        final user = supabase.auth.currentUser;
        if (user == null) throw Exception('Not signed in');
        final { error } = await supabase.rpc(
          'reject_payment',
          params: {'p_payment_id': paymentId, 'p_reason': 'Rejected by doctor', 'p_processor_id': user.id},
        );
        if (error != null) throw error;
        messenger.showSnackBar(
          const SnackBar(content: Text('Payment rejected'), backgroundColor: AppColors.success),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(patientName.isNotEmpty ? patientName[0].toUpperCase() : '?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimaryOf(context))),
                    Text('₦$amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'pending' ? AppColors.warning.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: status == 'pending' ? AppColors.warning : AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: isPending ? handleApprove : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: BorderSide(color: AppColors.success),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.approveLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: isPending ? handleReject : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.rejectLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
