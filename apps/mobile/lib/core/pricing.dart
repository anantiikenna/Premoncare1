const double emergencyMultiplier = 5;
const double emergencyDefaultRate = 50;

double resolveHourlyRate({double? consultationFee, double? hourlyRate}) {
  if (consultationFee != null && consultationFee > 0) return consultationFee;
  if (hourlyRate != null && hourlyRate > 0) return hourlyRate;
  return emergencyDefaultRate;
}

int emergencyAmount({
  double? consultationFee,
  double? hourlyRate,
  required int durationMinutes,
}) {
  final rate = resolveHourlyRate(
    consultationFee: consultationFee,
    hourlyRate: hourlyRate,
  );
  return (rate * emergencyMultiplier * durationMinutes / 60).round();
}

int emergencyHourlyRate({double? consultationFee, double? hourlyRate}) {
  final rate = resolveHourlyRate(
    consultationFee: consultationFee,
    hourlyRate: hourlyRate,
  );
  return (rate * emergencyMultiplier).round();
}
