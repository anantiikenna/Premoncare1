import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_locator.dart';

enum VerificationStep { professional, identity, facial, review }
enum VerificationField { license, govtIdFront, govtIdBack, selfie, govtId, address }

class VerificationState {
  final VerificationStep currentStep;
  final String title;
  final String specialty;
  final String experience;
  final String licenseNumber;
  final String? licenseUrl;
  final String? idType;
  final String? idFrontUrl;
  final String? idBackUrl;
  final String? idUrl; // Unified ID URL
  final String? addressUrl;
  final String? selfieUrl;
  final List<String> consultationModes;
  final bool agreed;
  final bool isSubmitting;
  final bool isUploading;
  final String? error;
  final String verificationStatus;
  final String? rejectionReason;

  VerificationState({
    this.currentStep = VerificationStep.professional,
    this.title = '',
    this.specialty = '',
    this.experience = '',
    this.licenseNumber = '',
    this.licenseUrl,
    this.idType,
    this.idFrontUrl,
    this.idBackUrl,
    this.idUrl,
    this.addressUrl,
    this.selfieUrl,
    this.consultationModes = const [],
    this.agreed = false,
    this.isSubmitting = false,
    this.isUploading = false,
    this.error,
    this.verificationStatus = 'unsubmitted',
    this.rejectionReason,
  });

  VerificationState copyWith({
    VerificationStep? currentStep,
    String? title,
    String? specialty,
    String? experience,
    String? licenseNumber,
    String? licenseUrl,
    String? idType,
    String? idFrontUrl,
    String? idBackUrl,
    String? idUrl,
    String? addressUrl,
    String? selfieUrl,
    List<String>? consultationModes,
    bool? agreed,
    bool? isSubmitting,
    bool? isUploading,
    String? error,
    String? verificationStatus,
    String? rejectionReason,
  }) {
    return VerificationState(
      currentStep: currentStep ?? this.currentStep,
      title: title ?? this.title,
      specialty: specialty ?? this.specialty,
      experience: experience ?? this.experience,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      idType: idType ?? this.idType,
      idFrontUrl: idFrontUrl ?? this.idFrontUrl,
      idBackUrl: idBackUrl ?? this.idBackUrl,
      idUrl: idUrl ?? this.idUrl,
      addressUrl: addressUrl ?? this.addressUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      consultationModes: consultationModes ?? this.consultationModes,
      agreed: agreed ?? this.agreed,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isUploading: isUploading ?? this.isUploading,
      error: error,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

class VerificationNotifier extends Notifier<VerificationState> {
  @override
  VerificationState build() {
    _fetchInitialStatus();
    return VerificationState();
  }

  Future<void> _fetchInitialStatus() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('profiles')
          .select('verification_status, title, specialty, experience_years, medical_license_number, rejection_reason')
          .eq('id', user.id)
          .single();

      state = state.copyWith(
        verificationStatus: data['verification_status'] ?? 'unsubmitted',
        title: data['title'] ?? '',
        specialty: data['specialty'] ?? '',
        experience: (data['experience_years'] ?? '').toString(),
        licenseNumber: data['medical_license_number'] ?? '',
        rejectionReason: data['rejection_reason'],
      );
    } catch (e) {
      // Ignore initial fetch errors
    }
  }

  void resetVerification() {
    state = VerificationState();
  }

  void nextStep() {
    final nextIdx = state.currentStep.index + 1;
    if (nextIdx < VerificationStep.values.length) {
      state = state.copyWith(currentStep: VerificationStep.values[nextIdx]);
    }
  }

  void previousStep() {
    final prevIdx = state.currentStep.index - 1;
    if (prevIdx >= 0) {
      state = state.copyWith(currentStep: VerificationStep.values[prevIdx]);
    }
  }

  void goToStep(VerificationStep step) {
    state = state.copyWith(currentStep: step);
  }

  void updateProfessional(String title, String specialty, String experience, String license) {
    state = state.copyWith(
      title: title,
      specialty: specialty,
      experience: experience,
      licenseNumber: license,
    );
  }

  void updateIdType(String type) {
    state = state.copyWith(idType: type);
  }

  void toggleConsultationMode(String mode) {
    final modes = List<String>.from(state.consultationModes);
    if (modes.contains(mode)) {
      modes.remove(mode);
    } else {
      modes.add(mode);
    }
    state = state.copyWith(consultationModes: modes);
  }

  void setAgreed(bool agreed) {
    state = state.copyWith(agreed: agreed);
  }

  Future<void> uploadFile(File file, VerificationField field, String fileName) async {
    state = state.copyWith(isUploading: true, error: null);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Map field to bucket
      String bucket;
      switch (field) {
        case VerificationField.license:
          bucket = 'doctor-verifications';
          break;
        case VerificationField.govtIdFront:
        case VerificationField.govtIdBack:
        case VerificationField.govtId:
        case VerificationField.address:
        case VerificationField.selfie:
          bucket = 'doctor-identities';
          break;
      }

      final path = '${user.id}/$fileName';
      await supabase.storage.from(bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      // Map field to state
      switch (field) {
        case VerificationField.license:
          state = state.copyWith(licenseUrl: path);
          break;
        case VerificationField.govtIdFront:
          state = state.copyWith(idFrontUrl: path);
          break;
        case VerificationField.govtIdBack:
          state = state.copyWith(idBackUrl: path);
          break;
        case VerificationField.govtId:
          state = state.copyWith(idUrl: path);
          break;
        case VerificationField.address:
          state = state.copyWith(addressUrl: path);
          break;
        case VerificationField.selfie:
          state = state.copyWith(selfieUrl: path);
          break;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isUploading: false);
    }
  }

  Future<bool> submit() async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await supabase.from('profiles').update({
        'title': state.title,
        'specialty': state.specialty,
        'experience_years': int.tryParse(state.experience) ?? 0,
        'verification_document_url': state.licenseUrl,
        'identity_document_front_url': state.idFrontUrl,
        'identity_document_back_url': state.idBackUrl,
        'identity_type': state.idType,
        'live_selfie_url': state.selfieUrl,
        'medical_license_number': state.licenseNumber,
        'preferred_consultation_types': state.consultationModes,
        'requested_role': 'doctor',
        'verification_status': 'pending',
      }).eq('id', user.id);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

final verificationProvider = NotifierProvider<VerificationNotifier, VerificationState>(() {
  return VerificationNotifier();
});
