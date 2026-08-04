import { getUserFacingError } from '@/lib/user-facing-errors'

describe('getUserFacingError', () => {
  it('returns fallback for unknown errors', () => {
    expect(getUserFacingError(null)).toBe('Something went wrong. Please try again.')
    expect(getUserFacingError(undefined)).toBe('Something went wrong. Please try again.')
    expect(getUserFacingError(42)).toBe('Something went wrong. Please try again.')
  })

  it('returns custom fallback when provided', () => {
    expect(getUserFacingError(null, 'Custom fallback')).toBe('Custom fallback')
  })

  it('handles OTP expired errors', () => {
    expect(getUserFacingError('OTP expired')).toContain('expired')
  })

  it('handles OTP invalid errors', () => {
    expect(getUserFacingError('Invalid OTP code')).toContain('incorrect')
  })

  it('handles email not confirmed', () => {
    expect(getUserFacingError('email not confirmed')).toContain('verify your email')
  })

  it('handles already registered errors', () => {
    expect(getUserFacingError('already registered')).toContain('already exists')
    expect(getUserFacingError('duplicate key error')).toContain('already exists')
  })

  it('handles rate limit errors', () => {
    expect(getUserFacingError('rate limit exceeded')).toContain('Too many')
    expect(getUserFacingError('429 too many')).toContain('Too many')
  })

  it('handles network errors', () => {
    expect(getUserFacingError('network error')).toContain('connection')
    expect(getUserFacingError('Failed to fetch')).toContain('connection')
    expect(getUserFacingError('timeout')).toContain('connection')
  })

  it('handles permission errors', () => {
    expect(getUserFacingError('permission denied')).toContain('permission')
    expect(getUserFacingError('42501')).toContain('permission')
    expect(getUserFacingError('row-level security')).toContain('permission')
  })

  it('handles Error objects', () => {
    const error = new Error('OTP expired')
    expect(getUserFacingError(error)).toContain('expired')
  })

  it('handles objects with code property', () => {
    const error = { code: '429', message: 'rate limit' }
    expect(getUserFacingError(error)).toContain('Too many')
  })
})
