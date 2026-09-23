import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../l10n/app_localizations.dart';

class ProposeFollowupDialog extends StatefulWidget {
  final String? patientId;
  final String? patientName;

  const ProposeFollowupDialog({super.key, this.patientId, this.patientName});

  @override
  State<ProposeFollowupDialog> createState() => _ProposeFollowupDialogState();
}

class _ProposeFollowupDialogState extends State<ProposeFollowupDialog> {
  final TextEditingController _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;
  String? _patientId;
  String? _patientName;
  List<Map<String, dynamic>> _patients = [];
  bool _loadingPatients = true;

  @override
  void initState() {
    super.initState();
    _patientId = widget.patientId;
    _patientName = widget.patientName;
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _loadingPatients = false);
        return;
      }
      final data = await supabase
          .from('appointments')
          .select('patient_id, profiles!appointments_patient_id_fkey(id, full_name)')
          .eq('doctor_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);
      final seen = <String>{};
      final patients = <Map<String, dynamic>>[];
      for (final row in data) {
        final profile = row['profiles'];
        if (profile is Map && profile['id'] != null) {
          final id = profile['id'] as String;
          if (seen.add(id)) {
            patients.add({'id': id, 'full_name': profile['full_name'] ?? 'Patient'});
          }
        }
      }
      if (mounted) {
        setState(() {
          _patients = patients;
          _loadingPatients = false;
          if (_patientId == null && patients.isNotEmpty) {
            _patientId = patients.first['id'] as String;
            _patientName = patients.first['full_name'] as String;
          }
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Follow-up patients load failed: $e');
      if (mounted) setState(() => _loadingPatients = false);
    }
  }

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
    if (_patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectPatient)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not signed in');
      final profile = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      final doctorName = profile?['full_name'] ?? 'Doctor';
      final dateStr = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
      final timeStr = _selectedTime.format(context);

      await supabase.from('notifications').insert({
        'user_id': _patientId,
        'title': 'New Follow-up Proposal',
        'message': 'Dr. $doctorName has proposed a follow-up session on $dateStr at $timeStr.',
        'type': 'appointment_proposal',
        'link': '/patient/appointments?propose=${user.id}&date=$dateStr&time=$timeStr',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.followUpProposalSentSuccessfully),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
        padding: EdgeInsets.fromLTRB(32, 32, 32, 16 + mq.padding.bottom),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
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
          InkWell(
            onTap: _loadingPatients || _patients.isEmpty
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.surfaceOf(context),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (ctx) => ListView.builder(
                        itemCount: _patients.length,
                        itemBuilder: (_, i) {
                          final p = _patients[i];
                          return ListTile(
                            title: Text(p['full_name'] as String),
                            selected: p['id'] == _patientId,
                            onTap: () {
                              setState(() {
                                _patientId = p['id'] as String;
                                _patientName = p['full_name'] as String;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    );
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.surfaceAltOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLightOf(context))),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (_patientName ?? '?').isNotEmpty ? (_patientName![0].toUpperCase()) : '?',
                      style: const TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.bold, fontSize: 9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _loadingPatients ? '...' : (_patientName ?? l10n.selectPatient),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryOf(context)),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiaryOf(context), size: 20),
                ],
              ),
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
        ),
      ),
    );
  }
}
