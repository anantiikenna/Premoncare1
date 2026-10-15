import { render, screen, act, cleanup, waitFor } from '@testing-library/react'
import EmergencyWaitingPage from '@/app/emergency-waiting/page'

type UpdateCall = {
  table: string
  payload: Record<string, unknown>
  column: string
  value: unknown
}

let mockUpdateCalls: UpdateCall[] = []
let mockPostgresCallback: ((payload: { new?: { status?: string } }) => void) | null = null
let mockRemoveChannelCalls: unknown[] = []
const mockPush = jest.fn()

jest.mock('next/navigation', () => ({
  useRouter: () => ({ push: (path: string) => mockPush(path) }),
}))

jest.mock('@/lib/supabase', () => ({
  createClient: () => ({
    channel: () => {
      const ch = {
        on: (_type: string, _config: unknown, cb: (payload: { new?: { status?: string } }) => void) => {
          mockPostgresCallback = cb
          return ch
        },
        subscribe: () => ch,
      }
      return ch
    },
    removeChannel: (ch: unknown) => {
      mockRemoveChannelCalls.push(ch)
    },
    from: (table: string) => ({
      update: (payload: Record<string, unknown>) => ({
        eq: async (column: string, value: unknown) => {
          mockUpdateCalls.push({ table, payload, column, value })
        },
      }),
    }),
  }),
}))

const APT_ID = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'

function seedLocalStorage() {
  localStorage.setItem('premon_emergency_appointment_id', APT_ID)
  localStorage.setItem('premon_emergency_doctor_name', 'Dr. Alpha')
  localStorage.setItem('premon_emergency_doctor_id', 'doc-123')
  localStorage.setItem('premon_emergency_amount', '1500')
  localStorage.setItem('premon_emergency_duration', '30')
}

describe('EmergencyWaitingPage (3-minute doctor handshake)', () => {
  beforeEach(() => {
    jest.useFakeTimers()
    mockUpdateCalls = []
    mockPostgresCallback = null
    mockRemoveChannelCalls = []
    mockPush.mockClear()
    localStorage.clear()
  })

  afterEach(() => {
    jest.useRealTimers()
    cleanup()
  })

  it('redirects to /emergency when no appointment id is present', () => {
    render(<EmergencyWaitingPage />)

    expect(mockPush).toHaveBeenCalledWith('/emergency')
    expect(localStorage.getItem('premon_emergency_appointment_id')).toBeNull()
  })

  it('shows the 03:00 countdown and doctor card while waiting', () => {
    seedLocalStorage()
    render(<EmergencyWaitingPage />)

    expect(screen.getByText('03:00')).toBeInTheDocument()
    expect(screen.getByText('Connecting You...')).toBeInTheDocument()
    expect(screen.getAllByText('Dr. Alpha').length).toBeGreaterThan(0)
    expect(screen.getByText('Cancel Request')).toBeInTheDocument()
  })

  it('on realtime emergency_accepted shows acceptance, stores the flag, and redirects to payment after 2s', () => {
    seedLocalStorage()
    render(<EmergencyWaitingPage />)

    expect(mockPostgresCallback).not.toBeNull()

    act(() => {
      mockPostgresCallback!({ new: { status: 'emergency_accepted' } })
    })

    expect(screen.getByText('Doctor Accepted!')).toBeInTheDocument()
    expect(screen.queryByText('03:00')).toBeNull()

    act(() => {
      jest.advanceTimersByTime(2000)
    })

    expect(localStorage.getItem('premon_emergency_accepted')).toBe('true')
    expect(mockPush).toHaveBeenCalledWith('/account-conversion')
  })

  it('on realtime emergency_declined shows the unavailable state and offers to find another doctor', () => {
    seedLocalStorage()
    render(<EmergencyWaitingPage />)

    act(() => {
      mockPostgresCallback!({ new: { status: 'emergency_declined' } })
    })

    expect(screen.getByText('Doctor Unavailable')).toBeInTheDocument()
    expect(screen.getByText('Find Another Doctor')).toBeInTheDocument()
    expect(mockPush).not.toHaveBeenCalled()
  })

  it('auto-declines in the database when the 3-minute window expires', async () => {
    seedLocalStorage()
    render(<EmergencyWaitingPage />)

    expect(screen.getByText('03:00')).toBeInTheDocument()

    await act(async () => {
      jest.advanceTimersByTime(180_000)
    })

    expect(mockUpdateCalls).toEqual([
      {
        table: 'appointments',
        payload: { status: 'emergency_declined' },
        column: 'id',
        value: APT_ID,
      },
    ])
    expect(screen.getByText('Request Expired')).toBeInTheDocument()
    expect(screen.getByText('Find Another Doctor')).toBeInTheDocument()
  })

  it('cancel writes emergency_declined and returns to the doctor list', async () => {
    seedLocalStorage()
    render(<EmergencyWaitingPage />)

    await act(async () => {
      screen.getByText('Cancel Request').click()
    })

    expect(mockUpdateCalls).toEqual([
      {
        table: 'appointments',
        payload: { status: 'emergency_declined' },
        column: 'id',
        value: APT_ID,
      },
    ])
    expect(mockPush).toHaveBeenCalledWith('/doctors')
  })

  it('Find Another Doctor clears the handshake keys and navigates away', async () => {
    seedLocalStorage()
    render(<EmergencyWaitingPage />)

    act(() => {
      mockPostgresCallback!({ new: { status: 'emergency_declined' } })
    })

    await act(async () => {
      screen.getByText('Find Another Doctor').click()
    })

    expect(localStorage.getItem('premon_emergency_appointment_id')).toBeNull()
    expect(localStorage.getItem('premon_emergency_doctor_name')).toBeNull()
    expect(localStorage.getItem('premon_emergency_doctor_id')).toBeNull()
    expect(localStorage.getItem('premon_emergency_amount')).toBeNull()
    expect(localStorage.getItem('premon_emergency_duration')).toBeNull()
    expect(mockPush).toHaveBeenCalledWith('/doctors')
  })

  it('unsubscribes from the realtime channel on unmount', async () => {
    seedLocalStorage()
    const { unmount } = render(<EmergencyWaitingPage />)

    unmount()

    await waitFor(() => expect(mockRemoveChannelCalls.length).toBeGreaterThan(0))
  })
})
