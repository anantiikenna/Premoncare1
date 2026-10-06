export const EMERGENCY_MULTIPLIER = 5
export const EMERGENCY_DEFAULT_RATE = 50

export function resolveHourlyRate(
    consultationFee?: number | null,
    hourlyRate?: number | null
): number {
    if (consultationFee && consultationFee > 0) return consultationFee
    if (hourlyRate && hourlyRate > 0) return hourlyRate
    return EMERGENCY_DEFAULT_RATE
}

export function emergencyAmount(
    consultationFee: number | null | undefined,
    hourlyRate: number | null | undefined,
    durationMinutes: number
): number {
    const rate = resolveHourlyRate(consultationFee, hourlyRate)
    return Math.round((rate * EMERGENCY_MULTIPLIER * durationMinutes) / 60)
}

export function emergencyHourlyRate(
    consultationFee?: number | null,
    hourlyRate?: number | null
): number {
    return Math.round(
        resolveHourlyRate(consultationFee, hourlyRate) * EMERGENCY_MULTIPLIER
    )
}
