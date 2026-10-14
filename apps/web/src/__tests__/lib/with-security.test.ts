const mockGetUser = jest.fn()
const mockSingle = jest.fn()
const mockEq = jest.fn(() => ({ single: mockSingle }))
const mockSelect = jest.fn(() => ({ eq: mockEq }))
const mockFrom = jest.fn(() => ({ select: mockSelect }))
const mockCreateClient = jest.fn()

jest.mock('@/lib/supabase-server', () => ({
  createClient: () => mockCreateClient(),
}))

import { NextRequest, NextResponse } from 'next/server'
import { withSecurity } from '@/lib/security'

const USER = { id: 'jwt-user-1', email: 'jwt@example.com' }
const ALLOWED_ORIGIN = 'http://localhost:3000'

let ipSeq = 0
function uniqueIp(): string {
  ipSeq += 1
  return `203.0.113.${(ipSeq % 250) + 1}`
}

function makeReq(init: RequestInit & { url?: string } = {}) {
  const { url, ...rest } = init
  return new NextRequest(
    url ?? 'http://localhost:3000/api/test',
    rest as unknown as ConstructorParameters<typeof NextRequest>[1]
  )
}

function reqWithIp(ip: string, init: RequestInit = {}) {
  const headers = new Headers(init.headers)
  headers.set('x-forwarded-for', ip)
  return makeReq({ ...init, headers })
}

const okHandler = jest.fn(async () => NextResponse.json({ ok: true }))

let consoleErrorSpy: jest.SpyInstance

beforeEach(() => {
  jest.clearAllMocks()
  consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
  mockCreateClient.mockResolvedValue({
    auth: { getUser: mockGetUser },
    from: mockFrom,
  })
  mockGetUser.mockResolvedValue({ data: { user: USER }, error: null })
  mockSingle.mockResolvedValue({ data: { role: 'doctor' }, error: null })
})

afterEach(() => {
  consoleErrorSpy.mockRestore()
})

describe('CORS & preflight', () => {
  it('answers OPTIONS preflight with 204 and allowed-origin CORS headers', async () => {
    const res = await withSecurity(
      makeReq({
        method: 'OPTIONS',
        headers: { origin: ALLOWED_ORIGIN },
      }),
      okHandler,
      { requireAuth: false }
    )

    expect(res.status).toBe(204)
    expect(res.headers.get('Access-Control-Allow-Origin')).toBe(ALLOWED_ORIGIN)
    expect(res.headers.get('Access-Control-Allow-Methods')).toContain('POST')
    expect(res.headers.get('Access-Control-Allow-Credentials')).toBe('true')
    expect(okHandler).not.toHaveBeenCalled()
  })

  it('returns 204 without ACAO for a disallowed origin', async () => {
    const res = await withSecurity(
      makeReq({
        method: 'OPTIONS',
        headers: { origin: 'https://evil.example' },
      }),
      okHandler,
      { requireAuth: false }
    )

    expect(res.status).toBe(204)
    expect(res.headers.get('Access-Control-Allow-Origin')).toBeNull()
    expect(okHandler).not.toHaveBeenCalled()
  })

  it('adds CORS headers to handler responses for allowed origins', async () => {
    const res = await withSecurity(
      reqWithIp(uniqueIp(), {
        headers: { origin: ALLOWED_ORIGIN },
      }),
      okHandler,
      { requireAuth: false }
    )

    expect(res.status).toBe(200)
    expect(res.headers.get('Access-Control-Allow-Origin')).toBe(ALLOWED_ORIGIN)
  })
})

describe('rate limiting', () => {
  it('allows 60 requests per minute then answers 429 without running the handler', async () => {
    const ip = '198.51.100.10'

    for (let i = 0; i < 60; i++) {
      const res = await withSecurity(reqWithIp(ip), okHandler, { requireAuth: false })
      expect(res.status).toBe(200)
    }

    const blocked = await withSecurity(reqWithIp(ip), okHandler, { requireAuth: false })
    expect(blocked.status).toBe(429)
    expect(await blocked.json()).toEqual({ error: 'Too Many Requests' })
    expect(okHandler).toHaveBeenCalledTimes(60)
  })

  it('keys on the RIGHTMOST x-forwarded-for entry (spoofed left entries ignored)', async () => {
    const trusted = '198.51.100.77'

    for (let i = 0; i < 60; i++) {
      const res = await withSecurity(
        makeReq({
          headers: { 'x-forwarded-for': `10.0.0.${i % 250}, ${trusted}` },
        }),
        okHandler,
        { requireAuth: false }
      )
      expect(res.status).toBe(200)
    }

    const blocked = await withSecurity(
      makeReq({
        headers: { 'x-forwarded-for': `10.0.0.99, ${trusted}` },
      }),
      okHandler,
      { requireAuth: false }
    )
    expect(blocked.status).toBe(429)

    const differentIp = await withSecurity(
      makeReq({
        headers: { 'x-forwarded-for': `10.0.0.0, 198.51.100.78` },
      }),
      okHandler,
      { requireAuth: false }
    )
    expect(differentIp.status).toBe(200)
  })

  it('never rate-limits webhooks', async () => {
    const ip = '198.51.100.200'
    for (let i = 0; i < 75; i++) {
      const res = await withSecurity(reqWithIp(ip), okHandler, {
        requireAuth: false,
        isWebhook: true,
      })
      expect(res.status).toBe(200)
    }
    expect(okHandler).toHaveBeenCalledTimes(75)
  })
})

describe('authentication', () => {
  it('answers 401 when there is no session and no Bearer token', async () => {
    mockGetUser.mockResolvedValue({ data: { user: null }, error: { message: 'no session' } })

    const res = await withSecurity(reqWithIp(uniqueIp()), okHandler)

    expect(res.status).toBe(401)
    expect(await res.json()).toEqual({ error: 'Unauthorized Access' })
    expect(okHandler).not.toHaveBeenCalled()
  })

  it('accepts Authorization: Bearer <access_token> for mobile clients', async () => {
    mockGetUser
      .mockResolvedValueOnce({ data: { user: null }, error: { message: 'no session' } })
      .mockResolvedValueOnce({ data: { user: USER }, error: null })

    let received: unknown
    const handler = jest.fn(async (_req: NextRequest, sessionUser?: unknown) => {
      received = sessionUser
      return NextResponse.json({ ok: true })
    })

    const res = await withSecurity(
      reqWithIp(uniqueIp(), {
        headers: { authorization: 'Bearer mobile-access-token' },
      }),
      handler
    )

    expect(res.status).toBe(200)
    expect(mockGetUser).toHaveBeenNthCalledWith(2, 'mobile-access-token')
    expect(received).toEqual(USER)
  })

  it('answers 401 when the Bearer token is also rejected', async () => {
    mockGetUser.mockResolvedValue({ data: { user: null }, error: { message: 'invalid' } })

    const res = await withSecurity(
      reqWithIp(uniqueIp(), {
        headers: { authorization: 'Bearer garbage-token' },
      }),
      okHandler
    )

    expect(res.status).toBe(401)
    expect(okHandler).not.toHaveBeenCalled()
  })

  it('skips authentication entirely when requireAuth is false', async () => {
    const res = await withSecurity(reqWithIp(uniqueIp()), okHandler, { requireAuth: false })

    expect(res.status).toBe(200)
    expect(mockCreateClient).not.toHaveBeenCalled()
    expect(okHandler).toHaveBeenCalledWith(expect.anything(), null)
  })
})

describe('role enforcement', () => {
  it('answers 403 when the profile role is not in requireRoles', async () => {
    mockSingle.mockResolvedValue({ data: { role: 'patient' }, error: null })

    const res = await withSecurity(
      reqWithIp(uniqueIp()),
      okHandler,
      { requireAuth: true, requireRoles: ['doctor', 'admin'] }
    )

    expect(res.status).toBe(403)
    expect(await res.json()).toEqual({ error: 'Forbidden' })
    expect(okHandler).not.toHaveBeenCalled()
  })

  it('answers 403 when the profile row is missing', async () => {
    mockSingle.mockResolvedValue({ data: null, error: { message: 'not found' } })

    const res = await withSecurity(
      reqWithIp(uniqueIp()),
      okHandler,
      { requireAuth: true, requireRoles: ['admin'] }
    )

    expect(res.status).toBe(403)
    expect(okHandler).not.toHaveBeenCalled()
  })

  it('runs the handler when the role matches', async () => {
    mockSingle.mockResolvedValue({ data: { role: 'admin' }, error: null })

    const res = await withSecurity(
      reqWithIp(uniqueIp()),
      okHandler,
      { requireAuth: true, requireRoles: ['admin'] }
    )

    expect(res.status).toBe(200)
    expect(mockFrom).toHaveBeenCalledWith('profiles')
    expect(okHandler).toHaveBeenCalledTimes(1)
  })
})

describe('JWT-sourced identity', () => {
  it('passes the authenticated user from the JWT to the handler — never from the request body', async () => {
    let received: { id?: string } | undefined
    const handler = jest.fn(async (_req: NextRequest, sessionUser?: { id?: string }) => {
      received = sessionUser
      return NextResponse.json({ ok: true })
    })

    const res = await withSecurity(
      reqWithIp(uniqueIp(), {
        method: 'POST',
        body: JSON.stringify({ userId: 'attacker-chosen-id', role: 'admin' }),
        headers: { 'content-type': 'application/json' },
      }),
      handler,
      { requireAuth: true }
    )

    expect(res.status).toBe(200)
    expect(received?.id).toBe('jwt-user-1')
    expect(received?.id).not.toBe('attacker-chosen-id')
  })
})

describe('handler errors', () => {
  it('answers 500 without leaking the internal error message or stack', async () => {
    const handler = jest.fn(async () => {
      throw new Error('DB password is hunter2')
    })

    const res = await withSecurity(reqWithIp(uniqueIp()), handler, {
      requireAuth: false,
    })

    expect(res.status).toBe(500)
    const body = await res.text()
    expect(JSON.parse(body)).toEqual({ error: 'Internal Server Error' })
    expect(body).not.toContain('hunter2')
    expect(body).not.toContain('at ')
    expect(consoleErrorSpy).toHaveBeenCalledWith('[API Error]:', expect.any(Error))
  })
})
