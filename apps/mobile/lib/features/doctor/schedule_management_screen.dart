import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/widgets/global_user_avatar.dart';
import '../../../core/supabase_locator.dart';

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
  final String _timezone = '(GMT+1) West Africa Time (WAT)';
  
  final List<Map<String, dynamic>> _weeklyHours = [
    {'day': 'Monday', 'enabled': true, 'start': '08:00 AM', 'end': '06:00 PM'},
    {'day': 'Tuesday', 'enabled': true, 'start': '08:00 AM', 'end': '06:00 PM'},
    {'day': 'Wednesday', 'enabled': true, 'start': '08:00 AM', 'end': '06:00 PM'},
    {'day': 'Thursday', 'enabled': true, 'start': '08:00 AM', 'end': '06:00 PM'},
    {'day': 'Friday', 'enabled': true, 'start': '08:00 AM', 'end': '05:00 PM'},
    {'day': 'Saturday', 'enabled': false, 'start': '09:00 AM', 'end': '01:00 PM'},
    {'day': 'Sunday', 'enabled': false, 'start': 'Unavailable', 'end': ''},
  ];

  final List<Map<String, String>> _breakTimes = [
    {'label': 'Lunch Break', 'time': '12:00 PM - 01:00 PM'},
    {'label': 'Short Break', 'time': '04:00 PM - 04:15 PM'},
    {'label': 'Personal Time', 'time': '07:30 PM - 08:00 PM'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    // In a real app, fetch from doctor_schedules table
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Doctor Availability & Schedule',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, color: Color(0xFF1E293B)),
            onPressed: () => context.push('/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile coming soon')),
                );
              },
              child: const GlobalUserAvatar(radius: 18),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage your working hours, availability and preferences',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // Status Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'Availability Status',
                          'Available',
                          'You are open for bookings',
                          const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildToggleCard(
                          'Vacation Mode',
                          'Turn on to pause bookings',
                          _isVacationMode,
                          (val) => setState(() => _isVacationMode = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Grid Actions
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildQuickAction(LucideIcons.clock, 'Working Hours', const Color(0xFF8B5CF6)),
                      _buildQuickAction(LucideIcons.calendar, 'Unavailable Days', const Color(0xFFEF4444)),
                      _buildQuickAction(LucideIcons.coffee, 'Break Times', const Color(0xFFF59E0B)),
                      _buildQuickAction(LucideIcons.alertCircle, 'Emergency Availability', const Color(0xFF10B981)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Timezone
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.globe, color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Timezone', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              Text(_timezone, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, color: Color(0xFF94A3B8), size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Weekly Working Hours
                  _buildSectionHeader('Weekly Working Hours', onAction: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Schedule hours copied to all days')),
                    );
                  }, actionLabel: 'Copy to all', actionIcon: LucideIcons.copy),
                  const SizedBox(height: 16),
                  ..._weeklyHours.map((day) => _buildDayRow(day)),
                  const SizedBox(height: 32),

                  // Break Times
                  _buildSectionHeader('Break Times (Daily)', onAction: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Break time added')),
                    );
                  }, actionLabel: 'Add Break', actionIcon: LucideIcons.plus),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _breakTimes.map((brk) => _buildBreakCard(brk)).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Emergency & Auto-Accept
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionToggleCard(
                          'Emergency Availability',
                          'Allow emergency bookings outside regular hours',
                          _emergencyAvailability,
                          (val) => setState(() => _emergencyAvailability = val),
                          footer: Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Emergency rate: 5x normal rate',
                                    style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
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
                          'Auto-Accept Bookings',
                          'Automatically accept new bookings within your working hours',
                          _autoAccept,
                          (val) => setState(() => _autoAccept = val),
                          footer: Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(LucideIcons.info, color: primaryColor, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You will be notified of all new bookings',
                                    style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
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
                onPressed: () async {
                  final user = supabase.auth.currentUser;
                  if (user == null) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Schedule saved successfully ✓'), backgroundColor: Color(0xFF10B981)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F62FE),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
          Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildToggleCard(String title, String sub, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: const Color(0xFF0F62FE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildActionToggleCard(String title, String sub, bool value, Function(bool) onChanged, {Widget? footer}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: const Color(0xFF0F62FE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ?footer,
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Column(
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
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onAction, required String actionLabel, required IconData actionIcon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
        TextButton.icon(
          onPressed: onAction,
          icon: Icon(actionIcon, size: 14, color: const Color(0xFF0F62FE)),
          label: Text(actionLabel, style: const TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildDayRow(Map<String, dynamic> day) {
    bool enabled = day['enabled'];
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
                color: enabled ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: enabled,
              onChanged: (val) => setState(() => day['enabled'] = val),
              activeThumbColor: const Color(0xFF10B981),
            ),
          ),
          const Spacer(),
          if (enabled) ...[
            _buildTimePicker(day['start']),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('to', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ),
            _buildTimePicker(day['end']),
          ] else
            const Text('Unavailable', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
          const SizedBox(width: 8),
          const Icon(LucideIcons.plus, size: 18, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(width: 4),
          const Icon(LucideIcons.chevronDown, size: 14, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildBreakCard(Map<String, String> brk) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(brk['time']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const SizedBox(width: 12),
              const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 4),
          Text(brk['label']!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
