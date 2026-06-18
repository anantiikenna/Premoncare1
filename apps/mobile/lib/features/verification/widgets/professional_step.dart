import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile/features/verification/verification_provider.dart';

class ProfessionalStep extends ConsumerStatefulWidget {
  const ProfessionalStep({super.key});

  @override
  ConsumerState<ProfessionalStep> createState() => _ProfessionalStepState();
}

class _ProfessionalStepState extends ConsumerState<ProfessionalStep> {
  late TextEditingController _licenseController;
  String? _selectedSpecialty;
  String? _selectedSubSpecialty;
  String? _selectedExperience;

  @override
  void initState() {
    super.initState();
    final state = ref.read(verificationProvider);
    _licenseController = TextEditingController(text: state.licenseNumber);
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
        // Info Box
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEF2FF)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.badge_outlined, color: Color(0xFF4338CA), size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tell us about your professional background',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'This information helps us verify your credentials and ensure trust on our platform.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Medical Specialty Dropdown
        _buildLabel('Medical Specialty', isRequired: true),
        const Text('Select your primary area of specialization.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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

        // Sub-specialty Dropdown
        _buildLabel('Sub-specialty', isRequired: false),
        const Text('Select your sub-specialty if applicable.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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

        // Years of Experience Dropdown
        _buildLabel('Years of Experience', isRequired: true),
        const Text('Total years of professional experience in your field.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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

        // Medical License Number
        _buildLabel('Medical License Number', isRequired: true),
        const Text('Enter your valid medical license number.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 12),
        TextField(
          controller: _licenseController,
          onChanged: (_) => _onChanged(),
          decoration: InputDecoration(
            hintText: 'Enter license number',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: const Icon(Icons.verified_outlined, color: Color(0xFF6366F1), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // File Upload
        _buildLabel('Upload Medical License', isRequired: true),
        const Text('Upload a clear copy of your medical license.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 16),
        InkWell(
          onTap: state.isUploading ? null : _pickLicense,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6366F1), style: BorderStyle.solid, width: 1), // Real Flutter dashed border needs a custom painter or package
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload_outlined, color: Color(0xFF6366F1), size: 40),
                const SizedBox(height: 12),
                Text(
                  state.licenseUrl != null ? 'License Document Uploaded' : 'Upload License Document',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1B4B)),
                ),
                const SizedBox(height: 4),
                const Text('PDF, JPG or PNG (Max. 10MB)', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Encryption Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: Color(0xFF6366F1), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your information is 256-bit encrypted',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E1B4B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All documents are securely stored in your private vault and are only accessible to our verification team.',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, height: 1.4),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1B4B)),
          ),
          if (isRequired)
            const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, color: const Color(0xFF6366F1), size: 20),
              const SizedBox(width: 12),
              Text(hint, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
            ],
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14, color: Color(0xFF1E1B4B))),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
