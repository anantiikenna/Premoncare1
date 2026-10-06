import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/pricing.dart';

void main() {
  group('resolveHourlyRate (cross-platform contract)', () {
    test('prefers consultation_fee when set', () {
      expect(resolveHourlyRate(consultationFee: 15000, hourlyRate: 9000), 15000);
    });

    test('falls back to hourly_rate when consultation_fee is 0 or null', () {
      expect(resolveHourlyRate(consultationFee: 0, hourlyRate: 9000), 9000);
      expect(resolveHourlyRate(hourlyRate: 9000), 9000);
    });

    test('falls back to the default rate of 50 when neither is set', () {
      expect(resolveHourlyRate(), 50);
      expect(resolveHourlyRate(consultationFee: 0, hourlyRate: 0), 50);
    });
  });

  group('emergencyAmount (5× base hourly rate)', () {
    test('charges exactly 5× the hourly rate for a full hour', () {
      expect(
        emergencyAmount(consultationFee: 15000, durationMinutes: 60),
        75000,
      );
      expect(
        emergencyAmount(consultationFee: 15000, durationMinutes: 60),
        emergencyHourlyRate(consultationFee: 15000),
      );
    });

    test('scales linearly with duration (₦15,000/hr doctor)', () {
      expect(emergencyAmount(consultationFee: 15000, durationMinutes: 15), 18750);
      expect(emergencyAmount(consultationFee: 15000, durationMinutes: 30), 37500);
      expect(emergencyAmount(consultationFee: 15000, durationMinutes: 45), 56250);
      expect(emergencyAmount(consultationFee: 15000, durationMinutes: 60), 75000);
    });

    test('uses hourly_rate when consultation_fee is unset', () {
      expect(
        emergencyAmount(consultationFee: 0, hourlyRate: 8000, durationMinutes: 15),
        10000,
      );
      expect(
        emergencyAmount(hourlyRate: 8000, durationMinutes: 30),
        20000,
      );
    });

    test('uses the default rate of 50 when no rate is set', () {
      expect(emergencyAmount(durationMinutes: 15), 63);
      expect(emergencyAmount(consultationFee: 0, hourlyRate: 0, durationMinutes: 45), 188);
    });

    test('rounds half up to whole naira (identical on both platforms)', () {
      expect(emergencyAmount(consultationFee: 12345, durationMinutes: 15), 15431);
      expect(emergencyAmount(durationMinutes: 15), 63);
      expect(emergencyAmount(durationMinutes: 45), 188);
      expect(emergencyAmount(consultationFee: 15000.5, durationMinutes: 60), 75003);
    });

    test('returns 0 for a 0-minute duration', () {
      expect(emergencyAmount(consultationFee: 15000, durationMinutes: 0), 0);
    });
  });

  group('emergencyHourlyRate (list badge)', () {
    test('is 5× the resolved hourly rate', () {
      expect(emergencyHourlyRate(consultationFee: 15000, hourlyRate: 9000), 75000);
      expect(emergencyHourlyRate(consultationFee: 0, hourlyRate: 8000), 40000);
      expect(emergencyHourlyRate(), 250);
    });
  });
}
