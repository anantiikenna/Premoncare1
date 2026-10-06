const mockInsert = jest.fn()
const mockFrom = jest.fn(() => ({ insert: mockInsert }))

const mockSupabase = { from: mockFrom }

jest.mock('@/lib/supabase', () => ({
  createClient: jest.fn(() => mockSupabase),
}))

import { logAuditEvent, logPHIAccess } from '@/lib/audit'

let consoleErrorSpy: jest.SpyInstance

beforeEach(() => {
  jest.clearAllMocks()
  consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
  mockInsert.mockResolvedValue({ error: null })
})

afterEach(() => {
  consoleErrorSpy.mockRestore()
})

function lastInsertedPayload() {
  return mockInsert.mock.calls[mockInsert.mock.calls.length - 1][0] as Record<string, unknown>
}

describe('logAuditEvent', () => {
  it('maps actor_id to user_id and inserts action + details', async () => {
    await logAuditEvent({ actor_id: 'u-1', action: 'record_view' })

    expect(mockFrom).toHaveBeenCalledWith('audit_logs')
    expect(lastInsertedPayload()).toEqual({
      user_id: 'u-1',
      action: 'record_view',
      details: {},
    })
  })

  it('nests target_user_id, resource_type and resource_id inside details', async () => {
    await logAuditEvent({
      actor_id: 'doctor-1',
      action: 'phi_access',
      target_user_id: 'patient-9',
      resource_type: 'medical_record',
      resource_id: 'file-3',
      details: { reason: 'consultation' },
    })

    expect(lastInsertedPayload()).toEqual({
      user_id: 'doctor-1',
      action: 'phi_access',
      details: {
        reason: 'consultation',
        target_user_id: 'patient-9',
        resource_type: 'medical_record',
        resource_id: 'file-3',
      },
    })
  })

  it('inserts ONLY user_id, action and details (no PHI fields)', async () => {
    await logAuditEvent({
      actor_id: 'u-1',
      action: 'phi_access',
      target_user_id: 'u-2',
      resource_type: 'medical_record',
      resource_id: 'f-1',
      details: { diagnosis: 'must-not-leak' },
    })

    const payload = lastInsertedPayload()
    expect(Object.keys(payload).sort()).toEqual(['action', 'details', 'user_id'])
    expect(payload).not.toHaveProperty('email')
    expect(payload).not.toHaveProperty('name')
    expect(payload).not.toHaveProperty('patient_name')
    expect(payload).not.toHaveProperty('symptoms')
    expect(payload).not.toHaveProperty('actor_email')
  })

  it('omits target/resource keys from details when they are not provided', async () => {
    await logAuditEvent({ actor_id: 'u-1', action: 'account_export' })

    expect(lastInsertedPayload().details).not.toHaveProperty('target_user_id')
    expect(lastInsertedPayload().details).not.toHaveProperty('resource_type')
    expect(lastInsertedPayload().details).not.toHaveProperty('resource_id')
  })

  it('logs the insert error and never throws when Supabase returns an error', async () => {
    mockInsert.mockResolvedValue({ error: { message: 'permission denied' } })

    await expect(
      logAuditEvent({ actor_id: 'u-1', action: 'record_delete' })
    ).resolves.toBeUndefined()

    expect(consoleErrorSpy).toHaveBeenCalledWith(
      'Audit log failed:',
      'permission denied'
    )
  })

  it('never throws when the insert itself throws', async () => {
    mockInsert.mockRejectedValue(new Error('network down'))

    await expect(
      logAuditEvent({ actor_id: 'u-1', action: 'record_delete' })
    ).resolves.toBeUndefined()

    expect(consoleErrorSpy).toHaveBeenCalledWith(
      'Audit log failed:',
      expect.any(Error)
    )
  })
})

describe('logPHIAccess', () => {
  it('writes a phi_access audit row with target and resource nested in details', async () => {
    await logPHIAccess('doctor-1', 'patient-2', 'medical_record')

    expect(lastInsertedPayload()).toEqual({
      user_id: 'doctor-1',
      action: 'phi_access',
      details: {
        target_user_id: 'patient-2',
        resource_type: 'medical_record',
      },
    })
  })
})
