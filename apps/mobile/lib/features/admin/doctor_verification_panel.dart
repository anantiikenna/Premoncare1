import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/services/admin_service.dart';
import 'admin_scaffold.dart';

final _adminService = AdminService();

enum _TabStatus { pending, underReview, verified, rejected }

class DoctorVerificationPanel extends ConsumerStatefulWidget {
  const DoctorVerificationPanel({super.key});

  @override
  ConsumerState<DoctorVerificationPanel> createState() => _DoctorVerificationPanelState();
}

class _DoctorVerificationPanelState extends ConsumerState<DoctorVerificationPanel> {
  _TabStatus _selectedTab = _TabStatus.pending;
  String _searchQuery = '';
  Map<String, dynamic>? _selectedDoctor;
  bool _doctorsLoading = false;

  List<Map<String, dynamic>> _doctors = [];
  Map<String, int> _counts = {'pending': 0, 'under_review': 0, 'approved': 0, 'rejected': 0};

  final _searchController = TextEditingController();
  final _adminNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  String get _statusFilter {
    switch (_selectedTab) {
      case _TabStatus.pending:
        return 'pending';
      case _TabStatus.underReview:
        return 'under_review';
      case _TabStatus.verified:
        return 'approved';
      case _TabStatus.rejected:
        return 'rejected';
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_fetchDoctors(), _fetchCounts()]);
  }

  Future<void> _fetchDoctors() async {
    setState(() => _doctorsLoading = true);
    try {
      final client = Supabase.instance.client;
      var query = client.from('profiles').select().eq('role', 'doctor');

      if (_selectedTab == _TabStatus.pending || _selectedTab == _TabStatus.underReview) {
        query = query.eq('verification_status', _statusFilter);
      } else if (_selectedTab == _TabStatus.verified) {
        query = query.eq('verification_status', 'approved');
      } else {
        query = query.eq('verification_status', 'rejected');
      }

      if (_searchQuery.isNotEmpty) {
        query = query.or('full_name.ilike.%$_searchQuery%,email.ilike.%$_searchQuery%');
      }

      final response = await query.order('created_at', ascending: false);
      if (mounted) {
        setState(() => _doctors = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load doctors: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _doctorsLoading = false);
    }
  }

  Future<void> _fetchCounts() async {
    try {
      final client = Supabase.instance.client;
      final pending = await client.from('profiles').select('id').eq('role', 'doctor').eq('verification_status', 'pending').count();
      final underReview = await client.from('profiles').select('id').eq('role', 'doctor').eq('verification_status', 'under_review').count();
      final approved = await client.from('profiles').select('id').eq('role', 'doctor').eq('verification_status', 'approved').count();
      final rejected = await client.from('profiles').select('id').eq('role', 'doctor').eq('verification_status', 'rejected').count();
      if (mounted) {
        setState(() {
          _counts = {
            'pending': pending.count,
            'under_review': underReview.count,
            'approved': approved.count,
            'rejected': rejected.count,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load counts: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
    }
  }

  void _selectDoctor(Map<String, dynamic> doctor) {
    setState(() => _selectedDoctor = doctor);
  }

  void _deselectDoctor() {
    setState(() => _selectedDoctor = null);
  }

  void _switchTab(_TabStatus tab) {
    setState(() {
      _selectedTab = tab;
      _selectedDoctor = null;
    });
    _fetchDoctors();
  }

  Future<void> _approveDoctor(Map<String, dynamic> doctor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            SizedBox(width: 12),
            Text('Approve Doctor?', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.slate800, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to approve ${doctor['full_name'] ?? 'this doctor'}? This will immediately grant them practitioner access and operational scheduling capabilities.',
          style: const TextStyle(color: AppColors.slate500, height: 1.5, fontSize: 13),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _doctorsLoading = true);
      try {
        await _adminService.updateVerificationStatus(doctor['id'], 'approved');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doctor verified successfully!'), backgroundColor: AppColors.success),
          );
          _deselectDoctor();
          _refreshAll();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _doctorsLoading = false);
      }
    }
  }

  Future<void> _rejectDoctor(Map<String, dynamic> doctor) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text('Reject Application', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.slate800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejecting this application. This will be sent to the user.',
              style: TextStyle(color: AppColors.slate500, height: 1.5, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection...',
                hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 13),
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _doctorsLoading = true);
      try {
        await _adminService.updateVerificationStatus(doctor['id'], 'rejected', reason: reasonController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application rejected.'), backgroundColor: AppColors.error),
          );
          _deselectDoctor();
          _refreshAll();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        reasonController.dispose();
        if (mounted) setState(() => _doctorsLoading = false);
      }
    }
  }

  Future<void> _requestMoreInfo(Map<String, dynamic> doctor) async {
    final infoController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.help_rounded, color: AppColors.warning),
            SizedBox(width: 12),
            Text('Request Information', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.slate800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What additional information do you need from the applicant?',
              style: TextStyle(color: AppColors.slate500, height: 1.5, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: infoController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'E.g. Please upload a clearer copy of your Medical License.',
                hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 13),
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _doctorsLoading = true);
      try {
        await _adminService.updateVerificationStatus(doctor['id'], 'under_review', reason: infoController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Information request sent. Status set to Under Review.'), backgroundColor: AppColors.warning),
          );
          _deselectDoctor();
          _refreshAll();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        infoController.dispose();
        if (mounted) setState(() => _doctorsLoading = false);
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'under_review':
        return AppColors.info;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.slate400;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'under_review':
        return 'Under Review';
      case 'approved':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      case 'unsubmitted':
        return 'Unsubmitted';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 2,
      body: _selectedDoctor != null
          ? _buildDetailView()
          : _buildListView(),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildTabFilters(),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildDoctorsList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    final doctor = _selectedDoctor!;
    final metadata = doctor['metadata'] as Map<String, dynamic>? ?? {};
    final documents = (metadata['documents'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _deselectDoctor,
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('Back to Queue', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDoctorProfileCard(doctor),
          const SizedBox(height: 32),
          _buildSectionHeader('Submitted Documents'),
          const SizedBox(height: 16),
          _buildDocumentsGrid(documents),
          const SizedBox(height: 32),
          _buildSectionHeader('Application Details'),
          const SizedBox(height: 16),
          _buildDetailsGrid(doctor, metadata),
          const SizedBox(height: 32),
          _buildAdminNotes(),
          const SizedBox(height: 32),
          _buildActionButtons(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTabFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabItem(
            label: 'Pending',
            count: '${_counts['pending'] ?? 0}',
            isSelected: _selectedTab == _TabStatus.pending,
            color: AppColors.warning,
            onTap: () => _switchTab(_TabStatus.pending),
          ),
          const SizedBox(width: 12),
          _TabItem(
            label: 'Under Review',
            count: '${_counts['under_review'] ?? 0}',
            isSelected: _selectedTab == _TabStatus.underReview,
            color: AppColors.info,
            onTap: () => _switchTab(_TabStatus.underReview),
          ),
          const SizedBox(width: 12),
          _TabItem(
            label: 'Verified',
            count: '${_counts['approved'] ?? 0}',
            isSelected: _selectedTab == _TabStatus.verified,
            color: AppColors.success,
            onTap: () => _switchTab(_TabStatus.verified),
          ),
          const SizedBox(width: 12),
          _TabItem(
            label: 'Rejected',
            count: '${_counts['rejected'] ?? 0}',
            isSelected: _selectedTab == _TabStatus.rejected,
            color: AppColors.error,
            onTap: () => _switchTab(_TabStatus.rejected),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _fetchDoctors(),
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800),
              decoration: InputDecoration(
                icon: const Icon(Icons.search_rounded, color: AppColors.slate400, size: 20),
                border: InputBorder.none,
                hintText: 'Search by name or email...',
                hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 13, fontWeight: FontWeight.w600),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.slate400, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _fetchDoctors();
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _fetchDoctors,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: _doctorsLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.tune_rounded, color: AppColors.slate600, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(label: 'Pending', count: '${_counts['pending'] ?? 0}', color: AppColors.warning),
        const SizedBox(width: 12),
        _StatCard(label: 'In Review', count: '${_counts['under_review'] ?? 0}', color: AppColors.info),
        const SizedBox(width: 12),
        _StatCard(label: 'Approved', count: '${_counts['approved'] ?? 0}', color: AppColors.success),
        const SizedBox(width: 12),
        _StatCard(label: 'Rejected', count: '${_counts['rejected'] ?? 0}', color: AppColors.error),
      ],
    );
  }

  Widget _buildDoctorsList() {
    if (_doctorsLoading && _doctors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_doctors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: AppColors.success.withValues(alpha: 0.5), size: 48),
              const SizedBox(height: 16),
              const Text('No doctors found', style: TextStyle(color: AppColors.slate500, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('All caught up for this category!', style: TextStyle(color: AppColors.slate400, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _doctors.map((doctor) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildDoctorListCard(doctor),
      )).toList(),
    );
  }

  Widget _buildDoctorListCard(Map<String, dynamic> doctor) {
    final name = doctor['full_name'] ?? 'Unknown';
    final email = doctor['email'] ?? '';
    final specialty = doctor['specialty'] ?? 'General';
    final status = doctor['verification_status'] ?? 'pending';
    final createdAt = doctor['created_at'] != null ? DateTime.tryParse(doctor['created_at']) : null;
    final color = _statusColor(status);

    return GestureDetector(
      onTap: () => _selectDoctor(doctor),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [BoxShadow(color: AppColors.shadowLight, blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surface, width: 2)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status == 'pending' ? Icons.hourglass_bottom_rounded
                              : status == 'under_review' ? Icons.search_rounded
                              : status == 'approved' ? Icons.check_rounded
                              : Icons.cancel_rounded,
                          color: Colors.white, size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(_statusLabel(status), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. $name', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                  const SizedBox(height: 2),
                  Text(specialty, style: const TextStyle(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AppColors.slate400, size: 13),
                      const SizedBox(width: 6),
                      Expanded(child: Text(email, style: const TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (createdAt != null)
                  Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: const TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.slate400, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorProfileCard(Map<String, dynamic> doctor) {
    final name = doctor['full_name'] ?? 'Unknown';
    final email = doctor['email'] ?? '';
    final phone = doctor['phone'] ?? '';
    final specialty = doctor['specialty'] ?? 'General';
    final status = doctor['verification_status'] ?? 'pending';
    final createdAt = doctor['created_at'] != null ? DateTime.tryParse(doctor['created_at']) : null;
    final id = doctor['id'] ?? '';
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surface, width: 2)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status == 'pending' ? Icons.hourglass_bottom_rounded
                                : status == 'under_review' ? Icons.search_rounded
                                : status == 'approved' ? Icons.check_rounded
                                : Icons.cancel_rounded,
                            color: Colors.white, size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(_statusLabel(status), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dr. $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                              const SizedBox(height: 2),
                              Text(specialty, style: const TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('User ID', style: TextStyle(fontSize: 10, color: AppColors.slate400, fontWeight: FontWeight.w700)),
                            Text(id.toString().substring(0, 8), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.slate800)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (email.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, color: AppColors.slate400, size: 14),
                          const SizedBox(width: 8),
                          Text(email, style: const TextStyle(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, color: AppColors.slate400, size: 14),
                          const SizedBox(width: 8),
                          Text(phone, style: const TextStyle(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          createdAt != null ? 'Applied on: ${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}' : 'Application date unknown',
                          style: const TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsGrid(List<dynamic> documents) {
    if (documents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Column(
          children: [
            Icon(Icons.folder_off_outlined, color: AppColors.slate300, size: 40),
            SizedBox(height: 12),
            Text('No documents submitted', style: TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('The applicant has not uploaded any documents yet.', style: TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: documents.map<Widget>((doc) {
        final docMap = doc is Map<String, dynamic> ? doc : {};
        final title = docMap['title'] ?? docMap['name'] ?? 'Document';
        final fileName = docMap['file_name'] ?? docMap['url'] ?? 'file';
        final isVerified = docMap['verified'] == true;
        return _DocumentCard(title: title, fileName: fileName, isVerified: isVerified, color: AppColors.primary);
      }).toList(),
    );
  }

  Widget _buildDetailsGrid(Map<String, dynamic> doctor, Map<String, dynamic> metadata) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _DetailItem(icon: Icons.person_outline_rounded, label: 'Full Name', value: 'Dr. ${doctor['full_name'] ?? 'N/A'}')),
              Expanded(child: _DetailItem(icon: Icons.badge_outlined, label: 'License Number', value: metadata['license_number'] ?? 'N/A')),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _DetailItem(icon: Icons.cake_outlined, label: 'Date of Birth', value: metadata['date_of_birth'] ?? 'N/A')),
              Expanded(child: _DetailItem(icon: Icons.location_on_outlined, label: 'Issuing State', value: metadata['issuing_state'] ?? 'N/A')),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _DetailItem(icon: Icons.transgender_rounded, label: 'Gender', value: metadata['gender'] ?? 'N/A')),
              Expanded(child: _DetailItem(icon: Icons.work_outline_rounded, label: 'Years of Experience', value: metadata['years_of_experience'] ?? 'N/A')),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _DetailItem(icon: Icons.medical_services_outlined, label: 'Specialization', value: doctor['specialty'] ?? 'N/A')),
              Expanded(child: _DetailItem(icon: Icons.apartment_rounded, label: 'Practice Type', value: metadata['practice_type'] ?? 'N/A')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Admin Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.slate800, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: TextField(
            controller: _adminNotesController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.slate800, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: 'Add a note (optional)...',
              hintStyle: TextStyle(color: AppColors.slate400, fontSize: 13, fontWeight: FontWeight.w600),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_selectedDoctor == null) return const SizedBox.shrink();
    final doctor = _selectedDoctor!;
    final status = doctor['verification_status'];
    final canApprove = status == 'pending' || status == 'under_review';
    final canReject = status == 'pending' || status == 'under_review';

    return Column(
      children: [
        if (status == 'pending') ...[
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Reject Application',
                  color: AppColors.error,
                  icon: Icons.cancel_outlined,
                  onTap: canReject ? () => _rejectDoctor(doctor) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Request More Info',
                  color: AppColors.warning,
                  icon: Icons.help_outline_rounded,
                  onTap: canReject ? () => _requestMoreInfo(doctor) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Approve & Verify',
                  color: AppColors.success,
                  icon: Icons.check_circle_outline_rounded,
                  onTap: canApprove ? () => _approveDoctor(doctor) : null,
                ),
              ),
            ],
          ),
        ],
        if (status == 'under_review') ...[
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Reject',
                  color: AppColors.error,
                  icon: Icons.cancel_outlined,
                  onTap: () => _rejectDoctor(doctor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Approve & Verify',
                  color: AppColors.success,
                  icon: Icons.check_circle_outline_rounded,
                  onTap: () => _approveDoctor(doctor),
                ),
              ),
            ],
          ),
        ],
        if (status == 'approved')
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Text('This doctor has been verified', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
        if (status == 'rejected')
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
                SizedBox(width: 8),
                Text('This application was rejected', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.slate800, letterSpacing: -0.5));
  }

  String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }
}

// ─── Private Widgets ──────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  final String label;
  final String count;
  final bool isSelected;
  final Color color;
  final VoidCallback? onTap;

  const _TabItem({required this.label, required this.count, required this.isSelected, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color.withValues(alpha: 0.5) : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.timer_outlined, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? color : AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Text(count, style: TextStyle(color: isSelected ? color : AppColors.slate400, fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _StatCard({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String title;
  final String fileName;
  final bool isVerified;
  final Color color;

  const _DocumentCard({required this.title, required this.fileName, required this.isVerified, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.description_rounded, color: AppColors.slate300, size: 40),
                  if (isVerified)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 10),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.slate800)),
          const SizedBox(height: 2),
          Text(fileName, style: const TextStyle(color: AppColors.slate400, fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isVerified ? AppColors.successLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isVerified ? 'Verified' : 'Pending',
              style: TextStyle(color: isVerified ? AppColors.success : AppColors.warning, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.slate400, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.slate800)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionButton({required this.label, required this.color, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: enabled ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: enabled ? 0.2 : 0.1)),
            ),
            child: Icon(icon, color: color.withValues(alpha: enabled ? 1.0 : 0.4), size: 20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color.withValues(alpha: enabled ? 1.0 : 0.4)),
        ),
      ],
    );
  }
}
