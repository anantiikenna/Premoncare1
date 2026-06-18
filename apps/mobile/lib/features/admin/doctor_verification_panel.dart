import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_scaffold.dart';

class DoctorVerificationPanel extends ConsumerWidget {
  const DoctorVerificationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryColor = Color(0xFF0F62FE);

    return AdminScaffold(
      selectedIndex: 2,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildTabFilters(),
            const SizedBox(height: 24),
            _buildSearchAndFilter(),
            const SizedBox(height: 32),
            _buildDoctorProfileCard(primaryColor),
            const SizedBox(height: 32),
            _buildVerificationStepper(primaryColor),
            const SizedBox(height: 32),
            _buildSectionHeader('Submitted Documents', onSeeAll: () {}),
            const SizedBox(height: 16),
            _buildDocumentsGrid(primaryColor),
            const SizedBox(height: 32),
            _buildSectionHeader('Application Details'),
            const SizedBox(height: 16),
            _buildDetailsGrid(),
            const SizedBox(height: 32),
            _buildAdminNotes(),
            const SizedBox(height: 32),
            _buildActionButtons(context, primaryColor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTabFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabItem(label: 'Pending', count: '23', isSelected: true, color: const Color(0xFF6366F1)),
          const SizedBox(width: 12),
          _TabItem(label: 'Under Review', count: '8', isSelected: false, color: const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          _TabItem(label: 'Verified', count: '156', isSelected: false, color: const Color(0xFF10B981)),
          const SizedBox(width: 12),
          _TabItem(label: 'Rejected', count: '12', isSelected: false, color: const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                SizedBox(width: 12),
                Text('Search by name, email or license number...', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: const Row(
            children: [
              Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 20),
              SizedBox(width: 8),
              Text('Filter', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorProfileCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F62FE).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Text('F', style: TextStyle(color: Color(0xFF0F62FE), fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 2)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 10),
                          SizedBox(width: 4),
                          Text('Pending', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dr. Femi Adebayo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                            SizedBox(height: 2),
                            Text('General Physician', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Application ID', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
                            Row(
                              children: [
                                const Text('APP-2025-0145', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                                const SizedBox(width: 4),
                                Icon(Icons.copy_rounded, color: primaryColor.withValues(alpha: 0.5), size: 14),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 14),
                        SizedBox(width: 8),
                        Text('femiadebayo@email.com', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.phone_outlined, color: Color(0xFF94A3B8), size: 14),
                        SizedBox(width: 8),
                        Text('+234 801 234 5678', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Applied on: 14 Jun 2025, 10:30 AM', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Text('85%', style: TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 4),
                              const Text('Match Score', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              Icon(Icons.info_outline_rounded, color: const Color(0xFF10B981).withValues(alpha: 0.5), size: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStepper(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepItem(label: 'Personal Info', status: 'Completed', isCompleted: true, isActive: false),
          _StepLine(isCompleted: true),
          _StepItem(label: 'License', status: 'Verified', isCompleted: true, isActive: false),
          _StepLine(isCompleted: true),
          _StepItem(label: 'Documents', status: 'Verified', isCompleted: true, isActive: false),
          _StepLine(isCompleted: true),
          _StepItem(label: 'Education', status: 'Verified', isCompleted: true, isActive: false),
          _StepLine(isCompleted: false),
          _StepItem(label: 'Review', status: 'Pending', isCompleted: false, isActive: true, stepNumber: '5'),
        ],
      ),
    );
  }

  Widget _buildDocumentsGrid(Color primaryColor) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: [
        _DocumentCard(title: 'Medical License', fileName: 'IMG_4521.jpg', isVerified: true, color: primaryColor),
        _DocumentCard(title: 'Professional ID', fileName: 'IMG_4522.jpg', isVerified: true, color: primaryColor),
        _DocumentCard(title: 'Degree Certificate', fileName: 'IMG_4523.jpg', isVerified: true, color: primaryColor),
        _DocumentCard(title: 'NYSC Certificate', fileName: 'IMG_4524.jpg', isVerified: true, color: primaryColor),
      ],
    );
  }

  Widget _buildDetailsGrid() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Expanded(child: _DetailItem(icon: Icons.person_outline_rounded, label: 'Full Name', value: 'Dr. Femi Adebayo')),
              Expanded(child: _DetailItem(icon: Icons.badge_outlined, label: 'License Number', value: 'MDCN123456')),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _DetailItem(icon: Icons.cake_outlined, label: 'Date of Birth', value: '12 March 1990')),
              Expanded(child: _DetailItem(icon: Icons.location_on_outlined, label: 'Issuing State', value: 'Lagos')),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _DetailItem(icon: Icons.transgender_rounded, label: 'Gender', value: 'Male')),
              Expanded(child: _DetailItem(icon: Icons.work_outline_rounded, label: 'Years of Experience', value: '8 Years')),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _DetailItem(icon: Icons.medical_services_outlined, label: 'Specialization', value: 'General Physician')),
              Expanded(child: _DetailItem(icon: Icons.apartment_rounded, label: 'Practice Type', value: 'Clinic')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Admin Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: const Text('Add a note (optional)...', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Reject Application',
            color: const Color(0xFFEF4444),
            icon: Icons.cancel_outlined,
            onTap: () => _showRejectionDialog(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Request More Info',
            color: const Color(0xFFF59E0B),
            icon: Icons.help_outline_rounded,
            onTap: () => _showRequestInfoDialog(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Approve & Verify',
            color: const Color(0xFF10B981),
            icon: Icons.check_circle_outline_rounded,
            onTap: () => _showApprovalDialog(context),
          ),
        ),
      ],
    );
  }

  void _showApprovalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 12),
            Text('Approve Doctor?', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to approve Dr. Femi Adebayo? This will immediately grant them practitioner access and operational scheduling capabilities.',
          style: TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 13),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Doctor verified successfully!'), backgroundColor: Color(0xFF10B981)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Reject Application', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejecting this application. This will be sent to the user.',
              style: TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Application rejected.'), backgroundColor: Color(0xFFEF4444)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRequestInfoDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.help_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 12),
            Text('Request Information', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What additional information do you need from the applicant?',
              style: TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'E.g. Please upload a clearer copy of your Medical License.',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Information request sent.'), backgroundColor: Color(0xFFF59E0B)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('View All', style: TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.w700, fontSize: 13)),
          ),
      ],
    );
  }


}

class _TabItem extends StatelessWidget {
  final String label;
  final String count;
  final bool isSelected;
  final Color color;

  const _TabItem({required this.label, required this.count, required this.isSelected, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? color.withValues(alpha: 0.5) : const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.timer_outlined, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isSelected ? color : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(count, style: TextStyle(color: isSelected ? color : const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String label;
  final String status;
  final bool isCompleted;
  final bool isActive;
  final String? stepNumber;

  const _StepItem({required this.label, required this.status, required this.isCompleted, required this.isActive, this.stepNumber});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFF10B981) : (isActive ? const Color(0xFF0F62FE) : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(color: isCompleted || isActive ? Colors.transparent : const Color(0xFFCBD5E1)),
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : (isActive
                  ? Center(child: Text(stepNumber ?? '', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
                  : null),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFFECFDF5) : (isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(status, style: TextStyle(color: isCompleted ? const Color(0xFF10B981) : (isActive ? const Color(0xFF0F62FE) : const Color(0xFF94A3B8)), fontSize: 8, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isCompleted;
  const _StepLine({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String title;
  final String fileName;
  final bool isVerified;
  final Color color;

  const _DocumentCard({required this.title, required this.fileName, required this.isVerified, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.description_rounded, color: Color(0xFFCBD5E1), size: 40),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(fileName, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
            child: const Text('Verified', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF3B82F6), size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
