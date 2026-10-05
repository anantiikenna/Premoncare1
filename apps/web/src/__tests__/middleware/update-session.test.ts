import { NextRequest, type NextResponse } from 'next/server'
import { createServerClient } from '@supabase/ssr'

jest.mock('@supabase/ssr', () => ({
  createServerClient: jest.fn(),
}))

import { updateSession } from '@/lib/supabase-middleware'

const mockGetUser = jest.fn()
const mockSingle = jest.fn()
const mockEq = jest.fn((_column: string, _value: string) => ({ single: mockSingle }))
const mockSelect = jest.fn((_columns: string) => ({ eq: mockEq }))
const mockFrom = jest.fn((_table: string) => ({ select: mockSelect }))

function makeRequest(path: string, cookies?: Record<string, string>) {
  const cookieHeader = Object.entries(cookies ?? {})
    .map(([name, value]) => `${name}=${value}`)
    .join('; ')
  return new NextRequest(`http://localhost${path}`, {
    headers: cookieHeader ? { cookie: cookieHeader } : {},
  })
}

function signIn(id: string, role?: string | null) {
  mockGetUser.mockResolvedValue({ data: { user: { id } } })
  mockSingle.mockResolvedValue({ data: role ? { role } : null })
}

function locationOf(res: NextResponse) {
  return res.headers.get('location')
}

beforeEach(() => {
  jest.clearAllMocks()
  jest.mocked(createServerClient).mockReturnValue({
    auth: { getUser: mockGetUser },
    from: mockFrom,
  } as unknown as ReturnType<typeof createServerClient>)
  mockGetUser.mockResolvedValue({ data: { user: null } })
  mockSingle.mockResolvedValue({ data: { role: 'patient' } })
})

describe('public routes (no auth check)', () => {
  it.each(['/', '/login', '/register', '/emergency', '/emergency-waiting', '/support', '/account-conversion'])(
    'serves %s without calling supabase auth',
    async (path) => {
      const res = await updateSession(makeRequest(path))
      expect(res.status).toBe(200)
      expect(mockGetUser).not.toHaveBeenCalled()
    }
  )
})

describe('logged-out users on protected routes', () => {
  it.each([
    '/admin/dashboard',
    '/doctor/appointments',
    '/patient/dashboard',
    '/notifications',
    '/messages',
    '/profile',
  ])('redirects %s to /login', async (path) => {
    const res = await updateSession(makeRequest(path))
    expect(res.status).toBe(307)
    expect(locationOf(res)).toBe('http://localhost/login')
  })

  it('does not redirect logged-out users on non-protected paths', async () => {
    const res = await updateSession(makeRequest('/some-public-page'))
    expect(res.status).toBe(200)
  })
})

describe('cross-role access prevention', () => {
  it.each([
    ['patient', '/admin/settings', '/patient/dashboard'],
    ['doctor', '/admin/settings', '/doctor/dashboard'],
    ['doctor', '/patient/records', '/doctor/dashboard'],
    ['patient', '/doctor/appointments', '/patient/dashboard'],
    ['admin', '/doctor/queue', '/admin/dashboard'],
    ['admin', '/patient/profile', '/admin/dashboard'],
  ])('role=%s on %s redirects to %s', async (role, path, expected) => {
    signIn('user-1', role)
    const res = await updateSession(makeRequest(path))
    expect(res.status).toBe(307)
    expect(locationOf(res)).toBe(`http://localhost${expected}`)
  })

  it.each([
    ['admin', '/admin/dashboard'],
    ['doctor', '/doctor/appointments'],
    ['patient', '/patient/dashboard'],
  ])('role=%s may access own area %s', async (role, path) => {
    signIn('user-1', role)
    const res = await updateSession(makeRequest(path))
    expect(res.status).toBe(200)
  })

  it('allows non-doctors to open /doctor/apply (verification wizard)', async () => {
    signIn('user-1', 'patient')
    const res = await updateSession(makeRequest('/doctor/apply'))
    expect(res.status).toBe(200)
  })
})

describe('login/register are public routes', () => {
  it('serves /login to authenticated users without an auth check', async () => {
    signIn('user-1', 'admin')
    const res = await updateSession(makeRequest('/login'))
    expect(res.status).toBe(200)
    expect(mockGetUser).not.toHaveBeenCalled()
  })

  it('serves /register to authenticated users without an auth check', async () => {
    signIn('user-1', 'patient')
    const res = await updateSession(makeRequest('/register'))
    expect(res.status).toBe(200)
    expect(mockGetUser).not.toHaveBeenCalled()
  })

  it('serves /login to logged-out users', async () => {
    const res = await updateSession(makeRequest('/login'))
    expect(res.status).toBe(200)
    expect(mockGetUser).not.toHaveBeenCalled()
  })
})

describe('premon_role cookie caching', () => {
  it('sets an httpOnly 7-day cookie when missing', async () => {
    signIn('user-1', 'doctor')
    const res = await updateSession(makeRequest('/doctor/appointments', {}))
    expect(res.status).toBe(200)
    const cookie = (res as unknown as { cookies: { get(n: string): { value: string } | undefined } }).cookies.get(
      'premon_role'
    )
    expect(cookie?.value).toBe('doctor')
    const options = (
      res as unknown as { cookies: { getOptions(n: string): Record<string, unknown> | undefined } }
    ).cookies.getOptions('premon_role')
    expect(options).toMatchObject({
      path: '/',
      maxAge: 60 * 60 * 24 * 7,
      httpOnly: true,
      sameSite: 'lax',
    })
  })

  it('refreshes a stale cookie to the authoritative DB role', async () => {
    signIn('user-1', 'patient')
    const res = await updateSession(makeRequest('/patient/dashboard', { premon_role: 'admin' }))
    const cookie = (res as unknown as { cookies: { get(n: string): { value: string } | undefined } }).cookies.get(
      'premon_role'
    )
    expect(cookie?.value).toBe('patient')
  })

  it('does not re-set the cookie when it already matches', async () => {
    signIn('user-1', 'patient')
    const res = await updateSession(makeRequest('/patient/dashboard', { premon_role: 'patient' }))
    const cookie = (res as unknown as { cookies: { get(n: string): { value: string } | undefined } }).cookies.get(
      'premon_role'
    )
    expect(cookie).toBeUndefined()
  })

  it('redirects to /patient/dashboard when the profile row is missing', async () => {
    signIn('user-1', null)
    const res = await updateSession(makeRequest('/admin/dashboard'))
    expect(res.status).toBe(307)
    expect(locationOf(res)).toBe('http://localhost/patient/dashboard')
  })

  it('defaults to patient role and caches it when the profile row is missing', async () => {
    signIn('user-1', null)
    const res = await updateSession(makeRequest('/patient/dashboard'))
    expect(res.status).toBe(200)
    const cookie = (res as unknown as { cookies: { get(n: string): { value: string } | undefined } }).cookies.get(
      'premon_role'
    )
    expect(cookie?.value).toBe('patient')
  })
})
