import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/generic_user_avatar.dart';
import '../../shared/widgets/mesh_circle.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';


class SelectDurationScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final double hourlyRate;
  final bool isEmergency;

  const SelectDurationScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.hourlyRate,
    required this.isEmergency,
  });

  @override
  State<SelectDurationScreen> createState() => _SelectDurationScreenState();
}

class _SelectDurationScreenState extends State<SelectDurationScreen> {
  int _selectedDuration = 30;

  double get _ratePerMinute => (widget.hourlyRate / 60) * (widget.isEmergency ? 5 : 1);

  int _priceForDuration(int minutes) => (_ratePerMinute * minutes).toInt();

  @override
  Widget build(BuildContext context) {
    final isEmergency = widget.isEmergency;
    final primaryColor = isEmergency ? AppColors.error : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          Positioned(top: -150, right: -100, child: MeshCircle(color: primaryColor.withValues(alpha: 0.1), size: 500)),
          Positioned(bottom: -100, left: -50, child: MeshCircle(color: primaryColor.withValues(alpha: 0.05), size: 400)),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(context, isEmergency),
                  const SizedBox(height: 24),
                  Text(isEmergency ? AppLocalizations.of(context)!.priorityDispatch : AppLocalizations.of(context)!.clinicalBooking,
                      style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Text(isEmergency ? AppLocalizations.of(context)!.emergencyAccessTitle : AppLocalizations.of(context)!.bookingDetails,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -1.0)),
                  const SizedBox(height: 32),

                  _SpecialistPreviewCard(
                    isEmergency: isEmergency,
                    primaryColor: primaryColor,
                    doctorName: widget.doctorName,
                    hourlyRate: widget.hourlyRate,
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle(AppLocalizations.of(context)!.sessionDuration),
                  const SizedBox(height: 16),
                  _DurationSelector(
                    selectedDuration: _selectedDuration,
                    primaryColor: primaryColor,
                    hourlyRate: widget.hourlyRate,
                    isEmergency: isEmergency,
                    onSelected: (val) => setState(() => _selectedDuration = val),
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle(AppLocalizations.of(context)!.pricingArchitecture),
                  const SizedBox(height: 16),
                  _PricingModule(
                    selectedDuration: _selectedDuration,
                    hourlyRate: widget.hourlyRate,
                    isEmergency: isEmergency,
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: () => context.push('/confirm-booking', extra: {
                        'doctorId': widget.doctorId,
                        'doctorName': widget.doctorName,
                        'durationMinutes': _selectedDuration,
                        'totalAmount': _priceForDuration(_selectedDuration).toDouble(),
                        'isEmergency': isEmergency,
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textInverse,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isEmergency ? AppLocalizations.of(context)!.authorizeEmergencyCare : AppLocalizations.of(context)!.proceedToConfirmation,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildAppBar(BuildContext context, bool isEmergency) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderOf(context))),
              child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context), size: 20),
            ),
          ),
          if (isEmergency) _EmergencyBadge(),
        ],
      ),
    );
  }
}

class _SpecialistPreviewCard extends StatelessWidget {
  final bool isEmergency;
  final Color primaryColor;
  final String doctorName;
  final double hourlyRate;

  const _SpecialistPreviewCard({
    required this.isEmergency,
    required this.primaryColor,
    required this.doctorName,
    required this.hourlyRate,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = doctorName;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isEmergency ? AppColors.errorLightOf(context) : AppColors.borderLightOf(context)),
      ),
      child: Row(
        children: [
          const GenericUserAvatar(radius: 36, avatarUrl: null),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('₦${hourlyRate.toStringAsFixed(0)} / hour', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final int selectedDuration;
  final Color primaryColor;
  final double hourlyRate;
  final bool isEmergency;
  final Function(int) onSelected;

  const _DurationSelector({
    required this.selectedDuration,
    required this.primaryColor,
    required this.hourlyRate,
    required this.isEmergency,
    required this.onSelected,
  });

  int _price(int mins) {
    final perMin = (hourlyRate / 60) * (isEmergency ? 5 : 1);
    return (perMin * mins).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final durations = [15, 30, 45, 60];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: durations.map((mins) {
          final isSelected = selectedDuration == mins;
          return GestureDetector(
            onTap: () => onSelected(mins),
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: isSelected ? primaryColor : AppColors.borderLightOf(context)),
                boxShadow: isSelected
                    ? [BoxShadow(color: primaryColor.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10))]
                    : [],
              ),
              child: Column(
                children: [
                  Text('$mins',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: isSelected ? AppColors.textInverse : AppColors.textPrimaryOf(context), letterSpacing: -1)),
                  Text('MINS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isSelected ? AppColors.textInverse.withValues(alpha: 0.7) : AppColors.textTertiaryOf(context), letterSpacing: 1)),
                  const SizedBox(height: 16),
                  Text('₦${_price(mins)}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isSelected ? AppColors.textInverse : primaryColor)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PricingModule extends StatelessWidget {
  final int selectedDuration;
  final double hourlyRate;
  final bool isEmergency;
  final Color primaryColor;

  const _PricingModule({
    required this.selectedDuration,
    required this.hourlyRate,
    required this.isEmergency,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final perMin = hourlyRate / 60;
    final multiplier = isEmergency ? 5 : 1;
    final total = (perMin * multiplier * selectedDuration).toInt();
    final totalStr = formatNairaAmount(total.toDouble());

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        children: [
          _PriceRow(label: AppLocalizations.of(context)!.clinicalBaseRate, value: '₦${perMin.toStringAsFixed(0)} / MIN'),
          const SizedBox(height: 16),
          _PriceRow(label: AppLocalizations.of(context)!.sessionDurationLabel, value: '$selectedDuration MINUTES'),
          if (isEmergency) ...[
            const SizedBox(height: 16),
            _PriceRow(label: AppLocalizations.of(context)!.emergencyPremium, value: AppLocalizations.of(context)!.fiveXRateApplied, isUrgent: true),
          ],
          Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Divider(color: AppColors.borderLightOf(context), thickness: 2)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.totalEstimate, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.textSecondaryOf(context), letterSpacing: 0.5)),
              Text('₦$totalStr', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: primaryColor, letterSpacing: -1.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isUrgent;
  const _PriceRow({required this.label, required this.value, this.isUrgent = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textTertiaryOf(context), letterSpacing: 0.5)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isUrgent ? AppColors.error : AppColors.textPrimaryOf(context))),
      ],
    );
  }
}

class _EmergencyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AppColors.errorLightOf(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.errorLightOf(context))),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.priorityAccess, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.error, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
