import {
  emergencyAmount,
  emergencyHourlyRate,
  resolveHourlyRate,
  EMERGENCY_MULTIPLIER,
  EMERGENCY_DEFAULT_RATE,
} from '@/lib/emergency-pricing'

describe('emergency pricing (5× base hourly rate, cross-platform contract)', () => {
  it('exposes the contract constants', () => {
    expect(EMERGENCY_MULTIPLIER).toBe(5)
    expect(EMERGENCY_DEFAULT_RATE).toBe(50)
  })

  describe('resolveHourlyRate', () => {
    it('prefers consultation_fee when set', () => {
      expect(resolveHourlyRate(15000, 9000)).toBe(15000)
    })

    it('falls back to hourly_rate when consultation_fee is 0 or null', () => {
      expect(resolveHourlyRate(0, 9000)).toBe(9000)
      expect(resolveHourlyRate(null, 9000)).toBe(9000)
      expect(resolveHourlyRate(undefined, 9000)).toBe(9000)
    })

    it('falls back to the default rate of 50 when neither is set', () => {
      expect(resolveHourlyRate(null, null)).toBe(50)
      expect(resolveHourlyRate(0, 0)).toBe(50)
      expect(resolveHourlyRate(undefined, undefined)).toBe(50)
    })
  })

  describe('emergencyAmount (booking charge)', () => {
    it('charges exactly 5× the hourly rate for a full hour', () => {
      expect(emergencyAmount(15000, null, 60)).toBe(75000)
      expect(emergencyAmount(15000, null, 60)).toBe(
        emergencyHourlyRate(15000, null)
      )
    })

    it('scales linearly with duration (₦15,000/hr doctor)', () => {
      expect(emergencyAmount(15000, null, 15)).toBe(18750)
      expect(emergencyAmount(15000, null, 30)).toBe(37500)
      expect(emergencyAmount(15000, null, 45)).toBe(56250)
      expect(emergencyAmount(15000, null, 60)).toBe(75000)
    })

    it('uses hourly_rate when consultation_fee is unset', () => {
      expect(emergencyAmount(0, 8000, 15)).toBe(10000)
      expect(emergencyAmount(null, 8000, 30)).toBe(20000)
    })

    it('uses the default rate of 50 when no rate is set', () => {
      expect(emergencyAmount(null, null, 15)).toBe(63)
      expect(emergencyAmount(0, 0, 45)).toBe(188)
    })

    it('rounds half up to whole naira (identical on both platforms)', () => {
      expect(emergencyAmount(12345, null, 15)).toBe(15431)
      expect(emergencyAmount(null, null, 15)).toBe(63)
      expect(emergencyAmount(null, null, 45)).toBe(188)
      expect(emergencyAmount(15000.5, null, 60)).toBe(75003)
    })

    it('returns 0 for a 0-minute duration', () => {
      expect(emergencyAmount(15000, null, 0)).toBe(0)
    })
  })

  describe('emergencyHourlyRate (list badge)', () => {
    it('is 5× the resolved hourly rate', () => {
      expect(emergencyHourlyRate(15000, 9000)).toBe(75000)
      expect(emergencyHourlyRate(0, 8000)).toBe(40000)
      expect(emergencyHourlyRate(null, null)).toBe(250)
    })
  })
})
