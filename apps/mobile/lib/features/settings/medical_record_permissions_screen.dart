import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/supabase_locator.dart';

class MedicalRecordPermissionsScreen extends ConsumerStatefulWidget {
  const MedicalRecordPermissionsScreen({super.key});

  @override
  ConsumerState<MedicalRecordPermissionsScreen> createState() => _MedicalRecordPermissionsScreenState();
}

class _MedicalRecordPermissionsScreenState extends ConsumerState<MedicalRecordPermissionsScreen> {
  List<Map<String, dynamic>> _permissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final result = await supabase
          .from('record_permissions')
          .select('*, profiles!record_permissions_doctor_id_fkey(full_name, specialty)')
          .eq('patient_id', user.id);
      setState(() {
        _permissions = List<Map<String, dynamic>>.from(result as List);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _revokePermission(String permissionId) async {
    try {
      await supabase.from('record_permissions').delete().eq('id', permissionId);
      _loadPermissions();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access revoked')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.textPrimaryOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: color),
          onPressed: () => context.pop(),
        ),
        title: Text('Record Permissions', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _permissions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _permissions.length,
                  itemBuilder: (context, index) {
                    final perm = _permissions[index];
                    final doctor = perm['profiles'] as Map<String, dynamic>?;
                    return _buildPermissionCard(perm, doctor);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_open_rounded, color: AppColors.textTertiaryOf(context), size: 56),
          const SizedBox(height: 16),
          Text('No permissions granted', style: AppTypography.h4Of(context)),
          const SizedBox(height: 8),
          Text(
            'Doctors will request access to your medical records when needed.',
            style: AppTypography.bodySmallOf(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(Map<String, dynamic> perm, Map<String, dynamic>? doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor?['full_name'] ?? 'Doctor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context))),
                const SizedBox(height: 2),
                Text(doctor?['specialty'] ?? 'Specialist', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _revokePermission(perm['id']),
            child: const Text('Revoke', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
