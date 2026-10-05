import { NextRequest } from 'next/server'

jest.mock('@/lib/supabase-middleware', () => ({
  updateSession: jest.fn(async () => 'SESSION_RESPONSE'),
}))

import { proxy, config } from '@/proxy'
import { updateSession } from '@/lib/supabase-middleware'

describe('proxy config.matcher', () => {
  const matcher = new RegExp(`^(?:${config.matcher[0]})$`)

  it.each([
    '/patient/dashboard',
    '/doctor/appointments',
    '/admin/settings',
    '/login',
    '/register',
    '/emergency',
    '/messages',
    '/notifications',
    '/profile',
  ])('runs middleware for page route %s', (path) => {
    expect(matcher.test(path)).toBe(true)
  })

  it.each([
    '/api/notifications/dispatch',
    '/api/appointments/meeting',
    '/api/payments/checkout',
    '/api/user/export',
  ])('excludes API route %s (withSecurity owns /api/)', (path) => {
    expect(matcher.test(path)).toBe(false)
  })

  it.each([
    '/_next/static/chunks/main-abc123.js',
    '/_next/image?url=%2Flogo.png&w=1080&q=75',
    '/favicon.ico',
    '/logo.png',
    '/icon.svg',
    '/photo.jpg',
  ])('excludes static asset %s', (path) => {
    expect(matcher.test(path)).toBe(false)
  })
})

describe('proxy()', () => {
  it('delegates the request to updateSession', async () => {
    const request = new NextRequest('http://localhost/patient/dashboard')
    const result = await proxy(request)
    expect(result).toBe('SESSION_RESPONSE')
    expect(updateSession).toHaveBeenCalledWith(request)
  })
})
