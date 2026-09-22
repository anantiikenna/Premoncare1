import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/global_user_avatar.dart';
import '../../core/supabase_locator.dart';
import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  bool _isLoading = true;
  bool _isVacationMode = false;
  bool _emergencyAvailability = false;
  bool _autoAccept = false;
  bool _isSaving = false;
  String _timezone = '(GMT+1) West Africa Time (WAT)';
  List<Map<String, dynamic>> _weeklyHours = [];
  List<Map<String, String>> _breakTimes = [];

  List<Map<String, dynamic>> _defaultWeeklyHours(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {'day': 'Monday', 'enabled': true, 'start': '08:00', 'end': '18:00'},
      {'day': 'Tuesday', 'enabled': true, 'start': '08:00', 'end': '18:00'},
      {'day': 'Wednesday', 'enabled': true, 'start': '08:00', 'end': '18:00'},
      {'day': 'Thursday', 'enabled': true, 'start': '08:00', 'end': '18:00'},
      {'day': 'Friday', 'enabled': true, 'start': '08:00', 'end': '17:00'},
      {'day': 'Saturday', 'enabled': false, 'start': '09:00', 'end': '13:00'},
      {'day': 'Sunday', 'enabled': false, 'start': '00:00', 'end': '00:00'},
    ];
  }

  List<Map<String, String>> _defaultBreakTimes(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {'label': l10n.lunchBreak, 'time': '12:00 - 13:00'},
      {'label': l10n.shortBreak, 'time': '16:00 - 16:15'},
      {'label': l10n.personalTime, 'time': '19:30 - 20:00'},
    ];
  }

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not signed in');
      final data = await supabase
          .from('doctor_schedules')
          .select('weekly_hours, break_times, vacation_mode, emergency_availability, auto_accept, timezone')
          .eq('doctor_id', user.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          if (data != null) {
            _weeklyHours = List<Map<String, dynamic>>.from(data['weekly_hours'] as List? ?? []);
            _breakTimes = List<Map<String, String>>.from(
              (data['break_times'] as List? ?? []).map((e) => Map<String, String>.from(e as Map)),
            );
            _isVacationMode = data['vacation_mode'] as bool? ?? false;
            _emergencyAvailability = data['emergency_availability'] as bool? ?? false;
            _autoAccept = data['auto_accept'] as bool? ?? false;
            if (data['timezone'] != null) _timezone = data['timezone'] as String;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSchedule() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not signed in');
      await supabase.from('doctor_schedules').upsert({
        'doctor_id': user.id,
        'weekly_hours': _weeklyHours,
        'break_times': _breakTimes,
        'vacation_mode': _isVacationMode,
        'emergency_availability': _emergencyAvailability,
        'auto_accept': _autoAccept,
        'timezone': _timezone,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'doctor_id');
      if (_emergencyAvailability) {
        await supabase.from('profiles').update({'is_emergency': true}).eq('id', user.id);
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.scheduleSavedSuccessfully), backgroundColor: AppColors.success),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.failedToSaveSchedule), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_weeklyHours.isEmpty && !_isLoading) {
      _weeklyHours = _defaultWeeklyHours(context);
      _breakTimes = _defaultBreakTimes(context);
    }
    final weeklyHours = _weeklyHours;
    final breakTimes = _breakTimes;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimaryOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.doctorAvailabilitySchedule,
          style: TextStyle(
            color: AppColors.textPrimaryOf(context),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: AppColors.textPrimaryOf(context)),
            onPressed: () => context.push('/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: GestureDetector(
              onTap: () => context.push('/settings-privacy'),
              child: const GlobalUserAvatar(radius: 18),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.manageWorkingHoursDescription,
                    style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          l10n.availabilityStatus,
                          l10n.available,
                          l10n.openForBookings,
                          AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildToggleCard(
                          l10n.vacationMode,
                          l10n.pauseBookingsDescription,
                          _isVacationMode,
                          (val) => setState(() => _isVacationMode = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildQuickAction(Icons.access_time, l10n.workingHours, AppColors.primary, onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.workingHoursDescription)))),
                      _buildQuickAction(Icons.calendar_today, l10n.unavailableDays, AppColors.error, onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.unavailableDaysDescription)))),
                      _buildQuickAction(Icons.local_cafe, l10n.breakTimes, AppColors.warning, onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.breakTimesDescription)))),
                      _buildQuickAction(Icons.warning, l10n.emergencyAvailability, AppColors.success, onTap: () async {
  final user = supabase.auth.currentUser;
  if (user == null) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final data = await supabase.from('profiles').select('is_emergency').eq('id', user.id).single();
    final currentValue = data['is_emergency'] as bool? ?? false;
    await supabase.from('profiles').update({'is_emergency': !currentValue}).eq('id', user.id);
    if (mounted) {
      setState(() => _emergencyAvailability = !currentValue);
      messenger.showSnackBar(SnackBar(
        content: Text(!currentValue ? l10n.emergencyAvailabilityEnabled : l10n.emergencyAvailabilityDisabled),
        backgroundColor: AppColors.success,
      ));
    }
  } catch (e) {
    if (mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.failedToSaveSchedule), backgroundColor: AppColors.error));
    }
  }
}),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLightOf(context)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.language, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.timezoneLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context))),
                              Text(_timezone, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.textTertiaryOf(context), size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionHeader(l10n.weeklyWorkingHours, onAction: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.scheduleCopiedToAllDays)),
                    );
                  }, actionLabel: l10n.copyToAll, actionIcon: Icons.content_copy),
                  const SizedBox(height: 16),
                  ...weeklyHours.map((day) => _buildDayRow(day)),
                  const SizedBox(height: 32),

                  _buildSectionHeader(l10n.breakTimesDaily, onAction: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.breakTimeAdded)),
                    );
                  }, actionLabel: l10n.addBreak, actionIcon: Icons.add),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: breakTimes.map((brk) => _buildBreakCard(brk)).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: _buildActionToggleCard(
                          l10n.emergencyAvailability,
                          l10n.allowEmergencyBookingsOutside,
                          _emergencyAvailability,
                          (val) => setState(() => _emergencyAvailability = val),
                          footer: Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.verified, color: AppColors.success, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.emergencyRate5xNormal,
                                    style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionToggleCard(
                          l10n.autoAcceptBookings,
                          l10n.autoAcceptDescription,
                          _autoAccept,
                          (val) => setState(() => _autoAccept = val),
                          footer: Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: AppColors.primary, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.notifiedOfAllNewBookings,
                                    style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ElevatedButton(
                onPressed: _isSaving ? null : _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.textInverse, strokeWidth: 2))
                    : Text(l10n.saveSchedule, style: const TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
          const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(String title, String status, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          Text(sub, style: TextStyle(fontSize: 10, color: AppColors.textTertiaryOf(context))),
        ],
      ),
    );
  }

  Widget _buildToggleCard(String title, String sub, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context))),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(sub, style: TextStyle(fontSize: 10, color: AppColors.textTertiaryOf(context))),
        ],
      ),
    );
  }

  Widget _buildActionToggleCard(String title, String sub, bool value, Function(bool) onChanged, {Widget? footer}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context)))),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 10, color: AppColors.textTertiaryOf(context))),
          ?footer,
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondaryOf(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onAction, required String actionLabel, required IconData actionIcon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context), letterSpacing: -0.5)),
        TextButton.icon(
          onPressed: onAction,
          icon: Icon(actionIcon, size: 14, color: AppColors.primary),
          label: Text(actionLabel, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildDayRow(Map<String, dynamic> day) {
    bool enabled = day['enabled'];
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              day['day'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: enabled ? AppColors.textPrimaryOf(context) : AppColors.textTertiaryOf(context),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: enabled,
              onChanged: (val) => setState(() => day['enabled'] = val),
              activeThumbColor: AppColors.success,
            ),
          ),
          const Spacer(),
          if (enabled) ...[
            _buildTimePicker(day['start']),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(l10n.timeConnector, style: TextStyle(fontSize: 12, color: AppColors.textTertiaryOf(context))),
            ),
            _buildTimePicker(day['end']),
          ] else
            Text(l10n.unavailableStatus, style: TextStyle(fontSize: 14, color: AppColors.textTertiaryOf(context), fontStyle: FontStyle.italic)),
          const SizedBox(width: 8),
          Icon(Icons.add, size: 18, color: AppColors.slate300),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Row(
        children: [
          Text(time, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimaryOf(context))),
          const SizedBox(width: 4),
          Icon(Icons.expand_more, size: 14, color: AppColors.textTertiaryOf(context)),
        ],
      ),
    );
  }

  Widget _buildBreakCard(Map<String, String> brk) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
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
              Text(brk['time']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
              const SizedBox(width: 12),
              Icon(Icons.delete, size: 16, color: AppColors.error),
            ],
          ),
          const SizedBox(height: 4),
          Text(brk['label']!, style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
