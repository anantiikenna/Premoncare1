import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/app_colors.dart';

class UploadReceiptScreen extends ConsumerStatefulWidget {
  const UploadReceiptScreen({super.key});

  @override
  ConsumerState<UploadReceiptScreen> createState() => _UploadReceiptScreenState();
}

class _UploadReceiptScreenState extends ConsumerState<UploadReceiptScreen> {
  XFile? _selectedFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFile() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _selectedFile = file;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context)),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Upload Payment Receipt',
              style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(
              'Upload your payment proof for verification',
              style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline_rounded, color: AppColors.textSecondaryOf(context)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upload your payment receipt for verification')),
              );
            },
          ),
        ],
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
                border: Border.all(color: AppColors.borderOf(context), style: BorderStyle.solid, width: 1.5),
              ),
              child: _selectedFile != null
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_selectedFile!.path),
                            height: 160,
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFile!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: _pickFile,
                              child: Text('Change File', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFile = null;
                                });
                              },
                              child: Text('Remove', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                            ),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textInverse,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
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
            _buildTextField(label: 'Amount Paid (₦)', hint: '18,000'),
            const SizedBox(height: 20),
            _buildDropdownField(label: 'Payment Method', value: 'Bank Transfer'),
            const SizedBox(height: 20),
            _buildTextField(label: 'Transaction Reference (Optional)', hint: 'e.g. 1234567890'),
            const SizedBox(height: 20),
            _buildTextField(label: 'Description (Optional)', hint: 'Add any additional information about this payment', maxLines: 3),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedFile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a receipt image first')),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Receipt submitted for verification. We\'ll review it shortly.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.of(context).maybePop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit for Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAltOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
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
                  Image.network('https://cdn-icons-png.flaticon.com/512/1007/1007929.png', width: 40, height: 40, errorBuilder: (context, error, stackTrace) => Icon(Icons.receipt_long_rounded, size: 40, color: AppColors.borderOf(context))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Uploaded Receipts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Receipt history will be available after your first upload')),
                    );
                  },
                  child: Row(
                    children: [
                      Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _HistoryTile(
              date: 'May 16, 2024',
              time: '10:32 AM',
              amount: '₦18,000',
              ref: '8827362819',
              status: 'Pending',
              statusLabel: 'Under review',
              statusColor: AppColors.warning,
              icon: Icons.access_time_rounded,
            ),
            _HistoryTile(
              date: 'May 10, 2024',
              time: '02:15 PM',
              amount: '₦10,000',
              ref: '7726352810',
              status: 'Approved',
              statusLabel: 'Time added: 45 mins',
              statusColor: AppColors.success,
              icon: Icons.check_circle_rounded,
            ),
            _HistoryTile(
              date: 'May 8, 2024',
              time: '11:45 AM',
              amount: '₦5,000',
              ref: '6638272910',
              status: 'Rejected',
              statusLabel: 'Amount mismatch',
              statusColor: AppColors.error,
              icon: Icons.cancel_rounded,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required String hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryOf(context))),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
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

  Widget _buildDropdownField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryOf(context))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: ['Bank Transfer', 'P2P Transfer'].map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_rounded, size: 18, color: AppColors.textTertiaryOf(context)),
                      const SizedBox(width: 12),
                      Text(val, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String date;
  final String time;
  final String amount;
  final String ref;
  final String status;
  final String statusLabel;
  final Color statusColor;
  final IconData icon;

  const _HistoryTile({
    required this.date,
    required this.time,
    required this.amount,
    required this.ref,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$date • $time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryOf(context))),
                Text(amount, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimaryOf(context))),
                Text('Ref: $ref', style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text(statusLabel, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 10)),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryOf(context)),
        ],
      ),
    );
  }
}
