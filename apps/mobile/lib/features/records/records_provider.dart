import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_locator.dart';

enum RecordType { labResult, prescription, imaging, immunization, clinicalNote, other }

class MedicalRecord {
  final String id;
  final String patientId;
  final String title;
  final String? description;
  final RecordType recordType;
  final String documentUrl;
  final List<String> authorizedDoctors;
  final DateTime createdAt;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.title,
    this.description,
    required this.recordType,
    required this.documentUrl,
    required this.authorizedDoctors,
    required this.createdAt,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'],
      patientId: json['patient_id'],
      title: json['title'],
      description: json['description'],
      recordType: RecordType.values.firstWhere(
        (e) => e.name == json['record_type'],
        orElse: () => RecordType.other,
      ),
      documentUrl: json['document_url'],
      authorizedDoctors: List<String>.from(json['authorized_doctors'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Provider for patient's personal medical records vault
final patientRecordsProvider = StreamProvider.autoDispose<List<MedicalRecord>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('medical_records')
      .stream(primaryKey: ['id'])
      .eq('patient_id', user.id)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => MedicalRecord.fromJson(json)).toList());
});

/// Provider for records shared WITH a doctor
final authorizedRecordsProvider = StreamProvider.autoDispose<List<MedicalRecord>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('medical_records')
      .stream(primaryKey: ['id'])
      .contains('authorized_doctors', [user.id])
      .order('created_at', ascending: false)
      .limit(100)
      .map((data) => data.map((json) => MedicalRecord.fromJson(json)).toList());
});

class RecordsService {
  static Future<void> uploadRecord({
    required String title,
    required RecordType type,
    required File file,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Upload to storage
    final fileExt = file.path.split('.').last;
    final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    
    await supabase.storage.from('patient-medical-vault').upload(
      fileName,
      file,
    );

    // 2. Create DB record
    await supabase.from('medical_records').insert({
      'patient_id': user.id,
      'title': title,
      'record_type': type.name,
      'document_url': fileName,
    });
  }

  static Future<void> toggleAuthorization(String recordId, String doctorId, bool authorize) async {
    final res = await supabase
        .from('medical_records')
        .select('title, record_type, authorized_doctors')
        .eq('id', recordId)
        .single();
    
    final currentVisible = List<String>.from(res['authorized_doctors'] ?? []);
    if (authorize && !currentVisible.contains(doctorId)) {
      currentVisible.add(doctorId);
    } else if (!authorize) {
      currentVisible.remove(doctorId);
    }

    await supabase
        .from('medical_records')
        .update({'authorized_doctors': currentVisible})
        .eq('id', recordId);

    // If authorized, trigger a real-time notification to the doctor
    if (authorize) {
      try {
        final user = supabase.auth.currentUser;
        final session = supabase.auth.currentSession;
        final baseUrl = const String.fromEnvironment('NEXT_PUBLIC_SITE_URL', defaultValue: 'https://premoncare.com');
        
        if (session != null && user != null) {
          final title = 'Medical Record Shared';
          final type = res['record_type'] ?? 'Record';
          final recordTitle = res['title'] ?? 'Untitled';
          final message = 'A patient has shared a $type: "$recordTitle" with you.';

          // Call the unified dispatcher on the web backend
          await http.post(
            Uri.parse('$baseUrl/api/notifications/dispatch'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session.accessToken}',
            },
            body: jsonEncode({
              'userId': doctorId,
              'title': title,
              'message': message,
              'type': 'system', // Categorized as system/audit
              'link': '/doctor/records',
            }),
          );
        }
      } catch (e) {
        // We don't want to fail the main transaction if notification fails, 
        // but we log it for debugging.
        if (kDebugMode) debugPrint('Failed to send sharing notification: $e');
      }
    }
  }

  static Future<void> deleteRecord(MedicalRecord record) async {
    await supabase.storage.from('patient-medical-vault').remove([record.documentUrl]);
    await supabase.from('medical_records').delete().eq('id', record.id);
  }
}
