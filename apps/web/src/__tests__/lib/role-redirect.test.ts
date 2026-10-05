import { createClient } from '@/lib/supabase-server'

jest.mock('next/navigation', () => ({
  redirect: jest.fn((url: string) => {
    throw new Error(`NEXT_REDIRECT:${url}`)
  }),
}))

import { redirect } from 'next/navigation'
import { redirectToRolePath } from '@/lib/role-redirect'

const mockGetUser = jest.fn()
const mockSingle = jest.fn()
const mockEq = jest.fn((_column: string, _value: string) => ({ single: mockSingle }))
const mockSelect = jest.fn((_columns: string) => ({ eq: mockEq }))
const mockFrom = jest.fn((_table: string) => ({ select: mockSelect }))

beforeEach(() => {
  jest.clearAllMocks()
  jest.mocked(createClient).mockResolvedValue({
    auth: { getUser: mockGetUser },
    from: mockFrom,
  } as unknown as Awaited<ReturnType<typeof createClient>>)
})

describe('redirectToRolePath', () => {
  it('redirects unauthenticated users to /login', async () => {
    mockGetUser.mockResolvedValue({ data: { user: null } })

    await expect(redirectToRolePath('/dashboard')).rejects.toThrow('NEXT_REDIRECT:/login')
    expect(jest.mocked(redirect)).toHaveBeenCalledWith('/login')
    expect(mockFrom).not.toHaveBeenCalled()
  })

  it.each([
    ['admin', '/dashboard', '/admin/dashboard'],
    ['doctor', '/dashboard', '/doctor/dashboard'],
    ['patient', '/dashboard', '/patient/dashboard'],
    ['doctor', '/appointments', '/doctor/appointments'],
    ['patient', '/records', '/patient/records'],
  ])('role=%s path=%s redirects to %s', async (role, path, expected) => {
    mockGetUser.mockResolvedValue({ data: { user: { id: 'user-1' } } })
    mockSingle.mockResolvedValue({ data: { role } })

    await expect(redirectToRolePath(path)).rejects.toThrow(`NEXT_REDIRECT:${expected}`)
    expect(mockFrom).toHaveBeenCalledWith('profiles')
    expect(mockEq).toHaveBeenCalledWith('id', 'user-1')
    expect(jest.mocked(redirect)).toHaveBeenCalledWith(expected)
  })

  it.each(['nurse', 'superuser', ''])(
    'falls back to patient for unrecognized role "%s"',
    async (role) => {
      mockGetUser.mockResolvedValue({ data: { user: { id: 'user-1' } } })
      mockSingle.mockResolvedValue({ data: { role } })

      await expect(redirectToRolePath('/dashboard')).rejects.toThrow('NEXT_REDIRECT:/patient/dashboard')
    }
  )

  it('falls back to patient when the profile row is missing', async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: 'user-1' } } })
    mockSingle.mockResolvedValue({ data: null })

    await expect(redirectToRolePath('/dashboard')).rejects.toThrow('NEXT_REDIRECT:/patient/dashboard')
  })
})
