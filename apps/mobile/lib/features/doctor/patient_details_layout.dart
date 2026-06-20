import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PatientDetailsLayout extends StatefulWidget {
  final String patientId;
  const PatientDetailsLayout({super.key, required this.patientId});

  @override
  State<PatientDetailsLayout> createState() => _PatientDetailsLayoutState();
}

class _PatientDetailsLayoutState extends State<PatientDetailsLayout> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F62FE);
    const bgColor = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildPatientHeader(),
          const SizedBox(height: 20),
          _buildTabBar(primaryColor),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(primaryColor: primaryColor),
                _ConsultationsTab(primaryColor: primaryColor),
                _RecordsTab(primaryColor: primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Patient Details',
        style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1E293B)),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (context) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.folder_open_rounded, color: Color(0xFF0F62FE)),
                        title: const Text('View Records', style: TextStyle(fontWeight: FontWeight.w700)),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Scroll to the Records tab to view patient files')),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.message_rounded, color: Color(0xFF22C55E)),
                        title: const Text('Send Message', style: TextStyle(fontWeight: FontWeight.w700)),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/chat/${widget.patientId}');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.block_rounded, color: Color(0xFFEF4444)),
                        title: const Text('Block Patient', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Block Patient'),
                              content: const Text('Are you sure you want to block this patient? They won\'t be able to book consultations with you.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Patient blocked')),
                                    );
                                  },
                                  child: const Text('Block', style: TextStyle(color: Color(0xFFEF4444))),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1.0),
        child: Divider(height: 1.0, color: Color(0xFFF1F5F9)),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF0F62FE),
            child: Text('J', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('John Michael Adebayo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                const Text('28 years • Male • O+', style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoTag(label: 'Hypertension', color: const Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    _InfoTag(label: 'Allergy: Penicillin', color: const Color(0xFFF59E0B)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(Color primaryColor) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primaryColor,
        unselectedLabelColor: const Color(0xFF94A3B8),
        indicatorColor: primaryColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: 'OVERVIEW'),
          Tab(text: 'CONSULTATIONS'),
          Tab(text: 'RECORDS'),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Color primaryColor;
  const _OverviewTab({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClinicalSummary(),
          const SizedBox(height: 24),
          _buildVitalsGrid(),
          const SizedBox(height: 24),
          _buildMedicationList(),
        ],
      ),
    );
  }

  Widget _buildClinicalSummary() {
    return _SectionCard(
      title: 'Clinical Summary',
      child: const Text(
        'Patient presents with chronic hypertension managed with Lisinopril. Recent blood pressure readings indicate slight elevation. No recent hospitalizations or surgical interventions.',
        style: TextStyle(color: Color(0xFF64748B), height: 1.6, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildVitalsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RECENT VITALS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: const [
            _VitalCard(label: 'Blood Pressure', value: '138/92', unit: 'mmHg', color: Color(0xFFEF4444)),
            _VitalCard(label: 'Heart Rate', value: '78', unit: 'bpm', color: Color(0xFF3B82F6)),
            _VitalCard(label: 'Body Temp', value: '36.8', unit: '°C', color: Color(0xFF10B981)),
            _VitalCard(label: 'Weight', value: '74.2', unit: 'kg', color: Color(0xFF8B5CF6)),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicationList() {
    return _SectionCard(
      title: 'Current Medications',
      child: Column(
        children: [
          _MedicationItem(name: 'Lisinopril 10mg', dose: '1x Daily', type: 'Antihypertensive'),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _MedicationItem(name: 'Amlodipine 5mg', dose: '1x Daily', type: 'Calcium Channel Blocker'),
        ],
      ),
    );
  }
}

class _ConsultationsTab extends StatelessWidget {
  final Color primaryColor;
  const _ConsultationsTab({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) => _ConsultationItem(index: index, primaryColor: primaryColor),
    );
  }
}

class _RecordsTab extends StatefulWidget {
  final Color primaryColor;
  const _RecordsTab({required this.primaryColor});

  @override
  State<_RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<_RecordsTab> {
  int _activeSubTab = 0;
  final List<String> _subTabs = ['DOCUMENTS', 'IMAGES', 'LABS', 'NOTES', 'PRESCRIPTIONS'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSubTabBar(),
        Expanded(
          child: _buildSubTabContent(),
        ),
      ],
    );
  }

  Widget _buildSubTabBar() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _subTabs.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => setState(() => _activeSubTab = index),
          child: Container(
            margin: const EdgeInsets.only(right: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _activeSubTab == index ? widget.primaryColor : Colors.transparent, width: 2)),
            ),
            child: Text(
              _subTabs[index],
              style: TextStyle(color: _activeSubTab == index ? widget.primaryColor : const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabContent() {
    // Modular content based on _activeSubTab
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 4,
      itemBuilder: (context, index) => _RecordItem(index: index, type: _subTabs[_activeSubTab]),
    );
  }
}

// Helper Widgets
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _VitalCard({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicationItem extends StatelessWidget {
  final String name;
  final String dose;
  final String type;
  const _MedicationItem({required this.name, required this.dose, required this.type});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.medication_rounded, color: Color(0xFF0F62FE), size: 20)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text('$type • $dose', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsultationItem extends StatelessWidget {
  final int index;
  final Color primaryColor;
  const _ConsultationItem({required this.index, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const Text('JUN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F62FE))),
                Text('${14 - index}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F62FE))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Video Consultation', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text('Dr. Sarah Wilson • ${15 + index * 5} mins', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}

class _RecordItem extends StatelessWidget {
  final int index;
  final String type;
  const _RecordItem({required this.index, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: Color(0xFF64748B), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${type.substring(0, 1) + type.substring(1).toLowerCase()} Report #${1024 - index}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                const Text('Added 2 days ago • 2.4 MB', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF0F62FE)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File saved to device downloads')),
              );
            },
          ),
        ],
      ),
    );
  }
}
