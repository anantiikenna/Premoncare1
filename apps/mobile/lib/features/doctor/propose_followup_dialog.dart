import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';

class ProposeFollowupDialog extends StatefulWidget {
  const ProposeFollowupDialog({super.key});

  @override
  State<ProposeFollowupDialog> createState() => _ProposeFollowupDialogState();
}

class _ProposeFollowupDialogState extends State<ProposeFollowupDialog> {
  final TextEditingController _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textInverse,
              onSurface: AppColors.textPrimaryOf(context),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitProposal() async {
    final l10n = AppLocalizations.of(context)!;
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseProvideClinicalReason)),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.followUpProposalSentSuccessfully),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.proposeFollowUp,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5),
                  ),
                  Text(
                    l10n.patientRetentionAndCare,
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: AppColors.textTertiaryOf(context)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          Text(l10n.selectPatient, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondaryOf(context), letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.surfaceAltOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLightOf(context))),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: Text('S', style: TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.bold, fontSize: 9)),
                ),
                const SizedBox(width: 12),
                Text(l10n.sarahJohnsonToday, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryOf(context))),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiaryOf(context), size: 20),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.proposedDate, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondaryOf(context), letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(color: AppColors.surfaceAltOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLightOf(context))),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryOf(context))),
                          ],
                        ),
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
                    Text(l10n.preferredTime, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondaryOf(context), letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(color: AppColors.surfaceAltOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLightOf(context))),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(_selectedTime.format(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryOf(context))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          Text(l10n.clinicalReasonInstructions, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondaryOf(context), letterSpacing: 0.5)),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.explainFollowUpNecessary,
              hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiaryOf(context), fontWeight: FontWeight.w500),
              filled: true,
              fillColor: AppColors.surfaceAltOf(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(20),
            ),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimaryOf(context)),
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitProposal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textInverse,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, size: 18),
                      const SizedBox(width: 12),
                      Text(l10n.sendProposalToPatient, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                    ],
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.patientWillBeNotified,
              style: TextStyle(fontSize: 10, color: AppColors.textTertiaryOf(context), fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
