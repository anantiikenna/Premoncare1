String formatDoctorName(String? title, String? fullName) {
  final t = (title != null && title.isNotEmpty) ? title : 'Dr.';
  final name = (fullName != null && fullName.isNotEmpty) ? fullName : 'Doctor';
  return '$t $name';
}
