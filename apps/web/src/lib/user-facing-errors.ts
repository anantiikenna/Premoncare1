type ErrorLike = {
  message?: string
  code?: string
  status?: number
}

function errorText(error: unknown) {
  if (typeof error === 'string') return error
  if (error && typeof error === 'object') {
    const err = error as ErrorLike
    return [err.message, err.code, err.status?.toString()].filter(Boolean).join(' ')
  }
  return ''
}

export function getUserFacingError(error: unknown, fallback = 'Something went wrong. Please try again.') {
  const text = errorText(error).toLowerCase()

  if (!text) return fallback
  if (text.includes('otp') || text.includes('token') || text.includes('code')) {
    if (text.includes('expired')) return 'That code has expired. Request a new code and try again.'
    if (text.includes('invalid')) return 'That code is incorrect. Please check the digits and try again.'
  }
  if (text.includes('email not confirmed')) {
    return 'Please verify your email address before signing in.'
  }
  if (text.includes('already registered') || text.includes('already exists') || text.includes('duplicate')) {
    return 'An account already exists for this email. Please sign in with your email code.'
  }
  if (text.includes('rate limit') || text.includes('too many') || text.includes('429')) {
    return 'Too many attempts. Please wait a moment before trying again.'
  }
  if (text.includes('network') || text.includes('fetch') || text.includes('timeout') || text.includes('failed to fetch')) {
    return 'We could not reach Premon Care. Check your connection and try again.'
  }
  if (text.includes('permission denied') || text.includes('42501') || text.includes('row-level security')) {
    return 'You do not have permission to complete this action. Please contact support if this seems wrong.'
  }

  return fallback
}
