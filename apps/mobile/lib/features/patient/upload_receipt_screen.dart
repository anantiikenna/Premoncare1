import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UploadReceiptScreen extends ConsumerWidget {
  const UploadReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'Upload Payment Receipt',
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(
              'Upload your payment proof for verification',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.black54),
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
            // Upload Dropzone
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F5FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD6BBFB), style: BorderStyle.solid, width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
                    child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF7F56D9), size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('Upload Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('JPG, PNG or PDF (Max 5MB)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File picker coming soon')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6941C6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Choose File', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text('Your data is secure and encrypted', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Form
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Receipt submitted for verification. We\'ll review it shortly.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                  Navigator.of(context).maybePop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6941C6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit for Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            // Tips Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F5FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6BBFB).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF6941C6), size: 24),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tips for faster verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6941C6))),
                        Text('• Make sure the amount is clearly visible', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text('• Use a clear, well-lit image of the receipt', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Image.network('https://cdn-icons-png.flaticon.com/512/1007/1007929.png', width: 40, height: 40, errorBuilder: (context, error, stackTrace) => const Icon(Icons.receipt_long_rounded, size: 40, color: Color(0xFFD6BBFB))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Uploaded Receipts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Receipt history coming soon')),
                    );
                  },
                  child: const Row(
                    children: [
                      Text('View All', style: TextStyle(color: Color(0xFF6941C6), fontWeight: FontWeight.bold)),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFF6941C6), size: 20),
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
              statusColor: Colors.orange,
              icon: Icons.access_time_rounded,
            ),
            _HistoryTile(
              date: 'May 10, 2024',
              time: '02:15 PM',
              amount: '₦10,000',
              ref: '7726352810',
              status: 'Approved',
              statusLabel: 'Time added: 45 mins',
              statusColor: Colors.green,
              icon: Icons.check_circle_rounded,
            ),
            _HistoryTile(
              date: 'May 8, 2024',
              time: '11:45 AM',
              amount: '₦5,000',
              ref: '6638272910',
              status: 'Rejected',
              statusLabel: 'Amount mismatch',
              statusColor: Colors.red,
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
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
                      const Icon(Icons.account_balance_rounded, size: 18, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(val, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  // Store selected payment method in state
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
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
                Text('$date • $time', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(amount, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                Text('Ref: $ref', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
              Text(statusLabel, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}
