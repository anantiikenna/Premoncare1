import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/supabase_locator.dart';
import '../../core/providers.dart';
import '../../shared/widgets/global_user_avatar.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dobController;
  late final TextEditingController _genderController;
  late final TextEditingController _addressController;
  late final TextEditingController _paymentInstructionsController;
  late final TextEditingController _bloodGroupController;
  late final TextEditingController _nextOfKinNameController;
  late final TextEditingController _nextOfKinPhoneController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;
  bool _emailAlertsEnabled = true;

  final _imagePicker = ImagePicker();
  File? _selectedPhoto;
  File? _selectedIdDocument;
  String? _existingIdUrl;
  String? _originalIdUrl;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _genderController = TextEditingController();
    _addressController = TextEditingController();
    _paymentInstructionsController = TextEditingController();
    _bloodGroupController = TextEditingController();
    _nextOfKinNameController = TextEditingController();
    _nextOfKinPhoneController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _paymentInstructionsController.dispose();
    _bloodGroupController.dispose();
    _nextOfKinNameController.dispose();
    _nextOfKinPhoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic>? profile) {
    _fullNameController.text = profile?['full_name'] ?? '';
    _phoneController.text = profile?['phone'] ?? '';
    _dobController.text = profile?['dob'] ?? '';
    _genderController.text = profile?['gender'] ?? '';
    _addressController.text = profile?['address'] ?? '';
    _paymentInstructionsController.text = profile?['payment_instructions'] ?? '';
    _bloodGroupController.text = profile?['blood_group'] ?? '';
    _nextOfKinNameController.text = profile?['next_of_kin_name'] ?? '';
    _nextOfKinPhoneController.text = profile?['next_of_kin_phone'] ?? '';
    _emergencyNameController.text = profile?['emergency_contact_name'] ?? '';
    _emergencyPhoneController.text = profile?['emergency_contact_phone'] ?? '';
    _emailAlertsEnabled = profile?['email_alerts_enabled'] ?? true;
    _existingIdUrl = profile?['identity_document_url'];
    _originalIdUrl = profile?['identity_document_url'];
  }

  void _enterEditMode(Map<String, dynamic>? profile) {
    _populateControllers(profile);
    setState(() => _isEditing = true);
  }

  void _exitEditMode() {
    setState(() {
      _isEditing = false;
      _selectedPhoto = null;
      _selectedIdDocument = null;
    });
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Change Profile Photo', style: AppTypography.h4Of(ctx)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: Text('Take Photo', style: AppTypography.bodyLargeOf(ctx)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: Text('Choose from Gallery', style: AppTypography.bodyLargeOf(ctx)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedPhoto = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String?> _uploadAvatar() async {
    if (_selectedPhoto == null) return null;

    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final ext = _selectedPhoto!.path.split('.').last;
    final path = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final bytes = await _selectedPhoto!.readAsBytes();

    await supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    // Add cache-busting query param to force refresh of cached image
    final baseUrl = supabase.storage.from('avatars').getPublicUrl(path);
    final cacheBuster = DateTime.now().millisecondsSinceEpoch;
    return '$baseUrl?t=$cacheBuster';
  }

  Future<String?> _uploadIdDocument() async {
    if (_selectedIdDocument == null) return null;

    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final ext = _selectedIdDocument!.path.split('.').last;
    final path = '${user.id}/id_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final bytes = await _selectedIdDocument!.readAsBytes();

    await supabase.storage.from('patient-identity-documents').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: false),
        );

    final url = supabase.storage.from('patient-identity-documents').getPublicUrl(path);
    return url;
  }

  Future<void> _saveProfile(Map<String, dynamic>? currentProfile) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      String? avatarUrl;
      if (_selectedPhoto != null) {
        avatarUrl = await _uploadAvatar();
      }

      String? idUrl;
      if (_selectedIdDocument != null) {
        idUrl = await _uploadIdDocument();
      }

      final updateData = <String, dynamic>{
        'full_name': _fullNameController.text.trim().isNotEmpty ? _fullNameController.text.trim() : null,
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        'dob': _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
        'gender': _genderController.text.trim().isNotEmpty ? _genderController.text.trim().toLowerCase() : null,
        'address': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        'blood_group': _bloodGroupController.text.trim().isNotEmpty ? _bloodGroupController.text.trim() : null,
        'next_of_kin_name': _nextOfKinNameController.text.trim().isNotEmpty ? _nextOfKinNameController.text.trim() : null,
        'next_of_kin_phone': _nextOfKinPhoneController.text.trim().isNotEmpty ? _nextOfKinPhoneController.text.trim() : null,
        'emergency_contact_name': _emergencyNameController.text.trim().isNotEmpty ? _emergencyNameController.text.trim() : null,
        'emergency_contact_phone': _emergencyPhoneController.text.trim().isNotEmpty ? _emergencyPhoneController.text.trim() : null,
        'email_alerts_enabled': _emailAlertsEnabled,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (currentProfile?['role'] == 'doctor') {
        updateData['payment_instructions'] = _paymentInstructionsController.text.trim().isNotEmpty ? _paymentInstructionsController.text.trim() : null;
      }

      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }

      if (idUrl != null) {
        updateData['identity_document_url'] = idUrl;
      }

      await supabase.from('profiles').update(updateData).eq('id', user.id);

      if (_originalIdUrl != null && _existingIdUrl == null && _selectedIdDocument == null) {
        try {
          final oldPath = _originalIdUrl!.split('/patient-identity-documents/')[1].split('?')[0];
          await supabase.storage.from('patient-identity-documents').remove([oldPath]);
        } catch (_) {}
      }

      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _exitEditMode();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final email = supabase.auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Personal Information',
          style: AppTypography.h4Of(context),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () {
                final profile = userProfileAsync.value;
                _enterEditMode(profile);
              },
              child: Text(
                'Edit',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: userProfileAsync.when(
        data: (profile) => _isEditing
            ? _buildEditForm(context, profile, email)
            : _buildViewMode(context, profile, email),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err', style: TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildViewMode(BuildContext context, Map<String, dynamic>? profile, String email) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const GlobalUserAvatar(radius: 50),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.primary),
            label: Text(
              'Change Photo',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoField(context, 'Full Name', profile?['full_name'] ?? 'Not set'),
          _buildInfoField(context, 'Email Address', email),
          _buildInfoField(context, 'Phone Number', profile?['phone'] ?? 'Not set'),
          _buildInfoField(context, 'Date of Birth', profile?['dob'] ?? 'Not set'),
          _buildInfoField(context, 'Gender', () {
            final g = (profile?['gender'] ?? 'Not set').toString();
            return g.isNotEmpty ? '${g[0].toUpperCase()}${g.substring(1)}' : g;
          }()),
          _buildInfoField(context, 'Address', profile?['address'] ?? 'Not set'),
          _buildInfoField(context, 'Blood Group', profile?['blood_group'] ?? 'Not set'),
          _buildInfoField(context, 'Next of Kin Name', profile?['next_of_kin_name'] ?? 'Not set'),
          _buildInfoField(context, 'Next of Kin Phone', profile?['next_of_kin_phone'] ?? 'Not set'),
          _buildInfoField(context, 'Emergency Contact Name', profile?['emergency_contact_name'] ?? 'Not set'),
          _buildInfoField(context, 'Emergency Contact Phone', profile?['emergency_contact_phone'] ?? 'Not set'),
          if (profile?['role'] == 'doctor')
            _buildInfoField(context, 'Payment Instructions (Bank Details)', profile?['payment_instructions'] ?? 'Not set'),
          _buildInfoField(context, 'Email Notifications', (profile?['email_alerts_enabled'] ?? true) ? 'Enabled' : 'Disabled'),
          _buildInfoField(context, 'Identity Verification', (profile?['identity_document_url'] ?? '').isNotEmpty ? 'Uploaded' : 'Not uploaded'),
        ],
      ),
    );
  }

  Widget _buildEditForm(BuildContext context, Map<String, dynamic>? profile, String email) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              _selectedPhoto != null
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage: FileImage(_selectedPhoto!),
                    )
                  : const GlobalUserAvatar(radius: 50),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _pickPhoto,
            child: Text(
              _selectedPhoto != null ? 'Change selection' : 'Change Photo',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildEditField(context, 'Full Name', _fullNameController, icon: Icons.person_outline_rounded),
          _buildEditField(context, 'Email Address', null, initialValue: email, enabled: false, icon: Icons.email_outlined),
          _buildEditField(context, 'Phone Number', _phoneController, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          _buildEditField(context, 'Date of Birth', _dobController, icon: Icons.cake_outlined, onTap: _pickDate),
          _buildEditField(context, 'Gender', _genderController, icon: Icons.wc_outlined, onTap: _pickGender),
          _buildEditField(context, 'Address', _addressController, icon: Icons.location_on_outlined, maxLines: 2),
          _buildEditField(context, 'Blood Group', _bloodGroupController, icon: Icons.bloodtype_outlined),
          _buildEditField(context, 'Next of Kin Name', _nextOfKinNameController, icon: Icons.group_outlined),
          _buildEditField(context, 'Next of Kin Phone', _nextOfKinPhoneController, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          _buildEditField(context, 'Emergency Contact Name', _emergencyNameController, icon: Icons.medical_services_outlined),
          _buildEditField(context, 'Emergency Contact Phone', _emergencyPhoneController, icon: Icons.emergency_outlined, keyboardType: TextInputType.phone),
          if (profile?['role'] == 'doctor')
            _buildEditField(context, 'Payment Instructions (Bank Details)', _paymentInstructionsController, icon: Icons.account_balance_rounded, maxLines: 3),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Row(
              children: [
                Icon(Icons.email_outlined, color: AppColors.textSecondaryOf(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email Notifications', style: AppTypography.bodyLargeOf(context)),
                      Text('Receive updates for payments and account status', style: AppTypography.caption),
                    ],
                  ),
                ),
                Switch(
                  value: _emailAlertsEnabled,
                  onChanged: (val) => setState(() => _emailAlertsEnabled = val),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.badge_outlined, color: AppColors.textSecondaryOf(context)),
                    const SizedBox(width: 12),
                    Text('Identity Verification', style: AppTypography.bodyLargeOf(context)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_existingIdUrl != null && _selectedIdDocument == null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successLightOf(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('ID uploaded', style: AppTypography.caption)),
                        TextButton(
                          onPressed: () => setState(() { _existingIdUrl = null; }),
                          child: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 12)),
                        ),
                      ],
                    ),
                  )
                else if (_selectedIdDocument != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.infoLightOf(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file, color: AppColors.info, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_selectedIdDocument!.path.split('/').last, style: AppTypography.caption, overflow: TextOverflow.ellipsis)),
                        TextButton(
                          onPressed: () => setState(() { _selectedIdDocument = null; }),
                          child: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 12)),
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                      if (picked != null) setState(() => _selectedIdDocument = File(picked.path));
                    },
                    icon: const Icon(Icons.upload_outlined),
                    label: const Text('Upload ID Card'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _exitEditMode,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryOf(context),
                    side: BorderSide(color: AppColors.borderOf(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveProfile(profile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save', style: AppTypography.buttonPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(BuildContext context, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmallOf(context),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.bodyLargeOf(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    BuildContext context,
    String label,
    TextEditingController? controller, {
    String? initialValue,
    bool enabled = true,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? AppColors.borderOf(context) : AppColors.slate300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, right: 16),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: AppColors.textSecondaryOf(context)),
                  const SizedBox(width: 8),
                ],
                Text(label, style: AppTypography.labelSmallOf(context)),
              ],
            ),
          ),
          if (controller != null)
            TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              maxLines: maxLines,
              onTap: onTap,
              style: AppTypography.bodyLargeOf(context),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                hintText: 'Enter $label',
                hintStyle: TextStyle(color: AppColors.textTertiaryOf(context)),
                suffixIcon: onTap != null
                    ? Icon(Icons.arrow_drop_down, color: AppColors.textSecondaryOf(context))
                    : null,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                initialValue ?? '',
                style: AppTypography.bodyLargeOf(context).copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dobController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _pickGender() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Select Gender', style: AppTypography.h4Of(ctx)),
              const SizedBox(height: 16),
              for (final gender in ['male', 'female', 'other', 'prefer not to say'])
                ListTile(
                  title: Text('${gender[0].toUpperCase()}${gender.substring(1)}', style: AppTypography.bodyLargeOf(ctx)),
                  trailing: _genderController.text == gender
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _genderController.text = gender);
                    Navigator.pop(ctx);
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
