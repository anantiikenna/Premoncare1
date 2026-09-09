import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/app_colors.dart';
import '../../core/supabase_locator.dart';
import '../../l10n/app_localizations.dart';

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
  String? _paymentMethod;
  bool _isLoading = false;
  String? _selectedDoctorId;

  List<Map<String, dynamic>> _doctors = [];
  bool _loadingDoctors = true;

  @override
  void initState() {
    super.initState();
    if (widget.amount != null) _amountController.text = widget.amount!.toStringAsFixed(0);
    _selectedDoctorId = widget.doctorId;
    _loadDoctors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _paymentMethod ??= AppLocalizations.of(context)!.bankTransfer;
  }

  Future<void> _loadDoctors() async {
    try {
      final data = await supabase
          .from('profiles')
          .select('id, full_name, specialty, consultation_fee, avatar_url, payment_instructions')
          .eq('role', 'doctor')
          .order('full_name');
      if (!mounted) return;
      setState(() {
        _doctors = List<Map<String, dynamic>>.from(data);
        _loadingDoctors = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDoctors = false);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectReceipt)));
      return;
    }
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterAmount)));
      return;
    }
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectDoctor)));
      return;
    }

    const maxSizeBytes = 5 * 1024 * 1024; // 5MB
    if (File(_selectedFile!.path).lengthSync() > maxSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.fileSizeUnder5MB)),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final amount = _parsedAmount();
    if (amount == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterValidAmount)),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

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
        'recipient_id': _selectedDoctorId,
        'amount': amount,
        'method': 'manual',
        'receipt_url': publicUrl,
        'status': 'pending',
        if (_refController.text.isNotEmpty) 'transaction_id': _refController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.receiptSubmitted), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.uploadFailed(e.toString())), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double? _parsedAmount() {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^\d.]'), '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return null;
    return amount;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryOf(context)), onPressed: () => context.pop()),
        centerTitle: true,
        title: Column(
          children: [
            Text(AppLocalizations.of(context)!.uploadPaymentReceipt, style: TextStyle(color: AppColors.textPrimaryOf(context), fontSize: 18, fontWeight: FontWeight.w900)),
            Text(AppLocalizations.of(context)!.uploadReceiptDescription, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11)),
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
                            TextButton(onPressed: _pickFile, child: Text(AppLocalizations.of(context)!.changeFile, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                            TextButton(onPressed: () => setState(() => _selectedFile = null), child: Text(AppLocalizations.of(context)!.remove, style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
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
                        Text(AppLocalizations.of(context)!.uploadReceipt, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(AppLocalizations.of(context)!.jpgPngPdf, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 12)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textInverse, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(AppLocalizations.of(context)!.chooseFile, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textTertiaryOf(context)),
                            const SizedBox(width: 4),
                            Text(AppLocalizations.of(context)!.yourDataSecure, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 32),
            _buildDoctorSelector(),
            const SizedBox(height: 20),
            _buildTextField(label: AppLocalizations.of(context)!.amountPaid, hint: '18000', controller: _amountController, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            _buildDropdownField(),
            const SizedBox(height: 20),
            _buildTextField(label: AppLocalizations.of(context)!.transactionReferenceOptional, hint: 'e.g. 1234567890', controller: _refController),
            const SizedBox(height: 20),
            _buildTextField(label: AppLocalizations.of(context)!.descriptionOptional, hint: 'Add any additional information about this payment', controller: _descController, maxLines: 3),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReceipt,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textInverse, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textInverse))
                    : Text(AppLocalizations.of(context)!.submitForVerification, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        Text(AppLocalizations.of(context)!.tipsFasterVerification, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                        Text(AppLocalizations.of(context)!.amountVisibleTip, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11)),
                        Text(AppLocalizations.of(context)!.clearImageTip, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 11)),
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
        Text(AppLocalizations.of(context)!.paymentMethod, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryOf(context))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderOf(context))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _paymentMethod,
              isExpanded: true,
              items: [AppLocalizations.of(context)!.bankTransfer, AppLocalizations.of(context)!.p2pTransfer].map((String val) {
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

  Widget _buildDoctorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.payingTo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryOf(context))),
        const SizedBox(height: 8),
        if (_loadingDoctors)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderOf(context))),
            child: Row(children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.loadingDoctors, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14)),
            ]),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: _selectedDoctorId == null ? AppColors.borderOf(context) : AppColors.primary.withValues(alpha: 0.3))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDoctorId,
                isExpanded: true,
                hint: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textTertiaryOf(context)),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.selectDoctor, style: TextStyle(color: AppColors.textTertiaryOf(context), fontSize: 14)),
                  ],
                ),
                items: _doctors.map((doc) {
                  final fee = doc['consultation_fee'] as num? ?? 0;
                  final avatar = doc['avatar_url'] as String?;
                  return DropdownMenuItem<String>(
                    value: doc['id'] as String,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          child: (avatar == null || avatar.isEmpty) ? Text((doc['full_name'] as String? ?? '?')[0].toUpperCase(), style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(doc['full_name'] ?? 'Unknown', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                              if (doc['specialty'] != null) Text(doc['specialty'], style: TextStyle(fontSize: 11, color: AppColors.textTertiaryOf(context)), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        if (fee > 0) Text('₦${fee.toInt()}/hr', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondaryOf(context))),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedDoctorId = val),
              ),
            ),
          ),
        if (_selectedDoctorId != null) ...[
          const SizedBox(height: 12),
          ..._doctors.where((d) => d['id'] == _selectedDoctorId).map((d) {
            final fee = d['consultation_fee'] as num? ?? 0;
            final avatar = d['avatar_url'] as String?;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: (avatar == null || avatar.isEmpty) ? Text((d['full_name'] as String? ?? '?')[0].toUpperCase(), style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(d['full_name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimaryOf(context)), overflow: TextOverflow.ellipsis),
                            ),
                            Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (d['specialty'] != null) Text(d['specialty'], style: TextStyle(fontSize: 12, color: AppColors.textTertiaryOf(context)), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('₦${fee.toInt()}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
                        Text(AppLocalizations.of(context)!.perHour, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final selectedDoc = _doctors.firstWhere((d) => d['id'] == _selectedDoctorId, orElse: () => {});
              final instructions = selectedDoc['payment_instructions'] as String?;
              final displayInstructions = (instructions != null && instructions.trim().isNotEmpty)
                  ? instructions
                  : AppLocalizations.of(context)!.noBankDetailsProvided;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, color: AppColors.info, size: 20),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.paymentInstructionsLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.info)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(displayInstructions, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13, height: 1.4)),
                  ],
                ),
              );
            }
          ),
        ],
      ],
    );
  }
}
