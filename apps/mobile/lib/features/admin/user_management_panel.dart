import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_providers.dart';
import 'admin_scaffold.dart';

class UserManagementPanel extends ConsumerStatefulWidget {
  const UserManagementPanel({super.key});

  @override
  ConsumerState<UserManagementPanel> createState() =>
      _UserManagementPanelState();
}

class _UserManagementPanelState extends ConsumerState<UserManagementPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedRole = [
          'all',
          'doctor',
          'patient',
          'admin',
        ][_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildQuickActionStrip(Color primaryColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _QuickActionBtn(
            icon: Icons.add,
            label: 'Add User',
            color: primaryColor,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New users register through the patient portal. Send them the registration link.')),
              );
            },
          ),
          const SizedBox(width: 12),
          _QuickActionBtn(
            icon: Icons.content_copy,
            label: 'Bulk Actions',
            color: const Color(0xFF64748B),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bulk actions are being developed. Manage users individually through the list above.')),
              );
            },
          ),
          const SizedBox(width: 12),
          _QuickActionBtn(
            icon: Icons.download,
            label: 'Export Users',
            color: const Color(0xFF64748B),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export is being developed. Use your device\'s screenshot feature to save user data.')),
              );
            },
          ),
          const SizedBox(width: 12),
          _QuickActionBtn(
            icon: Icons.person_add,
            label: 'Invite User',
            color: const Color(0xFF64748B),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invitations are sent automatically when users register. Direct them to the signup page.')),
              );
            },
          ),
          const SizedBox(width: 12),
          _QuickActionBtn(
            icon: Icons.description,
            label: 'User Logs',
            color: const Color(0xFF64748B),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audit logs are being developed. All admin actions are tracked in the system for compliance.')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F62FE);
    final adminService = ref.watch(adminServiceProvider);

    return AdminScaffold(
      selectedIndex: 1,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'View, manage and take actions on all platform users',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStatsGrid(adminService),
                  const SizedBox(height: 24),
                  _buildQuickActionStrip(primaryColor),
                  const SizedBox(height: 24),
                  _buildSearchAndFilter(primaryColor),
                  const SizedBox(height: 24),
                  _buildTabHeader(primaryColor),
                ],
              ),
            ),
          ),
          _buildUserList(adminService),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic adminService) {
    return FutureBuilder<Map<String, dynamic>>(
      future: adminService.getUserManagementStats(),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ??
            {
              'total': 0,
              'doctors': 0,
              'patients': 0,
              'pending': 0,
              'suspended': 0,
            };

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _StatCard(
                label: 'Total Users',
                value: stats['total'].toString(),
                trend: '+18.6%',
                icon: Icons.people,
                color: const Color(0xFF0F62FE),
              ),
              _StatCard(
                label: 'Doctors',
                value: stats['doctors'].toString(),
                trend: '+14.2%',
                icon: Icons.medical_services,
                color: const Color(0xFF10B981),
              ),
              _StatCard(
                label: 'Patients',
                value: stats['patients'].toString(),
                trend: '+19.3%',
                icon: Icons.person,
                color: const Color(0xFF8B5CF6),
              ),
              _StatCard(
                label: 'Pending',
                value: stats['pending'].toString(),
                trend: '-6.1%',
                icon: Icons.access_time,
                color: const Color(0xFFF59E0B),
              ),
              _StatCard(
                label: 'Suspended',
                value: stats['suspended'].toString(),
                trend: '-3.4%',
                icon: Icons.warning,
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilter(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: const Color(0xFF94A3B8),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Search by name, email or phone...',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.filter_list,
                color: const Color(0xFF1E293B),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Filters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabHeader(Color primaryColor) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: primaryColor,
      unselectedLabelColor: const Color(0xFF64748B),
      indicatorColor: primaryColor,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      tabs: const [
        Tab(text: 'All Users'),
        Tab(text: 'Doctors'),
        Tab(text: 'Patients'),
        Tab(text: 'Admins'),
      ],
    );
  }

  Widget _buildUserList(dynamic adminService) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: adminService.getUsers(
        role: _selectedRole,
        searchQuery: _searchQuery,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final users = snapshot.data ?? [];

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _UserListItem(user: users[index]),
              childCount: users.length,
            ),
          ),
        );
      },
    );
  }

}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = color == const Color(0xFF0F62FE);

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : Colors.white,
        foregroundColor: isPrimary ? Colors.white : color,
        elevation: 0,
        side: isPrimary ? BorderSide.none : BorderSide(color: Colors.grey.shade200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                trend.startsWith('+')
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: trend.startsWith('+')
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  color: trend.startsWith('+')
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(user['account_status'] ?? 'active');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.15),
                child: Text(
                  (user['full_name'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF0F62FE),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: user['is_online'] == true
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
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
                Row(
                  children: [
                    Text(
                      user['full_name'] ?? 'User Name',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RoleBadge(role: user['role'] ?? 'patient'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] ?? 'email@example.com',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: USR-${(user['id'] as String).substring(0, 5).toUpperCase()}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(
                status: user['account_status'] ?? 'active',
                color: statusColor,
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: () => _showActionSheet(context, user),
                icon: const Icon(
                  Icons.more_horiz,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'suspended':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _showActionSheet(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserActionSheet(user: user),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _UserActionSheet extends ConsumerWidget {
  final Map<String, dynamic> user;
  const _UserActionSheet({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminService = ref.watch(adminServiceProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'User Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage account for ${user['full_name']}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          _ActionTile(
            icon: Icons.block,
            label: user['account_status'] == 'suspended'
                ? 'Activate Account'
                : 'Suspend Account',
            color: user['account_status'] == 'suspended'
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
            onTap: () {
              adminService.updateUserAccountStatus(
                user['id'],
                user['account_status'] == 'suspended' ? 'active' : 'suspended',
              );
              Navigator.pop(context);
            },
          ),
          _ActionTile(
            icon: Icons.gpp_bad,
            label: 'Ban Account (Permanent)',
            color: const Color(0xFFEF4444),
            onTap: () {
              adminService.updateUserAccountStatus(user['id'], 'banned');
              Navigator.pop(context);
            },
          ),
          _ActionTile(
            icon: Icons.edit,
            label: 'Edit Profile Information',
            onTap: () {
              // Navigate to edit profile
              Navigator.pop(context);
            },
          ),
          _ActionTile(
            icon: Icons.refresh,
            label: 'Reset Verification State',
            onTap: () {
              adminService.resetVerification(user['id']);
              Navigator.pop(context);
            },
          ),
          _ActionTile(
            icon: Icons.visibility,
            label: 'Impersonate / Support View',
            color: const Color(0xFF0F62FE),
            onTap: () {
              // Implementation of support mode
              Navigator.pop(context);
            },
          ),
          _ActionTile(
            icon: Icons.bolt,
            label: 'Emergency Intervention',
            color: const Color(0xFFF59E0B),
            onTap: () {
              // Implementation of emergency override
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final finalColor = color ?? const Color(0xFF1E293B);

    return ListTile(
      leading: Icon(icon, color: finalColor, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: finalColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }
}
