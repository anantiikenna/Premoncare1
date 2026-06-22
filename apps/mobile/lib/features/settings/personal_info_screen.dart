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

  final _imagePicker = ImagePicker();
  File? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _genderController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic>? profile) {
    _fullNameController.text = profile?['full_name'] ?? '';
    _phoneController.text = profile?['phone'] ?? '';
    _dobController.text = profile?['dob'] ?? '';
    _genderController.text = profile?['gender'] ?? '';
    _addressController.text = profile?['address'] ?? '';
  }

  void _enterEditMode(Map<String, dynamic>? profile) {
    _populateControllers(profile);
    setState(() => _isEditing = true);
  }

  void _exitEditMode() {
    setState(() {
      _isEditing = false;
      _selectedPhoto = null;
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
    final path = 'avatars/${user.id}.$ext';

    await supabase.storage.from('avatars').upload(
          path,
          _selectedPhoto!,
          fileOptions: const FileOptions(upsert: true),
        );

    final url = supabase.storage.from('avatars').getPublicUrl(path);
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

      final updateData = <String, dynamic>{
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dob': _dobController.text.trim(),
        'gender': _genderController.text.trim(),
        'address': _addressController.text.trim(),
      };

      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }

      await supabase.from('profiles').update(updateData).eq('id', user.id);

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
          _buildInfoField(context, 'Gender', profile?['gender'] ?? 'Not set'),
          _buildInfoField(context, 'Address', profile?['address'] ?? 'Not set'),
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
              for (final gender in ['Male', 'Female', 'Other', 'Prefer not to say'])
                ListTile(
                  title: Text(gender, style: AppTypography.bodyLargeOf(ctx)),
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
