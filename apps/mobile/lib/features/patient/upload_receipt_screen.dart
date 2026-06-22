import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';

final uploadReceiptLoadingProvider = StateProvider<bool>((ref) => false);

class UploadReceiptScreen extends ConsumerStatefulWidget {
  final String? appointmentId;
  final String? doctorId;
  final double? amount;

  const UploadReceiptScreen({super.key, this.appointmentId, this.doctorId, this.amount});

  @override
  ConsumerState<UploadReceiptScreen> createState() => _UploadReceiptScreenState();
}

class _UploadReceiptScreenState extends ConsumerState<UploadReceiptScreen> {
  XFile? _selectedFile;
  final ImagePicker _picker = ImagePicker();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  final _descController = TextEditingController();
  String _paymentMethod = 'Bank Transfer';

  @override
  void initState() {
    super.initState();
    if (widget.amount != null) {
      _amountController.text = widget.amount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _selectedFile = file);
  }

  Future<void> _submitReceipt() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a receipt image first')));
      return;
    }
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the amount paid')));
      return;
    }

    ref.read(uploadReceiptLoadingProvider.notifier).state = true;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final fileExt = _selectedFile!.path.split('.').last;
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final fileBytes = await File(_selectedFile!.path).readAsBytes();

      await supabase.storage.from('payment-receipts').uploadBinary(fileName, fileBytes);
      final publicUrl = supabase.storage.from('payment-receipts').getPublicUrl(fileName);

      await supabase.from('payments').insert({
        'user_id': user.id,
        if (widget.doctorId != null) 'recipient_id': widget.doctorId,
        'amount': double.parse(_amountController.text.replaceAll(RegExp(r'[^\d.]'), '')),
        'method': 'manual',
        'receipt_url': publicUrl,
        'status': 'pending',
        if (_refController.text.isNotEmpty) 'transaction_id': _refController.text,
        if (widget.appointmentId != null) 'duration_minutes': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Receipt submitted for verification'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      ref.read(uploadReceiptLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(uploadReceiptLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context)), onPressed: () => context.pop()),
        centerTitle: true,
        title: Column(
          children: [
            Text('Upload Payment Receipt', style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 18, fontWeight: FontWeight.w900)),
            Text('Upload your payment proof for verification', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: AppColors.surfaceAltOf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderOf(context), width: 1.5),
              ),
              child: _selectedFile != null
                  ? Column(
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_selectedFile!.path), height: 160, width: 200, fit: BoxFit.cover)),
                        const SizedBox(height: 16),
                        Text(_selectedFile!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(onPressed: _pickFile, child: Text('Change File', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                            TextButton(onPressed: () => setState(() => _selectedFile = null), child: Text('Remove', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.surfaceOf(context), shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 10)]),
                          child: Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text('Upload Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('JPG, PNG or PDF (Max 5MB)', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 12)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textInverse, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Choose File', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textTertiaryOf(context)),
                            const SizedBox(width: 4),
                            Text('Your data is secure and encrypted', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 32),
            _buildTextField(label: 'Amount Paid (₦)', hint: '18000', controller: _amountController, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            _buildDropdownField(),
            const SizedBox(height: 20),
            _buildTextField(label: 'Transaction Reference (Optional)', hint: 'e.g. 1234567890', controller: _refController),
            const SizedBox(height: 20),
            _buildTextField(label: 'Description (Optional)', hint: 'Add any additional information about this payment', controller: _descController, maxLines: 3),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitReceipt,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textInverse, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit for Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceAltOf(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderOf(context))),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tips for faster verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                        Text('• Make sure the amount is clearly visible', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11)),
                        Text('• Use a clear, well-lit image of the receipt', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11)),
                      ],
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

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryOf(context))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: AppColors.surfaceOf(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderOf(context))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderOf(context))),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryOf(context))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderOf(context))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _paymentMethod,
              isExpanded: true,
              items: ['Bank Transfer', 'P2P Transfer'].map((String val) {
                return DropdownMenuItem<String>(value: val, child: Row(
                  children: [
                    Icon(Icons.account_balance_rounded, size: 18, color: AppColors.textTertiaryOf(context)),
                    const SizedBox(width: 12),
                    Text(val, style: const TextStyle(fontSize: 14)),
                  ],
                ));
              }).toList(),
              onChanged: (val) { if (val != null) setState(() => _paymentMethod = val); },
            ),
          ),
        ),
      ],
    );
  }
}
