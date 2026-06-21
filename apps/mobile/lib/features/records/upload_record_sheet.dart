import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../core/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/glass_card.dart';
import 'records_provider.dart';

class UploadRecordSheet extends StatefulWidget {
  const UploadRecordSheet({super.key});

  @override
  State<UploadRecordSheet> createState() => _UploadRecordSheetState();
}

class _UploadRecordSheetState extends State<UploadRecordSheet> {
  final _titleController = TextEditingController();
  RecordType _selectedType = RecordType.labResult;
  File? _selectedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a title and select a file')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      await RecordsService.uploadRecord(
        title: _titleController.text.trim(),
        type: _selectedType,
        file: _selectedFile!,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Secure Vault Upload',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your files are stored in an encrypted private bucket.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
            ),
            const SizedBox(height: 32),
            CustomTextField(
              label: 'Record Title',
              hintText: 'e.g. June Blood Test',
              controller: _titleController,
            ),
            const SizedBox(height: 20),
            const Text('Record Category', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: RecordType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.name.split('_').join(' ')),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            _buildFileSelector(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isUploading ? null : _handleUpload,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _isUploading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Encrypt & Upload to Vault', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelector() {
    return InkWell(
      onTap: _pickFile,
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              _selectedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
              size: 48,
              color: _selectedFile != null ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFile != null 
                ? 'File Selected: ${_selectedFile!.path.split('/').last}'
                : 'Select PDF or Medical Image',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _selectedFile != null ? AppColors.success : AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
