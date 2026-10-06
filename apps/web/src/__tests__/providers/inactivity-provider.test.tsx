import { ReactNode } from 'react'

const mockPush = jest.fn()
const mockUnsubscribe = jest.fn()
const mockSignOut = jest.fn()
const mockGetSession = jest.fn()

type AuthCallback = (event: string, session: typeof SESSION | null) => void

const mockSupabase = {
  auth: {
    getSession: mockGetSession,
    onAuthStateChange: jest.fn((_cb: AuthCallback) => ({
      data: { subscription: { unsubscribe: mockUnsubscribe } },
    })),
    signOut: mockSignOut,
  },
}

jest.mock('@/lib/supabase', () => ({
  createClient: jest.fn(() => mockSupabase),
}))

jest.mock('next/navigation', () => ({
  useRouter: jest.fn(() => ({ push: mockPush })),
}))

import { render, screen, act, fireEvent } from '@testing-library/react'
import { InactivityProvider } from '@/components/providers/inactivity-provider'

const MINUTE = 60 * 1000

async function advance(ms: number) {
  await act(async () => {
    jest.advanceTimersByTime(ms)
  })
}

const SESSION = { access_token: 'tok', user: { id: 'u1' } }

async function renderWithSession(session: typeof SESSION | null = SESSION) {
  mockGetSession.mockResolvedValue({ data: { session } })
  const utils = render(
    <InactivityProvider>
      <div data-testid="child">child</div>
    </InactivityProvider>
  )
  await act(async () => {})
  return utils
}

beforeEach(() => {
  jest.useFakeTimers()
  jest.clearAllMocks()
  mockSignOut.mockResolvedValue(undefined)
})

afterEach(() => {
  jest.useRealTimers()
})

describe('InactivityProvider (HIPAA 15-minute auto-logout)', () => {
  it('renders children without a warning initially', async () => {
    await renderWithSession()
    expect(screen.getByTestId('child')).toBeInTheDocument()
    expect(screen.queryByText('Session Expiring Soon')).not.toBeInTheDocument()
  })

  it('shows the warning at exactly 14 minutes of inactivity', async () => {
    await renderWithSession()
    await advance(14 * MINUTE - 1000)
    expect(screen.queryByText('Session Expiring Soon')).not.toBeInTheDocument()
    await advance(1000)
    expect(screen.getByText('Session Expiring Soon')).toBeInTheDocument()
    expect(
      screen.getByText(/logged out in 1 minute due to inactivity/i)
    ).toBeInTheDocument()
  })

  it('signs out and redirects to /login?reason=inactivity after 15 minutes', async () => {
    await renderWithSession()
    await advance(15 * MINUTE)
    expect(mockSignOut).toHaveBeenCalledTimes(1)
    expect(mockPush).toHaveBeenCalledWith('/login?reason=inactivity')
  })

  it('KEEPS the warning visible while the 15th minute counts down', async () => {
    await renderWithSession()
    await advance(14 * MINUTE)
    expect(screen.getByText('Session Expiring Soon')).toBeInTheDocument()
    await advance(30 * 1000)
    expect(screen.getByText('Session Expiring Soon')).toBeInTheDocument()
    expect(mockSignOut).not.toHaveBeenCalled()
    await advance(30 * 1000)
    expect(mockSignOut).toHaveBeenCalledTimes(1)
  })

  it('activity before the warning resets the 15-minute window', async () => {
    await renderWithSession()
    await advance(10 * MINUTE)
    act(() => {
      window.dispatchEvent(new Event('mousemove'))
    })
    await advance(5 * MINUTE)
    expect(mockSignOut).not.toHaveBeenCalled()
    expect(screen.queryByText('Session Expiring Soon')).not.toBeInTheDocument()
    await advance(14 * MINUTE)
    expect(screen.getByText('Session Expiring Soon')).toBeInTheDocument()
    await advance(MINUTE)
    expect(mockSignOut).toHaveBeenCalledTimes(1)
  })

  it('does NOT reset the logout timer once the warning is showing', async () => {
    await renderWithSession()
    await advance(14 * MINUTE)
    expect(screen.getByText('Session Expiring Soon')).toBeInTheDocument()
    act(() => {
      window.dispatchEvent(new Event('mousemove'))
      window.dispatchEvent(new Event('keydown'))
    })
    expect(screen.getByText('Session Expiring Soon')).toBeInTheDocument()
    await advance(MINUTE)
    expect(mockSignOut).toHaveBeenCalledTimes(1)
    expect(mockPush).toHaveBeenCalledWith('/login?reason=inactivity')
  })

  it('"Stay Logged In" hides the warning and restarts the full window', async () => {
    await renderWithSession()
    await advance(14 * MINUTE)
    const button = screen.getByRole('button', { name: /stay logged in/i })
    act(() => {
      fireEvent.click(button)
    })
    expect(screen.queryByText('Session Expiring Soon')).not.toBeInTheDocument()
    await advance(MINUTE)
    expect(mockSignOut).not.toHaveBeenCalled()
    await advance(14 * MINUTE)
    expect(screen.getByText('Session Expiring Soon')).toBeInTheDocument()
    await advance(MINUTE)
    expect(mockSignOut).toHaveBeenCalledTimes(1)
  })

  it('never arms timers without a session', async () => {
    await renderWithSession(null)
    await advance(16 * MINUTE)
    expect(screen.queryByText('Session Expiring Soon')).not.toBeInTheDocument()
    expect(mockSignOut).not.toHaveBeenCalled()
    expect(mockPush).not.toHaveBeenCalled()
  })

  it('clears timers and unsubscribes on unmount', async () => {
    const { unmount } = await renderWithSession()
    unmount()
    expect(mockUnsubscribe).toHaveBeenCalledTimes(1)
    await advance(16 * MINUTE)
    expect(mockSignOut).not.toHaveBeenCalled()
  })

  it('signs out when the session disappears (auth state change)', async () => {
    mockGetSession.mockResolvedValue({ data: { session: SESSION } })
    let authCallback: AuthCallback | undefined
    mockSupabase.auth.onAuthStateChange.mockImplementation((cb: AuthCallback) => {
      authCallback = cb
      return { data: { subscription: { unsubscribe: mockUnsubscribe } } }
    })
    render(
      <InactivityProvider>
        <div data-testid="child">child</div>
      </InactivityProvider>
    )
    await act(async () => {})
    await advance(10 * MINUTE)
    act(() => {
      authCallback?.('SIGNED_OUT', null)
    })
    await advance(16 * MINUTE)
    expect(mockSignOut).not.toHaveBeenCalled()
    expect(screen.queryByText('Session Expiring Soon')).not.toBeInTheDocument()
  })
})
