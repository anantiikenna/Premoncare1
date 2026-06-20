import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConsultationScreen extends StatelessWidget {
  final String appointmentId;
  const ConsultationScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            const Text(
              'Consultation',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
                const SizedBox(width: 4),
                Text(
                  'Your call is end-to-end encrypted',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('End Call', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Video Feed Section
              _VideoFeedSection(),
              const SizedBox(height: 24),
              // Appointment Details Card
              _AppointmentDetailsCard(),
              const SizedBox(height: 16),
              // Time Balance Card
              _TimeBalanceCard(),
              const SizedBox(height: 16),
              // Chat Section
              _ChatSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoFeedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 450,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1559839734-2b71f1536783?auto=format&fit=crop&q=80&w=1000'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Header Info Overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.access_time_rounded, color: Colors.green, size: 24),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time Remaining', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      Text('24:32 mins', style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Spacer(),
                  VerticalDivider(color: Colors.white24, width: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Consultation with', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      Text('Dr. Adaeze Nwosu', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Patient PiP
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF0F62FE),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text('J', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40)),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.flip_camera_ios_rounded, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // HD Badge
          Positioned(
            top: 100,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Text('HD', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Icon(Icons.signal_cellular_alt_rounded, color: Colors.green, size: 12),
                ],
              ),
            ),
          ),
          // Control Bar
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlCircle(icon: Icons.mic_none_rounded, label: 'Mute'),
                _ControlCircle(icon: Icons.videocam_off_outlined, label: 'Turn Off'),
                _EndCallButton(),
                _ControlCircle(icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
                _ControlCircle(icon: Icons.more_horiz_rounded, label: 'More'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ControlCircle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _EndCallButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 8),
        const Text('End Call', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _AppointmentDetailsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Appointment Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Full appointment details will be available after your consultation.')),
                  );
                },
                child: const Row(
                  children: [
                    Text('View Details', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFF6366F1), size: 16),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F62FE).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('A', style: TextStyle(color: Color(0xFF0F62FE), fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Dr. Adaeze Nwosu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(width: 4),
                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
                        ],
                      ),
                      Text('Cardiologist', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      SizedBox(height: 4),
                      Text('Tue, 21 May 2024  •  11:00 AM  •  30 mins', style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('In Progress', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Time Balance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BalanceStat(icon: Icons.access_time_rounded, color: Colors.green, label: 'Total Balance', value: '45 mins', sub: 'Available'),
              Container(width: 1, height: 40, color: Colors.grey.shade100),
              _BalanceStat(icon: Icons.history_rounded, color: Colors.blue, label: 'Used', value: '5 mins', sub: 'This session'),
              Container(width: 1, height: 40, color: Colors.grey.shade100),
              _BalanceStat(icon: Icons.timer_rounded, color: Colors.purple, label: 'Remaining', value: '40 mins', sub: 'After this call'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;

  const _BalanceStat({required this.icon, required this.color, required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey, fontSize: 9)),
                Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(color: Colors.grey.shade400, fontSize: 8)),
      ],
    );
  }
}

class _ChatSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat history loads automatically during consultations')),
                  );
                },
                child: const Row(
                  children: [
                    Text('View all', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFF6366F1), size: 16),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFF0F62FE),
                      child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('Hello Jake, how are you feeling today?', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(height: 4),
                        const Text('11:02 AM', style: TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Typing Indicator placeholder
                Row(
                  children: [
                    const SizedBox(width: 40),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        children: [
                          CircleAvatar(radius: 2, backgroundColor: Colors.grey),
                          SizedBox(width: 4),
                          CircleAvatar(radius: 2, backgroundColor: Colors.grey),
                          SizedBox(width: 4),
                          CircleAvatar(radius: 2, backgroundColor: Colors.grey),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Input area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attachment_rounded, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const Icon(Icons.send_rounded, color: Color(0xFF6366F1), size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
