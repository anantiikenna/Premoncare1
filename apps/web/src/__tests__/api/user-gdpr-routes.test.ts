const mockGetUser = jest.fn()
const mockSingle = jest.fn()
const mockEq = jest.fn(() => ({ single: mockSingle }))
const mockSelect = jest.fn(() => ({ eq: mockEq }))
const mockFrom = jest.fn(() => ({ select: mockSelect }))
const mockRpc = jest.fn()
const mockCreateClient = jest.fn()

jest.mock('@/lib/supabase-server', () => ({
  createClient: () => mockCreateClient(),
}))

import { NextRequest } from 'next/server'
import { GET as exportGET } from '@/app/api/user/export/route'
import { POST as deletePOST } from '@/app/api/user/delete/route'

const USER = { id: 'jwt-user-1', email: 'gdpr@example.com' }

let ipSeq = 0
function uniqueIp(): string {
  ipSeq += 1
  return `198.51.100.${(ipSeq % 250) + 1}`
}

function makeReq(init: RequestInit & { url?: string } = {}) {
  const { url, ...rest } = init
  const headers = new Headers(init.headers)
  headers.set('x-forwarded-for', uniqueIp())
  return new NextRequest(
    url ?? 'http://localhost:3000/api/test',
    { ...rest, headers } as unknown as ConstructorParameters<typeof NextRequest>[1]
  )
}

function jsonReq(method: string, body?: unknown) {
  if (body === undefined) return makeReq({ method })
  return makeReq({
    method,
    body: JSON.stringify(body),
    headers: { 'content-type': 'application/json' },
  })
}

let consoleErrorSpy: jest.SpyInstance

beforeEach(() => {
  jest.clearAllMocks()
  consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
  mockCreateClient.mockResolvedValue({
    auth: { getUser: mockGetUser },
    from: mockFrom,
    rpc: mockRpc,
  })
  mockGetUser.mockResolvedValue({ data: { user: USER }, error: null })
  mockSingle.mockResolvedValue({ data: { role: 'patient' }, error: null })
})

afterEach(() => {
  consoleErrorSpy.mockRestore()
})

describe('GET /api/user/export (GDPR right to portability)', () => {
  it('exports the session user data as a JSON attachment via export_user_data', async () => {
    const payload = { profiles: [{ id: 'jwt-user-1' }], appointments: [] }
    mockRpc.mockResolvedValue({ data: payload, error: null })

    const res = await exportGET(makeReq({ method: 'GET' }))

    expect(res.status).toBe(200)
    expect(res.headers.get('Content-Type')).toBe('application/json')
    expect(res.headers.get('Content-Disposition')).toMatch(
      /^attachment; filename="premoncare-data-\d{4}-\d{2}-\d{2}\.json"$/
    )
    expect(await res.json()).toEqual(payload)
    expect(mockRpc).toHaveBeenCalledTimes(1)
    expect(mockRpc).toHaveBeenCalledWith('export_user_data', { p_user_id: 'jwt-user-1' })
  })

  it('answers 401 and never calls the RPC without a session', async () => {
    mockGetUser.mockResolvedValue({ data: { user: null }, error: { message: 'no session' } })

    const res = await exportGET(makeReq({ method: 'GET' }))

    expect(res.status).toBe(401)
    expect(await res.json()).toEqual({ error: 'Unauthorized Access' })
    expect(mockRpc).not.toHaveBeenCalled()
  })

  it('answers 500 with a generic message and no DB detail when the RPC fails', async () => {
    mockRpc.mockResolvedValue({
      data: null,
      error: { message: 'permission denied for table medical_records' },
    })

    const res = await exportGET(makeReq({ method: 'GET' }))

    expect(res.status).toBe(500)
    const body = await res.text()
    expect(JSON.parse(body)).toEqual({ error: 'Failed to export data' })
    expect(body).not.toContain('permission denied')
    expect(body).not.toContain('medical_records')
  })

  it('passes the RPC-level export limit through as 429', async () => {
    mockRpc.mockResolvedValue({
      data: { error: 'Export limit reached. Try again tomorrow.' },
      error: null,
    })

    const res = await exportGET(makeReq({ method: 'GET' }))

    expect(res.status).toBe(429)
    expect(await res.json()).toEqual({ error: 'Export limit reached. Try again tomorrow.' })
  })
})

describe('POST /api/user/delete (GDPR right to erasure)', () => {
  it('soft-deletes the session user and confirms the 30-day recovery window', async () => {
    mockRpc.mockResolvedValue({ data: { success: true }, error: null })

    const res = await deletePOST(jsonReq('POST', { reason: 'moved abroad' }))

    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body.success).toBe(true)
    expect(body.message).toContain('30 days')
    expect(mockRpc).toHaveBeenCalledWith('soft_delete_user', {
      p_user_id: 'jwt-user-1',
      p_reason: 'moved abroad',
    })
  })

  it('ignores identities supplied in the body — p_user_id always comes from the JWT (no IDOR)', async () => {
    mockRpc.mockResolvedValue({ data: { success: true }, error: null })

    const res = await deletePOST(
      jsonReq('POST', {
        user_id: 'victim-999',
        id: 'victim-999',
        patient_id: 'victim-999',
        reason: 'attack',
      })
    )

    expect(res.status).toBe(200)
    expect(mockRpc).toHaveBeenCalledTimes(1)
    expect(mockRpc).toHaveBeenCalledWith('soft_delete_user', {
      p_user_id: 'jwt-user-1',
      p_reason: 'attack',
    })
  })

  it('defaults p_reason to null when the request has no body', async () => {
    mockRpc.mockResolvedValue({ data: { success: true }, error: null })

    const res = await deletePOST(jsonReq('POST'))

    expect(res.status).toBe(200)
    expect(mockRpc).toHaveBeenCalledWith('soft_delete_user', {
      p_user_id: 'jwt-user-1',
      p_reason: null,
    })
  })

  it('answers 401 and never calls the RPC without a session', async () => {
    mockGetUser.mockResolvedValue({ data: { user: null }, error: { message: 'no session' } })

    const res = await deletePOST(jsonReq('POST', { reason: 'x' }))

    expect(res.status).toBe(401)
    expect(mockRpc).not.toHaveBeenCalled()
  })

  it('answers 500 with a generic message and no DB detail when the RPC fails', async () => {
    mockRpc.mockResolvedValue({
      data: null,
      error: { message: 'update on table profiles violates row-level security' },
    })

    const res = await deletePOST(jsonReq('POST', { reason: 'x' }))

    expect(res.status).toBe(500)
    const body = await res.text()
    expect(JSON.parse(body)).toEqual({ error: 'Failed to process deletion request' })
    expect(body).not.toContain('row-level security')
    expect(body).not.toContain('profiles')
  })

  it('passes an RPC-level refusal through as 403', async () => {
    mockRpc.mockResolvedValue({
      data: { error: 'Deletion blocked: active consultation in progress.' },
      error: null,
    })

    const res = await deletePOST(jsonReq('POST', { reason: 'x' }))

    expect(res.status).toBe(403)
    expect(await res.json()).toEqual({
      error: 'Deletion blocked: active consultation in progress.',
    })
  })
})
