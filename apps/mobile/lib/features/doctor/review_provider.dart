import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_locator.dart';

class Review {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      appointmentId: json['appointment_id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Providers
final doctorReviewsProvider = StreamProvider.family<List<Review>, String>((ref, doctorId) {
  return supabase
      .from('reviews')
      .stream(primaryKey: ['id'])
      .eq('doctor_id', doctorId)
      .order('created_at', ascending: false)
      .map((data) => data.map((item) => Review.fromJson(item)).toList());
});

class ReviewService {
  static Future<void> submitReview({
    required String appointmentId,
    required String doctorId,
    required int rating,
    String? comment,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await supabase.from('reviews').insert({
      'appointment_id': appointmentId,
      'patient_id': user.id,
      'doctor_id': doctorId,
      'rating': rating,
      'comment': comment,
    });

    // Note: Database RLS ensures only the patient who had the appointment can review.
  }
}
