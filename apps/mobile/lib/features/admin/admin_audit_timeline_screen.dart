import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_scaffold.dart';

class AdminAuditTimelineScreen extends ConsumerStatefulWidget {
  const AdminAuditTimelineScreen({super.key});

  @override
  ConsumerState<AdminAuditTimelineScreen> createState() => _AdminAuditTimelineScreenState();
}

class _AdminAuditTimelineScreenState extends ConsumerState<AdminAuditTimelineScreen> {
  String _selectedFilter = 'All Logs';
  final List<String> _filters = ['All Logs', 'Verification', 'Payments', 'User Actions', 'Security', 'Emergency', 'System'];

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 4,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeaderRow(),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildFilterChips(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateSortHeader(),
                  const SizedBox(height: 24),
                  _buildTimeline(),
                  const SizedBox(height: 24),
                  _buildFooterAlert(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildHeaderRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF8B5CF6), size: 28),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audit Timeline Viewer',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
              ),
              SizedBox(height: 4),
              Text(
                'Track and review all system activities\nin real-time',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.3),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('LIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text('Monitoring Active', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildStatCard('1,248', 'Admin Actions', 'Today', Icons.person_outline_rounded, const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          _buildStatCard('12', 'Security Alerts', 'Flagged Activities', Icons.verified_user_outlined, const Color(0xFF10B981)),
          const SizedBox(width: 12),
          _buildStatCard('89', 'Financial Reviews', 'Pending Reviews', Icons.account_balance_wallet_outlined, const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          _buildStatCard('4', 'Suspicious Logins', 'High Risk', Icons.warning_amber_rounded, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F62FE) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? const Color(0xFF0F62FE) : const Color(0xFFF1F5F9)),
                boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0F62FE).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSortHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('Today', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(width: 8),
            Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            const Text('18 May 2025', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ],
        ),
        const Row(
          children: [
            Text('Newest First', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F62FE))),
            SizedBox(width: 4),
            Icon(Icons.swap_vert_rounded, color: Color(0xFF0F62FE), size: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        _buildTimelineItem(
          time: '10:42 AM',
          relativeTime: '2 mins ago',
          dotColor: const Color(0xFF10B981),
          child: _buildEventCard(
            title: 'Doctor Verification Approved',
            description: 'Admin Sarah Johnson approved\nDr. Michael Adeyemi\'s KYC verification.',
            icon: Icons.assignment_ind_rounded,
            iconColor: const Color(0xFF10B981),
            badgeText: 'Successful',
            badgeColor: const Color(0xFF10B981),
            metaData: [
              const _EventMeta(label: 'Admin ID:', value: 'ADM-204'),
              const _EventMeta(label: 'IP:', value: '197.210.45.12'),
              const _EventMeta(label: 'Web', icon: Icons.desktop_windows_outlined),
            ],
          ),
        ),
        _buildTimelineItem(
          time: '10:17 AM',
          relativeTime: '27 mins ago',
          dotColor: const Color(0xFF3B82F6),
          child: _buildEventCard(
            title: 'Subscription Payment Approved',
            description: '₦25,000 Premium Plan payment\napproved for Dr. Grace Obi.',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF3B82F6),
            badgeText: 'Financial',
            badgeColor: const Color(0xFF3B82F6),
            metaData: [
              const _EventMeta(label: 'Admin ID:', value: 'ADM-091'),
              const _EventMeta(label: 'IP:', value: '105.28.11.32'),
              const _EventMeta(label: 'Mobile', icon: Icons.phone_android_rounded),
            ],
            actionButton: _buildActionButton(Icons.receipt_long_rounded, 'View Receipt', const Color(0xFF3B82F6)),
          ),
        ),
        _buildTimelineItem(
          time: '09:58 AM',
          relativeTime: '46 mins ago',
          dotColor: const Color(0xFFEF4444),
          child: _buildEventCard(
            title: 'Multiple Login Attempts Detected',
            description: 'Suspicious login activity detected\nfrom new device location.',
            icon: Icons.warning_rounded,
            iconColor: const Color(0xFFEF4444),
            badgeText: 'High Risk',
            badgeColor: const Color(0xFFEF4444),
            metaData: [
              const _EventMeta(label: 'IP:', value: '203.0.113.57'),
              const _EventMeta(label: 'Location:', value: 'Lagos, Nigeria', icon: Icons.location_on_outlined),
            ],
            actionRow: Row(
              children: [
                _buildActionButton(Icons.visibility_rounded, 'View Details', const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                _buildActionButton(Icons.lock_outline_rounded, 'Freeze Account', const Color(0xFF1E293B), isOutlined: true),
              ],
            ),
          ),
        ),
        _buildTimelineItem(
          time: '09:31 AM',
          relativeTime: '1h 13m ago',
          dotColor: const Color(0xFF8B5CF6),
          child: _buildEventCard(
            title: 'Medical Record Accessed',
            description: 'Patient records viewed by\nDr. Ibrahim Musa.',
            icon: Icons.description_rounded,
            iconColor: const Color(0xFF8B5CF6),
            badgeText: 'Info',
            badgeColor: const Color(0xFF8B5CF6),
            metaData: [
              const _EventMeta(label: 'Record ID:', value: 'MRD-77382'),
              const _EventMeta(label: 'Duration:', value: '12 mins'),
              const _EventMeta(label: 'Web', icon: Icons.desktop_windows_outlined),
            ],
          ),
        ),
        _buildTimelineItem(
          time: '08:45 AM',
          relativeTime: '1h 59m ago',
          dotColor: const Color(0xFFF59E0B),
          child: _buildEventCard(
            title: 'Permission Granted',
            description: 'Admin John Admin granted record\naccess to Dr. Adaora Nwosu.',
            icon: Icons.manage_accounts_rounded,
            iconColor: const Color(0xFFF59E0B),
            badgeText: 'Moderate',
            badgeColor: const Color(0xFFF59E0B),
            metaData: [
              const _EventMeta(label: 'Patient ID:', value: 'PAT-89211'),
              const _EventMeta(label: 'Access Type:', value: 'Full Access'),
            ],
          ),
        ),
        _buildTimelineItem(
          time: '08:12 AM',
          relativeTime: '2h 32m ago',
          dotColor: const Color(0xFF10B981),
          isLast: true,
          child: _buildEventCard(
            title: 'System Configuration Updated',
            description: 'Notification settings updated\nby Admin Sarah Johnson.',
            icon: Icons.settings_applications_rounded,
            iconColor: const Color(0xFF10B981),
            badgeText: 'Successful',
            badgeColor: const Color(0xFF10B981),
            metaData: [
              const _EventMeta(label: 'Admin ID:', value: 'ADM-204'),
              const _EventMeta(label: 'Module:', value: 'Notification'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({required String time, required String relativeTime, required Color dotColor, required Widget child, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(relativeTime, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              ],
            ),
          ),
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFF1F5F9),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
    required List<_EventMeta> metaData,
    Widget? actionButton,
    Widget? actionRow,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1.2)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (badgeText == 'Successful') ...[
                                Icon(Icons.check_circle_rounded, color: badgeColor, size: 10),
                                const SizedBox(width: 4),
                              ] else if (badgeText == 'High Risk') ...[
                                Icon(Icons.warning_rounded, color: badgeColor, size: 10),
                                const SizedBox(width: 4),
                              ] else if (badgeText == 'Moderate') ...[
                                Icon(Icons.error_rounded, color: badgeColor, size: 10),
                                const SizedBox(width: 4),
                              ],
                              Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B), height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: metaData.map((meta) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (meta.label.isNotEmpty)
                          Text('${meta.label} ', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600)),
                        if (meta.value != null)
                          Text(meta.value!, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 10, fontWeight: FontWeight.w800)),
                        if (meta.icon != null) ...[
                          if (meta.label.isNotEmpty || meta.value != null) const SizedBox(width: 4),
                          Icon(meta.icon, color: const Color(0xFF94A3B8), size: 12),
                        ],
                        if (meta != metaData.last)
                          Container(
                            margin: const EdgeInsets.only(left: 12),
                            width: 1,
                            height: 10,
                            color: const Color(0xFFE2E8F0),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
            ],
          ),
          if (actionButton != null || actionRow != null) ...[
            const SizedBox(height: 16),
            actionRow ?? actionButton!,
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, {bool isOutlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withValues(alpha: 0.1),
        border: Border.all(color: isOutlined ? const Color(0xFFE2E8F0) : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildFooterAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded, color: Color(0xFF3B82F6), size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'All audit activities are securely stored for compliance and investigation purposes.',
              style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
          Row(
            children: const [
              Text('Learn more', style: TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.w800)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF2563EB), size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventMeta {
  final String label;
  final String? value;
  final IconData? icon;

  const _EventMeta({required this.label, this.value, this.icon});
}
