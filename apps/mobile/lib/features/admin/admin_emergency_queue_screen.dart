import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class EmergencyCase {
  final String id;
  final String patientId;
  final String? patientName;
  final String? patientAvatarUrl;
  final String? specialty;
  final String? reason;
  final String? symptomDescription;
  final String? status;
  final DateTime createdAt;
  final bool isUrgent;

  const EmergencyCase({
    required this.id,
    required this.patientId,
    this.patientName,
    this.patientAvatarUrl,
    this.specialty,
    this.reason,
    this.symptomDescription,
    this.status,
    required this.createdAt,
    this.isUrgent = false,
  });

  factory EmergencyCase.fromJson(Map<String, dynamic> json) {
    final profile = json['patient_profile'] as Map<String, dynamic>?;
    final symptom = json['symptom_entries'] as List<dynamic>?;
    final symptomEntry =
        symptom != null && symptom.isNotEmpty ? symptom.first : null;

    return EmergencyCase(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      patientName: profile?['full_name'] as String?,
      patientAvatarUrl: profile?['avatar_url'] as String?,
      specialty: json['specialty'] as String?,
      reason: json['reason'] as String?,
      symptomDescription: symptomEntry?['description'] as String?,
      status: json['status'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isUrgent: json['is_emergency'] as bool? ?? false,
    );
  }
}

class EmergencyQueueAsync {
  final List<EmergencyCase> cases;

  const EmergencyQueueAsync({required this.cases});
}

final emergencyQueueProvider =
    StreamProvider.autoDispose<EmergencyQueueAsync>((ref) async* {
      final stream = _supabase
          .from('appointments')
          .stream(primaryKey: ['id'])
          .eq('is_emergency', true)
          .inFilter('status', [
            'emergency_request',
            'emergency_accepted',
            'emergency_active',
            'ongoing',
          ])
          .order('created_at', ascending: false);

      await for (final events in stream) {
        if (events.isEmpty) {
          yield const EmergencyQueueAsync(cases: []);
          return;
        }

        final caseIds = events.map((e) => e['id'] as String).toList();

        final profilesQuery = await _supabase
            .from('profiles')
            .select('id, full_name, avatar_url')
            .inFilter('id', events.map((e) => e['patient_id'] as String).toList());

        final profilesMap = <String, Map<String, dynamic>>{};
        for (final p in profilesQuery) {
          profilesMap[p['id'] as String] = p;
        }

        final symptomsQuery = await _supabase
            .from('symptom_entries')
            .select('id, description, appointment_id')
            .inFilter('appointment_id', caseIds);

        final symptomsMap = <String, List<Map<String, dynamic>>>{};
        for (final s in symptomsQuery) {
          final apptId = s['appointment_id'] as String;
          symptomsMap.putIfAbsent(apptId, () => []).add(s);
        }

        final emergencyCases =
            events.map((e) {
              final caseId = e['id'] as String;
              final patientId = e['patient_id'] as String;
              final patientProfile = profilesMap[patientId];
              final caseSymptoms = symptomsMap[caseId];
              final firstSymptom =
                  caseSymptoms != null && caseSymptoms.isNotEmpty
                      ? caseSymptoms.first
                      : null;

              return EmergencyCase(
                id: caseId,
                patientId: patientId,
                patientName: patientProfile?['full_name'] as String?,
                patientAvatarUrl:
                    patientProfile?['avatar_url'] as String?,
                specialty: e['specialty'] as String?,
                reason: e['reason'] as String?,
                symptomDescription:
                    firstSymptom?['description'] as String?,
                status: e['status'] as String?,
                createdAt: DateTime.parse(e['created_at'] as String),
                isUrgent: e['is_emergency'] as bool? ?? false,
              );
            }).toList();

        yield EmergencyQueueAsync(cases: emergencyCases);
      }
    });

final selectedCaseProvider = StateProvider<EmergencyCase?>((ref) => null);

class AdminEmergencyQueueScreen extends ConsumerStatefulWidget {
  const AdminEmergencyQueueScreen({super.key});

  @override
  ConsumerState<AdminEmergencyQueueScreen> createState() =>
      _AdminEmergencyQueueScreenState();
}

class _AdminEmergencyQueueScreenState
    extends ConsumerState<AdminEmergencyQueueScreen> {
  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(emergencyQueueProvider);
    final selectedCase = ref.watch(selectedCaseProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildQueueList(queueAsync),
          ),
          if (MediaQuery.of(context).size.width > 900)
            Expanded(
              flex: 3,
              child: selectedCase != null
                  ? _buildDetailView(selectedCase)
                  : _buildEmptyDetailView(),
            ),
        ],
      ),
    );
  }

  Widget _buildQueueList(AsyncValue<EmergencyQueueAsync> queueAsync) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        border: Border(
          right: BorderSide(
            color: AppColors.borderLightOf(context),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderLightOf(context),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorLightOf(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.emergency,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.emergencyQueue,
                        style: AppTypography.headlineMedium(context).copyWith(
                          color: AppColors.textPrimaryOf(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                queueAsync.when(
                  data: (queue) {
                    final pending = queue.cases
                        .where((c) => c.status == 'emergency_request')
                        .length;
                    final accepted = queue.cases
                        .where((c) =>
                            c.status == 'emergency_accepted' ||
                            c.status == 'ongoing')
                        .length;

                    return Row(
                      children: [
                        _buildStatusChip(
                          '${queue.cases.length} ${AppLocalizations.of(context)!.totalLabel}',
                          AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          '$pending ${AppLocalizations.of(context)!.pendingLabel}',
                          AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          '$accepted ${AppLocalizations.of(context)!.acceptedStatusLabel}',
                          AppColors.success,
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(height: 24),
                  error: (_, __) => const SizedBox(height: 24),
                ),
              ],
            ),
          ),
          Expanded(
            child: queueAsync.when(
              data: (queue) {
                if (queue.cases.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildCaseList(queue.cases);
              },
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium(context).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCaseList(List<EmergencyCase> cases) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final emergencyCase = cases[index];
        return _buildCaseCard(emergencyCase);
      },
    );
  }

  Widget _buildCaseCard(EmergencyCase emergencyCase) {
    final isSelected = ref.watch(selectedCaseProvider)?.id == emergencyCase.id;
    final statusColor = _getStatusColor(emergencyCase.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(selectedCaseProvider.notifier).state = emergencyCase;
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? statusColor.withValues(alpha: 0.05)
                  : AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? statusColor.withValues(alpha: 0.5)
                    : AppColors.borderLightOf(context),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        _buildPatientAvatar(
                          emergencyCase.patientName,
                          emergencyCase.patientAvatarUrl,
                        ),
                        if (emergencyCase.isUrgent)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.backgroundOf(context),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.warning,
                                color: AppColors.textInverse,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  emergencyCase.patientName ?? AppLocalizations.of(context)!.unknownPatient,
                                  style: AppTypography.titleMedium(context)
                                      .copyWith(
                                    color: AppColors.textPrimaryOf(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (emergencyCase.status ==
                                  'emergency_request')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.pendingReview,
                                    style: AppTypography.labelSmall(
                                      context,
                                    ).copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            emergencyCase.specialty ?? AppLocalizations.of(context)!.noSpecialtyAssigned,
                            style: AppTypography.bodySmall(context).copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (emergencyCase.reason != null &&
                    emergencyCase.reason!.isNotEmpty)
                  _buildInfoRow(
                    Icons.info_outline,
                    AppLocalizations.of(context)!.reasonLabel,
                    emergencyCase.reason!,
                  ),
                if (emergencyCase.symptomDescription != null &&
                    emergencyCase.symptomDescription!.isNotEmpty)
                  _buildInfoRow(
                    Icons.medical_services_outlined,
                    AppLocalizations.of(context)!.symptomsLabel,
                    emergencyCase.symptomDescription!,
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textTertiaryOf(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimeAgo(emergencyCase.createdAt),
                      style: AppTypography.labelMedium(context).copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const Spacer(),
                    _buildStatusChip(
                      _getStatusLabel(emergencyCase.status),
                      statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiaryOf(context)),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: AppTypography.labelMedium(context).copyWith(
                      color: AppColors.textTertiaryOf(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: AppTypography.labelMedium(context).copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientAvatar(String? name, String? avatarUrl) {
    final initial =
        name != null && name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.textTertiaryOf(context),
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Text(
        initial,
        style: AppTypography.titleMedium(context).copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDetailView(EmergencyCase emergencyCase) {
    final statusColor = _getStatusColor(emergencyCase.status);

    return Container(
      color: AppColors.backgroundOf(context),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLightOf(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.emergency,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emergencyCase.patientName ?? AppLocalizations.of(context)!.unknownPatient,
                      style: AppTypography.headlineMedium(context).copyWith(
                        color: AppColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${emergencyCase.specialty ?? AppLocalizations.of(context)!.noSpecialty} - ${_getStatusLabel(emergencyCase.status)}',
                      style: AppTypography.bodyMedium(context).copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: AppColors.textSecondaryOf(context),
                ),
                onPressed: () {
                  ref.read(selectedCaseProvider.notifier).state = null;
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailCard(
                    AppLocalizations.of(context)!.emergencyRequestChecklist,
                    _buildResponseChecklist(emergencyCase),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailCard(
                    AppLocalizations.of(context)!.clinicalDetails,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          AppLocalizations.of(context)!.reasonLabel,
                          emergencyCase.reason ?? AppLocalizations.of(context)!.notProvided,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          AppLocalizations.of(context)!.symptomsLabel,
                          emergencyCase.symptomDescription ?? AppLocalizations.of(context)!.notProvided,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          AppLocalizations.of(context)!.timeOfRequest,
                          _formatDateTime(emergencyCase.createdAt),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseChecklist(EmergencyCase emergencyCase) {
    final status = emergencyCase.status;
    final hasAccepted =
        status == 'emergency_accepted' ||
        status == 'ongoing' ||
        status == 'emergency_active';
    final hasStarted =
        status == 'ongoing' || status == 'emergency_active';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChecklistItem(
          AppLocalizations.of(context)!.emergencyRequestReceived,
          true,
          AppColors.success,
        ),
        _buildChecklistItem(
          AppLocalizations.of(context)!.notifyAvailableDoctors,
          hasAccepted,
          hasAccepted ? AppColors.success : AppColors.warning,
        ),
        _buildChecklistItem(
          AppLocalizations.of(context)!.doctorAcceptedRequest,
          hasAccepted,
          hasAccepted ? AppColors.success : AppColors.textTertiaryOf(context),
        ),
        _buildChecklistItem(
          AppLocalizations.of(context)!.consultationInProgress,
          hasStarted,
          hasStarted ? AppColors.success : AppColors.textTertiaryOf(context),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(String label, bool completed, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: completed ? color.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: color,
                width: 2,
              ),
            ),
            child: completed
                ? Icon(Icons.check, color: color, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium(context).copyWith(
                color: completed
                    ? AppColors.textPrimaryOf(context)
                    : AppColors.textSecondaryOf(context),
                fontWeight: completed ? FontWeight.w600 : FontWeight.w400,
                decoration: completed ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textTertiaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLightOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium(context).copyWith(
              color: AppColors.textPrimaryOf(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium(context).copyWith(
            color: AppColors.textTertiaryOf(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.bodyMedium(context).copyWith(
            color: AppColors.textPrimaryOf(context),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDetailView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.textTertiaryOf(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.touch_app,
              color: AppColors.textTertiaryOf(context),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.selectAnEmergencyCase,
            style: AppTypography.titleLarge(context).copyWith(
              color: AppColors.textPrimaryOf(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.chooseCaseFromQueue,
            style: AppTypography.bodyMedium(context).copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.successLightOf(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.noEmergencyConsults,
              style: AppTypography.titleLarge(context).copyWith(
                color: AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.allClearMessage,
              style: AppTypography.bodyMedium(context).copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.error,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.loadingEmergencies,
            style: AppTypography.bodyMedium(context).copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.errorLightOf(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.failedToLoadQueue,
              style: AppTypography.titleLarge(context).copyWith(
                color: AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.connectionIssue,
              style: AppTypography.bodyMedium(context).copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return AppLocalizations.of(context)!.justNow;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ${AppLocalizations.of(context)!.agoLabel}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${AppLocalizations.of(context)!.agoLabel}';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return AppLocalizations.of(context)!.justNow;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ${AppLocalizations.of(context)!.agoLabel}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${AppLocalizations.of(context)!.agoLabel}';
    } else {
      return DateFormat('MMM d, y HH:mm').format(dateTime);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'emergency_request':
        return AppColors.warning;
      case 'emergency_accepted':
        return AppColors.info;
      case 'ongoing':
      case 'emergency_active':
        return AppColors.success;
      default:
        return AppColors.textTertiaryOf(context);
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'emergency_request':
        return AppLocalizations.of(context)!.pendingLabel;
      case 'emergency_accepted':
        return AppLocalizations.of(context)!.acceptedStatusLabel;
      case 'ongoing':
      case 'emergency_active':
        return AppLocalizations.of(context)!.watchingLabel;
      default:
        return status?.toUpperCase() ?? '';
    }
  }
}
