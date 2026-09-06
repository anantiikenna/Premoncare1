import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import 'admin_avatar.dart';
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
                const SnackBar(
                  content: Text(
                    'New users register through the patient portal. Send them the registration link.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          _QuickActionBtn(
            icon: Icons.content_copy,
            label: 'Bulk Actions',
            color: AppColors.textSecondaryOf(context),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Bulk actions are being developed. Manage users individually through the list above.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          _QuickActionBtn(
            icon: Icons.download,
            label: 'Export Users',
            color: AppColors.textSecondaryOf(context),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Export is being developed. Use your device\'s screenshot feature to save user data.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          _QuickActionBtn(
            icon: Icons.person_add,
            label: 'Invite User',
            color: AppColors.textSecondaryOf(context),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Invitations are sent automatically when users register. Direct them to the signup page.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          _QuickActionBtn(
            icon: Icons.description,
            label: 'User Logs',
            color: AppColors.textSecondaryOf(context),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Audit logs are being developed. All admin actions are tracked in the system for compliance.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;
    final adminService = ref.watch(adminServiceProvider);

    return AdminScaffold(
      selectedIndex: 1,
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimaryOf(context),
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View, manage and take actions on all platform users',
                      style: TextStyle(
                        color: AppColors.textSecondaryOf(context),
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
                icon: Icons.people,
                color: AppColors.primary,
              ),
              _StatCard(
                label: 'Doctors',
                value: stats['doctors'].toString(),
                icon: Icons.medical_services,
                color: AppColors.success,
              ),
              _StatCard(
                label: 'Patients',
                value: stats['patients'].toString(),
                icon: Icons.person,
                color: AppColors.primary,
              ),
              _StatCard(
                label: 'Pending',
                value: stats['pending'].toString(),
                icon: Icons.access_time,
                color: AppColors.warning,
              ),
              _StatCard(
                label: 'Suspended',
                value: stats['suspended'].toString(),
                icon: Icons.warning,
                color: AppColors.error,
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
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLightOf(context)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppColors.textTertiaryOf(context),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email or phone...',
                      hintStyle: TextStyle(
                        color: AppColors.textTertiaryOf(context),
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
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLightOf(context)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.filter_list,
                color: AppColors.textPrimaryOf(context),
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
      unselectedLabelColor: AppColors.textSecondaryOf(context),
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
    final isPrimary = color == AppColors.primary;

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : AppColors.surfaceOf(context),
        foregroundColor: isPrimary ? AppColors.textInverse : color,
        elevation: 0,
        side: isPrimary
            ? BorderSide.none
            : BorderSide(color: AppColors.borderLightOf(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
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
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
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
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
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
    final statusColor = _getStatusColor(
      user['account_status'] ?? 'active',
      context,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              AdminAvatar(
                imageUrl: user['avatar_url'] as String?,
                name: (user['full_name'] ?? 'U').toString(),
                radius: 26,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: user['is_online'] == true
                        ? AppColors.success
                        : AppColors.textTertiaryOf(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceOf(context),
                      width: 2,
                    ),
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RoleBadge(role: user['role'] ?? 'patient'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] ?? 'email@example.com',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: USR-${(user['id'] as String).substring(0, 5).toUpperCase()}',
                  style: TextStyle(
                    color: AppColors.textTertiaryOf(context),
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
                icon: Icon(
                  Icons.more_horiz,
                  color: AppColors.textTertiaryOf(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'suspended':
        return AppColors.error;
      default:
        return AppColors.textSecondaryOf(context);
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
        color: AppColors.borderLightOf(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: AppColors.textSecondaryOf(context),
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
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderOf(context),
              borderRadius: BorderRadius.circular(8),
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
            style: TextStyle(
              color: AppColors.textSecondaryOf(context),
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
                ? AppColors.success
                : AppColors.warning,
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
            color: AppColors.error,
            onTap: () {
              adminService.updateUserAccountStatus(user['id'], 'banned');
              Navigator.pop(context);
            },
          ),
          _ActionTile(
            icon: Icons.edit,
            label: 'Edit Profile Information',
            onTap: () {
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
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _ActionTile(
            icon: Icons.bolt,
            label: 'Emergency Intervention',
            color: AppColors.warning,
            onTap: () {
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
    final finalColor = color ?? AppColors.textPrimaryOf(context);

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
