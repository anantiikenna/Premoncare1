'use client'

const CONSENT_KEY = 'premon_cookie_consent'
const CONSENT_VERSION = '1.0'

export type ConsentChoice = 'accepted' | 'rejected' | null

export function getConsent(): ConsentChoice {
  if (typeof window === 'undefined') return null
  return localStorage.getItem(CONSENT_KEY) as ConsentChoice
}

export function setConsent(choice: 'accepted' | 'rejected'): void {
  localStorage.setItem(CONSENT_KEY, choice)
  localStorage.setItem(`${CONSENT_KEY}_version`, CONSENT_VERSION)

  if (choice === 'rejected') {
    removeNonEssentialCookies()
    if (typeof window !== 'undefined' && window.posthog) {
      window.posthog.opt_out_capturing()
    }
  } else {
    if (typeof window !== 'undefined' && window.posthog) {
      window.posthog.opt_in_capturing()
    }
  }
}

export function hasConsent(): boolean {
  return getConsent() !== null
}

export function removeNonEssentialCookies(): void {
  if (typeof document === 'undefined') return

  const essentialPrefixes = [
    'sb-',           // Supabase session tokens
    'premon_',       // App-internal consent state
    '__cf_',         // Cloudflare
    'cf_clearance',  // Cloudflare
  ]

  const cookies = document.cookie.split(';')
  for (const cookie of cookies) {
    const name = cookie.split('=')[0].trim()
    if (!name) continue

    const isEssential = essentialPrefixes.some((prefix) => name.startsWith(prefix))
    if (!isEssential) {
      document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/`
    }
  }
}

declare global {
  interface Window {
    posthog?: {
      opt_out_capturing: () => void
      opt_in_capturing: () => void
    }
  }
}
