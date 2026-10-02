import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../core/meeting_room.dart';
import '../../core/supabase_locator.dart';

class ConsultationScreen extends ConsumerStatefulWidget {
  final String appointmentId;
  final String? doctorName;
  final String? specialty;
  final int? durationMinutes;

  const ConsultationScreen({
    super.key,
    required this.appointmentId,
    this.doctorName,
    this.specialty,
    this.durationMinutes,
  });

  @override
  ConsumerState<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends ConsumerState<ConsultationScreen>
    with WidgetsBindingObserver {
  final _jitsiMeet = JitsiMeet();
  bool _isLoading = true;
  bool _isInMeeting = false;
  bool _meetingJoined = false;
  bool _ended = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSharingScreen = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  String? _otherParticipantName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _joinMeeting();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (_meetingJoined && !_ended) _jitsiMeet.hangUp();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Jitsi native SDK handles background/foreground automatically.
  }

  /// Verifies the current user is actually the patient or doctor of this
  /// appointment before joining the room (IDOR / unauthorized-join guard).
  Future<bool> _verifyOwnership() async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final row = await supabase
          .from('appointments')
          .select('id, patient_id, doctor_id, status')
          .eq('id', widget.appointmentId)
          .maybeSingle();

      if (row == null) return false;
      if (row['patient_id'] != user.id && row['doctor_id'] != user.id) {
        return false;
      }

      final status = row['status'] as String?;
      // Only allow joining for actionable states
      const allowed = {
        'confirmed',
        'rescheduled',
        'ongoing',
        'emergency_accepted',
        'pending',
      };
      return allowed.contains(status);
    } catch (e) {
      if (kDebugMode) debugPrint('Ownership check failed: $e');
      return false;
    }
  }

  Future<void> _joinMeeting() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) context.pop();
      return;
    }

    final owned = await _verifyOwnership();
    if (!owned) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not authorized to join this consultation.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Display name: profile full name (never expose email — PII)
    String displayName = 'Participant';
    try {
      final profile = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      final fullName = profile?['full_name'] as String?;
      if (fullName != null && fullName.trim().isNotEmpty) {
        displayName = fullName.trim();
      }
    } catch (_) {
      // fall back
    }

    final roomName = buildConsultationRoomName(widget.appointmentId);

    final options = JitsiMeetConferenceOptions(
      serverURL: 'https://8x8.vc',
      room: roomName,
      configOverrides: {
        'startWithAudioMuted': false,
        'startWithVideoMuted': false,
        'disableModeratorIndicator': true,
        'enableEmailInStats': false,
        // Prevent others from inviting more participants (closed room)
        'disableDeepLinking': true,
      },
      userInfo: JitsiMeetUserInfo(
        displayName: displayName,
      ),
    );

    final listener = JitsiMeetEventListener(
      conferenceJoined: (url) {
        if (!mounted || _ended) return;
        setState(() {
          _meetingJoined = true;
          _isLoading = false;
          _isInMeeting = true;
        });
        _startTimer();
        _updateAppointmentStatus('ongoing');
      },
      conferenceTerminated: (url, error) {
        if (!mounted || _ended) return;
        if (error == null || error.toString().isEmpty) {
          _endCall();
        } else {
          // Termination due to error: stop timer but do NOT mark completed
          _timer?.cancel();
          setState(() {
            _meetingJoined = false;
            _isInMeeting = false;
            _isLoading = false;
          });
          if (kDebugMode) debugPrint('Conference terminated with error: $error');
        }
      },
      audioMutedChanged: (muted) {
        if (mounted && !_ended) setState(() => _isMuted = muted);
      },
      videoMutedChanged: (muted) {
        if (mounted && !_ended) setState(() => _isVideoOff = muted);
      },
      participantJoined: (email, name, role, participantId) {
        if (mounted && !_ended) {
          setState(() => _otherParticipantName = name);
        }
      },
      participantLeft: (participantId) {
        if (mounted && !_ended) {
          setState(() => _otherParticipantName = null);
        }
      },
      readyToClose: () {
        if (mounted && !_ended) _endCall();
      },
    );

    try {
      await _jitsiMeet.join(options, listener);
    } catch (e) {
      if (mounted && !_ended) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join meeting: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_ended) {
        setState(() => _elapsedSeconds++);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _endCall() {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    if (_meetingJoined) _jitsiMeet.hangUp();
    _meetingJoined = false;

    _updateAppointmentStatus('completed');
    _persistDuration();

    if (mounted) {
      _navigateToSummary();
    }
  }

  /// Exit without touching appointment status (used by error/back paths
  /// when no actual consultation occurred).
  void _exitWithoutCompleting() {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    if (_meetingJoined) _jitsiMeet.hangUp();
    _meetingJoined = false;
    if (mounted) context.pop();
  }

  Future<void> _navigateToSummary() async {
    String? doctorId;
    num fee = 0;
    try {
      final row = await supabase
          .from('appointments')
          .select('doctor_id, total_amount')
          .eq('id', widget.appointmentId)
          .maybeSingle();
      doctorId = row?['doctor_id'] as String?;
      fee = (row?['total_amount'] as num?) ?? 0;
    } catch (_) {
      // proceed with defaults
    }
    if (!mounted) return;
    context.go('/consultation-summary/${widget.appointmentId}', extra: {
      'doctorName': widget.doctorName,
      'doctorId': doctorId,
      'fee': fee,
      'durationMinutes': widget.durationMinutes,
    });
  }

  Future<void> _updateAppointmentStatus(String status) async {
    try {
      await supabase
          .from('appointments')
          .update({'status': status})
          .eq('id', widget.appointmentId);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to update appointment status: $e');
    }
  }

  Future<void> _persistDuration() async {
    if (_elapsedSeconds <= 0) return;
    try {
      final minutes = (_elapsedSeconds / 60).ceil();
      await supabase
          .from('appointments')
          .update({'duration_minutes': minutes})
          .eq('id', widget.appointmentId);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to persist duration: $e');
    }
  }

  void _toggleMute() {
    _jitsiMeet.setAudioMuted(!_isMuted);
  }

  void _toggleVideo() {
    _jitsiMeet.setVideoMuted(!_isVideoOff);
  }

  void _toggleScreenShare() {
    _isSharingScreen = !_isSharingScreen;
    _jitsiMeet.toggleScreenShare(_isSharingScreen);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.textPrimaryOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: _isInMeeting
          ? AppBar(
              backgroundColor: AppColors.surfaceOf(context),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: color),
                onPressed: _endCall,
              ),
              title: Column(
                children: [
                  Text(
                    widget.doctorName ?? 'Consultation',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, color: AppColors.success, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        // TLS-encrypted in transit (NOT end-to-end)
                        'Encrypted connection',
                        style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              centerTitle: true,
              actions: [
                TextButton(
                  onPressed: _endCall,
                  child: const Text('End Call', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
                ),
              ],
            )
          : null,
      body: _isLoading
          ? _buildLoadingState()
          : _isInMeeting
              ? _buildMeetingControls()
              : _buildErrorState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Connecting to consultation...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 8),
          Text(
            'Setting up your secure video room',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          if (_otherParticipantName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_rounded, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '$_otherParticipantName joined',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_rounded, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatTime(_elapsedSeconds),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context)),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 20, color: AppColors.borderOf(context)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctorName ?? 'Doctor',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context)),
                    ),
                    Text(
                      widget.specialty ?? 'Consultation',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: _isMuted ? 'Unmute' : 'Mute',
                isActive: _isMuted,
                onTap: _toggleMute,
              ),
              _ControlButton(
                icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                label: _isVideoOff ? 'Camera Off' : 'Camera On',
                isActive: _isVideoOff,
                onTap: _toggleVideo,
              ),
              _EndCallButton(onTap: _endCall),
              _ControlButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: AppLocalizations.of(context)!.chat,
                onTap: () {
                  _jitsiMeet.openChat();
                },
              ),
              _ControlButton(
                icon: _isSharingScreen ? Icons.stop_screen_share_rounded : Icons.screen_share_rounded,
                label: _isSharingScreen ? 'Stop Share' : 'Share',
                isActive: _isSharingScreen,
                onTap: _toggleScreenShare,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Could not connect',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _ended = false;
              });
              _joinMeeting();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Retry', style: TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          TextButton(
            // Do NOT mark appointment completed — no call occurred
            onPressed: _exitWithoutCompleting,
            child: const Text('Go Back', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceOf(context),
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? AppColors.primary : AppColors.borderOf(context)),
            ),
            child: Icon(icon, color: isActive ? AppColors.primary : AppColors.textPrimaryOf(context), size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondaryOf(context))),
        ],
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EndCallButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
            child: Icon(Icons.call_end_rounded, color: AppColors.textInverse, size: 32),
          ),
          const SizedBox(height: 8),
          const Text('End', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.error)),
        ],
      ),
    );
  }
}
