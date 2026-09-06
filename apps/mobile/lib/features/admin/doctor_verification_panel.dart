import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/doctor_name_utils.dart';
import '../../core/supabase_locator.dart';
import '../../core/services/admin_service.dart';
import 'admin_scaffold.dart';
import 'admin_shared_widgets.dart';

final _adminService = AdminService();

enum _TabStatus { pending, underReview, verified, rejected }

class DoctorVerificationPanel extends ConsumerStatefulWidget {
  final String? selectedDoctorId;
  const DoctorVerificationPanel({super.key, this.selectedDoctorId});

  @override
  ConsumerState<DoctorVerificationPanel> createState() =>
      _DoctorVerificationPanelState();
}

class _DoctorVerificationPanelState
    extends ConsumerState<DoctorVerificationPanel> {
  _TabStatus _selectedTab = _TabStatus.pending;
  String _searchQuery = '';
  Map<String, dynamic>? _selectedDoctor;
  bool _doctorsLoading = false;
  String? _error;

  List<Map<String, dynamic>> _doctors = [];
  Map<String, int> _counts = {
    'pending': 0,
    'under_review': 0,
    'approved': 0,
    'rejected': 0,
  };

  final _searchController = TextEditingController();
  final _adminNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshAll().then((_) {
      if (widget.selectedDoctorId != null) {
        final doc = _doctors.firstWhere(
          (d) => d['id'] == widget.selectedDoctorId,
          orElse: () => <String, dynamic>{},
        );
        if (doc.isNotEmpty) {
          _selectDoctor(doc);
        } else {
          _fetchSelectedDoctorDirectly(widget.selectedDoctorId!);
        }
      }
    });
  }

  Future<void> _fetchSelectedDoctorDirectly(String id) async {
    setState(() => _doctorsLoading = true);
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response != null && mounted) {
        setState(() => _selectedDoctor = response);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _doctorsLoading = false);
    }
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
    setState(() => _error = null);
    await Future.wait([_fetchDoctors(), _fetchCounts()]);
  }

  Future<void> _fetchDoctors() async {
    setState(() => _doctorsLoading = true);
    try {
      final client = Supabase.instance.client;
      var query = client.from('profiles').select().eq('role', 'doctor');

      if (_selectedTab == _TabStatus.pending ||
          _selectedTab == _TabStatus.underReview) {
        query = query.eq('verification_status', _statusFilter);
      } else if (_selectedTab == _TabStatus.verified) {
        query = query.eq('verification_status', 'approved');
      } else {
        query = query.eq('verification_status', 'rejected');
      }

      if (_searchQuery.isNotEmpty) {
        query = query.or(
          'full_name.ilike.%$_searchQuery%,email.ilike.%$_searchQuery%',
        );
      }

      final response = await query.order('created_at', ascending: false);
      if (mounted) {
        setState(() => _doctors = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load doctors: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _doctorsLoading = false);
    }
  }

  Future<void> _fetchCounts() async {
    try {
      final client = Supabase.instance.client;
      final pending = await client
          .from('profiles')
          .select('id')
          .eq('role', 'doctor')
          .eq('verification_status', 'pending')
          .count();
      final underReview = await client
          .from('profiles')
          .select('id')
          .eq('role', 'doctor')
          .eq('verification_status', 'under_review')
          .count();
      final approved = await client
          .from('profiles')
          .select('id')
          .eq('role', 'doctor')
          .eq('verification_status', 'approved')
          .count();
      final rejected = await client
          .from('profiles')
          .select('id')
          .eq('role', 'doctor')
          .eq('verification_status', 'rejected')
          .count();
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
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load counts: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {}
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
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            SizedBox(width: 12),
            Text(
              'Approve Doctor?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryOf(context),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to approve ${doctor['full_name'] ?? 'this doctor'}? This will immediately grant them practitioner access and operational scheduling capabilities.',
          style: TextStyle(
            color: AppColors.textTertiaryOf(context),
            height: 1.5,
            fontSize: 13,
          ),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textTertiaryOf(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Approve',
              style: TextStyle(
                color: AppColors.textInverse,
                fontWeight: FontWeight.bold,
              ),
            ),
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
            const SnackBar(
              content: Text('Doctor verified successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          _deselectDoctor();
          _refreshAll();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
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
        title: Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text(
              'Reject Application',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryOf(context),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for rejecting this application. This will be sent to the user.',
              style: TextStyle(
                color: AppColors.textTertiaryOf(context),
                height: 1.5,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection...',
                hintStyle: TextStyle(
                  color: AppColors.textTertiaryOf(context),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.surfaceAltOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textTertiaryOf(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Reject',
              style: TextStyle(
                color: AppColors.textInverse,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _doctorsLoading = true);
      try {
        await _adminService.updateVerificationStatus(
          doctor['id'],
          'rejected',
          reason: reasonController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application rejected.'),
              backgroundColor: AppColors.error,
            ),
          );
          _deselectDoctor();
          _refreshAll();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
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
        title: Row(
          children: [
            Icon(Icons.help_rounded, color: AppColors.warning),
            SizedBox(width: 12),
            Text(
              'Request Information',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryOf(context),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What additional information do you need from the applicant?',
              style: TextStyle(
                color: AppColors.textTertiaryOf(context),
                height: 1.5,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: infoController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'E.g. Please upload a clearer copy of your Medical License.',
                hintStyle: TextStyle(
                  color: AppColors.textTertiaryOf(context),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.surfaceAltOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textTertiaryOf(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Send Request',
              style: TextStyle(
                color: AppColors.textInverse,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _doctorsLoading = true);
      try {
        await _adminService.updateVerificationStatus(
          doctor['id'],
          'under_review',
          reason: infoController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Information request sent. Status set to Under Review.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
          _deselectDoctor();
          _refreshAll();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
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
        return AppColors.textTertiaryOf(context);
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
      body: _error != null && !_doctorsLoading
          ? AdminErrorState(message: _error!, onRetry: _refreshAll)
          : _selectedDoctor != null
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
                const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Back to Queue',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDoctorProfileCard(doctor),
          const SizedBox(height: 32),
          _buildSectionHeader('Submitted Documents'),
          const SizedBox(height: 16),
          _buildDocumentsGrid(doctor),
          const SizedBox(height: 32),
          _buildIdentityComparison(doctor),
          const SizedBox(height: 32),
          _buildSectionHeader('Application Details'),
          const SizedBox(height: 16),
          _buildDetailsGrid(doctor),
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
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLightOf(context)),
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _fetchDoctors(),
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
              decoration: InputDecoration(
                icon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textTertiaryOf(context),
                  size: 20,
                ),
                border: InputBorder.none,
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(
                  color: AppColors.textTertiaryOf(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textTertiaryOf(context),
                          size: 18,
                        ),
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
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLightOf(context)),
            ),
            child: _doctorsLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    Icons.tune_rounded,
                    color: AppColors.textSecondaryOf(context),
                    size: 20,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(
          label: 'Pending',
          count: '${_counts['pending'] ?? 0}',
          color: AppColors.warning,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'In Review',
          count: '${_counts['under_review'] ?? 0}',
          color: AppColors.info,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Approved',
          count: '${_counts['approved'] ?? 0}',
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Rejected',
          count: '${_counts['rejected'] ?? 0}',
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildDoctorsList() {
    if (_doctorsLoading && _doctors.isEmpty) {
      return const Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_doctors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLightOf(context)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success.withValues(alpha: 0.5),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No doctors found',
                style: TextStyle(
                  color: AppColors.textTertiaryOf(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'All caught up for this category!',
                style: TextStyle(
                  color: AppColors.textTertiaryOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _doctors
          .map(
            (doctor) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDoctorListCard(doctor),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDoctorListCard(Map<String, dynamic> doctor) {
    final name = doctor['full_name'] ?? 'Unknown';
    final doctorTitle = doctor['title'] as String?;
    final displayName = formatDoctorName(doctorTitle, name);
    final email = doctor['email'] ?? '';
    final specialty = doctor['specialty'] ?? 'General';
    final status = doctor['verification_status'] ?? 'pending';
    final createdAt = doctor['created_at'] != null
        ? DateTime.tryParse(doctor['created_at'])
        : null;
    final color = _statusColor(status);

    return GestureDetector(
      onTap: () => _selectDoctor(doctor),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLightOf(context)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
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
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceOf(context), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status == 'pending'
                              ? Icons.hourglass_bottom_rounded
                              : status == 'under_review'
                              ? Icons.search_rounded
                              : status == 'approved'
                              ? Icons.check_rounded
                              : Icons.cancel_rounded,
                          color: AppColors.textInverse,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel(status),
                          style: const TextStyle(
                            color: AppColors.textInverse,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    specialty,
                    style: TextStyle(
                      color: AppColors.textTertiaryOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        color: AppColors.textTertiaryOf(context),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          email,
                          style: TextStyle(
                            color: AppColors.textTertiaryOf(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                    style: TextStyle(
                      color: AppColors.textTertiaryOf(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiaryOf(context),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorProfileCard(Map<String, dynamic> doctor) {
    final name = doctor['full_name'] ?? 'Unknown';
    final doctorTitle = doctor['title'] as String?;
    final displayName = formatDoctorName(doctorTitle, name);
    final email = doctor['email'] ?? '';
    final phone = doctor['phone'] ?? '';
    final specialty = doctor['specialty'] ?? 'General';
    final status = doctor['verification_status'] ?? 'pending';
    final createdAt = doctor['created_at'] != null
        ? DateTime.tryParse(doctor['created_at'])
        : null;
    final id = doctor['id'] ?? '';
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
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
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.surfaceOf(context), width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            status == 'pending'
                                ? Icons.hourglass_bottom_rounded
                                : status == 'under_review'
                                ? Icons.search_rounded
                                : status == 'approved'
                                ? Icons.check_rounded
                                : Icons.cancel_rounded,
                            color: AppColors.textInverse,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel(status),
                            style: const TextStyle(
                              color: AppColors.textInverse,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimaryOf(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                specialty,
                                style: TextStyle(
                                  color: AppColors.textTertiaryOf(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'User ID',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiaryOf(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              id.toString().substring(0, 8),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (email.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: AppColors.textTertiaryOf(context),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            email,
                            style: TextStyle(
                              color: AppColors.textTertiaryOf(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            color: AppColors.textTertiaryOf(context),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            phone,
                            style: TextStyle(
                              color: AppColors.textTertiaryOf(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          createdAt != null
                              ? 'Applied on: ${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}'
                              : 'Application date unknown',
                          style: TextStyle(
                            color: AppColors.textTertiaryOf(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildDocumentsGrid(Map<String, dynamic> doctor) {
    final docs = <_DocItem>[
      if ((doctor['verification_document_url'] as String?)?.isNotEmpty == true)
        _DocItem(
          title: 'Medical License',
          path: doctor['verification_document_url'],
          bucket: 'doctor-verifications',
          icon: Icons.local_hospital_outlined,
        ),
      if ((doctor['identity_document_front_url'] as String?)?.isNotEmpty == true)
        _DocItem(
          title: 'ID Document (Front)',
          path: doctor['identity_document_front_url'],
          bucket: 'doctor-identities',
          icon: Icons.badge_outlined,
        ),
      if ((doctor['identity_document_back_url'] as String?)?.isNotEmpty == true)
        _DocItem(
          title: 'ID Document (Back)',
          path: doctor['identity_document_back_url'],
          bucket: 'doctor-identities',
          icon: Icons.badge_outlined,
        ),
      if ((doctor['address_document_url'] as String?)?.isNotEmpty == true)
        _DocItem(
          title: 'Address Document',
          path: doctor['address_document_url'],
          bucket: 'doctor-identities',
          icon: Icons.home_outlined,
        ),
    ];

    if (docs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLightOf(context)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.folder_off_outlined,
              color: AppColors.textTertiaryOf(context),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'No documents submitted',
              style: TextStyle(
                color: AppColors.textTertiaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'The applicant has not uploaded any documents yet.',
              style: TextStyle(
                color: AppColors.textTertiaryOf(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
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
      children: docs.map((doc) => _DocumentCard(
        title: doc.title,
        fileName: doc.path.split('/').last,
        icon: doc.icon,
        onTap: () => context.push('/document-viewer', extra: {
          'bucket': doc.bucket,
          'path': doc.path,
          'title': doc.title,
        }),
      )).toList(),
    );
  }

  Widget _buildDetailsGrid(Map<String, dynamic> doctor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Full Name',
                  value: formatDoctorName(doctor['title'] as String?, doctor['full_name'] as String?),
                ),
              ),
              Expanded(
                child: _DetailItem(
                  icon: Icons.badge_outlined,
                  label: 'License Number',
                  value: doctor['medical_license_number'] ?? 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  icon: Icons.cake_outlined,
                  label: 'Date of Birth',
                  value: doctor['dob'] ?? 'N/A',
                ),
              ),
              Expanded(
                child: _DetailItem(
                  icon: Icons.transgender_rounded,
                  label: 'Gender',
                  value: doctor['gender'] ?? 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  icon: Icons.work_outline_rounded,
                  label: 'Years of Experience',
                  value: '${doctor['experience_years'] ?? 'N/A'}',
                ),
              ),
              Expanded(
                child: _DetailItem(
                  icon: Icons.medical_services_outlined,
                  label: 'Specialization',
                  value: doctor['specialty'] ?? 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  icon: Icons.badge_outlined,
                  label: 'ID Type',
                  value: doctor['identity_type'] ?? 'N/A',
                ),
              ),
              Expanded(
                child: _DetailItem(
                  icon: Icons.check_circle_outline,
                  label: 'Verification Status',
                  value: _statusLabel(doctor['verification_status'] ?? 'pending'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityComparison(Map<String, dynamic> doctor) {
    final idFront = doctor['identity_document_front_url'] as String?;
    final selfie = doctor['live_selfie_url'] as String?;

    if (idFront == null && selfie == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Identity Comparison'),
        const SizedBox(height: 16),
        Row(
          children: [
            if (idFront != null)
              Expanded(
                child: _IdentityImageCard(
                  title: 'Government ID',
                  path: idFront,
                  bucket: 'doctor-identities',
                ),
              ),
            if (idFront != null && selfie != null) const SizedBox(width: 16),
            if (selfie != null)
              Expanded(
                child: _IdentityImageCard(
                  title: 'Live Selfie',
                  path: selfie,
                  bucket: 'doctor-identities',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimaryOf(context),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLightOf(context)),
          ),
          child: TextField(
            controller: _adminNotesController,
            maxLines: 4,
            style: TextStyle(
              color: AppColors.textPrimaryOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Add a note (optional)...',
              hintStyle: TextStyle(
                color: AppColors.textTertiaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
              color: AppColors.successLightOf(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'This doctor has been verified',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        if (status == 'rejected')
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.errorLightOf(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
                SizedBox(width: 8),
                Text(
                  'This application was rejected',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimaryOf(context),
        letterSpacing: -0.5,
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
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

  const _TabItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : AppColors.borderLightOf(context),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer_outlined, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textTertiaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              count,
              style: TextStyle(
                color: isSelected ? color : AppColors.textTertiaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
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

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
  });

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
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocItem {
  final String title;
  final String path;
  final String bucket;
  final IconData icon;

  const _DocItem({
    required this.title,
    required this.path,
    required this.bucket,
    required this.icon,
  });
}

class _DocumentCard extends StatelessWidget {
  final String title;
  final String fileName;
  final IconData icon;
  final VoidCallback? onTap;

  const _DocumentCard({
    required this.title,
    required this.fileName,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLightOf(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fileName,
              style: TextStyle(
                color: AppColors.textTertiaryOf(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined, size: 10, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'View',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityImageCard extends StatefulWidget {
  final String title;
  final String path;
  final String bucket;

  const _IdentityImageCard({
    required this.title,
    required this.path,
    required this.bucket,
  });

  @override
  State<_IdentityImageCard> createState() => _IdentityImageCardState();
}

class _IdentityImageCardState extends State<_IdentityImageCard> {
  late Future<String?> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = _getSignedUrl();
  }

  Future<String?> _getSignedUrl() async {
    try {
      return await supabase.storage.from(widget.bucket).createSignedUrl(widget.path, 1800);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/document-viewer', extra: {
        'bucket': widget.bucket,
        'path': widget.path,
        'title': widget.title,
      }),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLightOf(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<String?>(
                future: _urlFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  final url = snapshot.data;
                  if (url == null) {
                    return Center(
                      child: Icon(Icons.broken_image_rounded, color: AppColors.textTertiaryOf(context), size: 32),
                    );
                  }
                  return Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.broken_image_rounded, color: AppColors.textTertiaryOf(context), size: 32),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.infoLightOf(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiaryOf(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
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

  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    this.onTap,
  });

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
              border: Border.all(
                color: color.withValues(alpha: enabled ? 0.2 : 0.1),
              ),
            ),
            child: Icon(
              icon,
              color: color.withValues(alpha: enabled ? 1.0 : 0.4),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: color.withValues(alpha: enabled ? 1.0 : 0.4),
          ),
        ),
      ],
    );
  }
}
