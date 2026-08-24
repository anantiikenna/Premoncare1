String formatDoctorName(String? title, String? fullName) {
  final t = (title != null && title.isNotEmpty) ? title : 'Dr.';
  return '$t ${fullName ?? 'Doctor'}';
}
