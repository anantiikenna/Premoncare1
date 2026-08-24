import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile/features/verification/verification_provider.dart';
import '../../../core/app_colors.dart';

class ProfessionalStep extends ConsumerStatefulWidget {
  const ProfessionalStep({super.key});

  @override
  ConsumerState<ProfessionalStep> createState() => _ProfessionalStepState();
}

class _ProfessionalStepState extends ConsumerState<ProfessionalStep> {
  late TextEditingController _licenseController;
  String? _selectedTitle;
  String? _selectedSpecialty;
  String? _selectedSubSpecialty;
  String? _selectedExperience;

  @override
  void initState() {
    super.initState();
    final state = ref.read(verificationProvider);
    _licenseController = TextEditingController(text: state.licenseNumber);
    _selectedTitle = state.title.isNotEmpty ? state.title : null;
    _selectedSpecialty = state.specialty.isNotEmpty ? state.specialty : null;
    _selectedExperience = state.experience.isNotEmpty ? state.experience : null;
  }

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  void _onChanged() {
    ref.read(verificationProvider.notifier).updateProfessional(
      _selectedTitle ?? '',
      _selectedSpecialty ?? '',
      _selectedExperience ?? '',
      _licenseController.text,
    );
  }

  Future<void> _pickLicense() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      await ref.read(verificationProvider.notifier).uploadFile(
        file,
        VerificationField.license,
        'medical_license_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLightOf(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAltOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.badge_outlined, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tell us about your professional background',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This information helps us verify your credentials and ensure trust on our platform.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildLabel('Professional Title', isRequired: true),
        Text('Select your professional title or designation.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
        const SizedBox(height: 12),
        _buildDropdown(
          hint: 'Select your title',
          icon: Icons.person_outline,
          value: _selectedTitle,
          items: ['Dr.', 'Prof.', 'Assoc. Prof.', 'Mr.', 'Mrs.', 'Ms.', 'Veteran', 'Consultant', 'Pharmacist', 'Nurse', 'Therapist'],
          onChanged: (val) {
            setState(() => _selectedTitle = val);
            _onChanged();
          },
        ),
        const SizedBox(height: 24),
        _buildLabel('Medical Specialty', isRequired: true),
        Text('Select your primary area of specialization.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
        const SizedBox(height: 12),
        _buildDropdown(
          hint: 'Select your specialty',
          icon: Icons.medical_services_outlined,
          value: _selectedSpecialty,
          items: ['General Practitioner', 'Cardiologist', 'Neurologist', 'Pediatrician', 'Surgeon'],
          onChanged: (val) {
            setState(() => _selectedSpecialty = val);
            _onChanged();
          },
        ),
        const SizedBox(height: 24),
        _buildLabel('Sub-specialty', isRequired: false),
        Text('Select your sub-specialty if applicable.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
        const SizedBox(height: 12),
        _buildDropdown(
          hint: 'Select sub-specialty',
          icon: Icons.account_tree_outlined,
          value: _selectedSubSpecialty,
          items: ['Clinical Cardiology', 'Pediatric Neurology', 'None'],
          onChanged: (val) {
            setState(() => _selectedSubSpecialty = val);
          },
        ),
        const SizedBox(height: 24),
        _buildLabel('Years of Experience', isRequired: true),
        Text('Total years of professional experience in your field.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
        const SizedBox(height: 12),
        _buildDropdown(
          hint: 'Select years of experience',
          icon: Icons.calendar_today_outlined,
          value: _selectedExperience,
          items: ['1-3 years', '4-7 years', '8-12 years', '13+ years'],
          onChanged: (val) {
            setState(() => _selectedExperience = val);
            _onChanged();
          },
        ),
        const SizedBox(height: 24),
        _buildLabel('Medical License Number', isRequired: true),
        Text('Enter your valid medical license number.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
        const SizedBox(height: 12),
        TextField(
          controller: _licenseController,
          onChanged: (_) => _onChanged(),
          decoration: InputDecoration(
            hintText: 'Enter license number',
            hintStyle: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14),
            prefixIcon: Icon(Icons.verified_outlined, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.surfaceOf(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderOf(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderOf(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildLabel('Upload Medical License', isRequired: true),
        Text('Upload a clear copy of your medical license.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
        const SizedBox(height: 16),
        InkWell(
          onTap: state.isUploading ? null : _pickLicense,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, style: BorderStyle.solid, width: 1),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 40),
                const SizedBox(height: 12),
                Text(
                  state.licenseUrl != null ? 'License Document Uploaded' : 'Upload License Document',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryOf(context)),
                ),
                const SizedBox(height: 4),
                Text('PDF, JPG or PNG (Max. 10MB)', style: TextStyle(fontSize: 12, color: AppColors.textTertiaryOf(context))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundOf(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your information is 256-bit encrypted',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimaryOf(context)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All documents are securely stored in your private vault and are only accessible to our verification team.',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondaryOf(context), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {required bool isRequired}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryOf(context)),
          ),
          if (isRequired)
            Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(hint, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14)),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiaryOf(context)),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: TextStyle(fontSize: 14, color: AppColors.textPrimaryOf(context))),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
