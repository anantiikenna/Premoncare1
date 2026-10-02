import { render, screen, waitFor, act, cleanup } from '@testing-library/react'
import { MeetingRoom } from '@/components/appointments/meeting-room'

type ListenerMap = Record<string, (...args: unknown[]) => void>

let mockUpdateCalls: Array<{
  table: string
  payload: Record<string, unknown>
  column: string
  value: unknown
}> = []
let mockCtorArgs: { domain: string; options: Record<string, any> } | null = null
let mockListeners: ListenerMap = {}

class MockJitsiApi {
  constructor(domain: string, options: Record<string, any>) {
    mockCtorArgs = { domain, options }
  }
  addEventListeners(listeners: ListenerMap) {
    mockListeners = listeners
  }
  dispose() {}
}

jest.mock('@/lib/supabase', () => ({
  createClient: () => ({
    from: (table: string) => ({
      update: (payload: Record<string, unknown>) => ({
        eq: async (column: string, value: unknown) => {
          mockUpdateCalls.push({ table, payload, column, value })
        },
      }),
    }),
  }),
}))

describe('MeetingRoom', () => {
  const APT_ID = '11111111-2222-3333-4444-555555555555'

  beforeEach(() => {
    mockUpdateCalls = []
    mockCtorArgs = null
    mockListeners = {}
    ;(window as any).JitsiMeetExternalAPI = MockJitsiApi
  })

  afterEach(() => {
    delete (window as any).JitsiMeetExternalAPI
    cleanup()
  })

  it('joins the exact room the mobile app uses: PremonCare-{appointmentId} on 8x8.vc', () => {
    render(
      <MeetingRoom
        roomName={APT_ID}
        userName="Dr. Test"
        appointmentId={APT_ID}
        onClose={jest.fn()}
      />
    )

    expect(mockCtorArgs).not.toBeNull()
    expect(mockCtorArgs!.domain).toBe('8x8.vc')
    expect(mockCtorArgs!.options.roomName).toBe(`PremonCare-${APT_ID}`)
    expect(mockCtorArgs!.options.userInfo.displayName).toBe('Dr. Test')
    expect(mockCtorArgs!.options.configOverwrite.disableDeepLinking).toBe(true)
    expect(mockCtorArgs!.options.configOverwrite.enableEmailInStats).toBe(false)
  })

  it('marks ongoing on conferenceJoined, completed on leave, then closes exactly once', async () => {
    const onClose = jest.fn()
    render(
      <MeetingRoom
        roomName={APT_ID}
        userName="Patient Test"
        appointmentId={APT_ID}
        onClose={onClose}
      />
    )

    expect(mockCtorArgs).not.toBeNull()
    expect(screen.queryByText(/initializing secure room/i)).toBeNull()

    act(() => {
      mockListeners.conferenceJoined()
    })
    await waitFor(() =>
      expect(mockUpdateCalls).toEqual([
        {
          table: 'appointments',
          payload: { status: 'ongoing' },
          column: 'id',
          value: APT_ID,
        },
      ])
    )

    act(() => {
      mockListeners.videoConferenceLeft()
    })
    await waitFor(() => expect(onClose).toHaveBeenCalledTimes(1))
    expect(mockUpdateCalls).toHaveLength(2)
    expect(mockUpdateCalls[1].payload).toEqual({ status: 'completed' })

    act(() => {
      mockListeners.readyToClose()
    })
    expect(mockUpdateCalls).toHaveLength(2)
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('loads external_api.js from 8x8.vc when the SDK is not yet present and removes it on unmount', () => {
    delete (window as any).JitsiMeetExternalAPI

    const { unmount } = render(
      <MeetingRoom
        roomName={APT_ID}
        userName="Dr. Test"
        appointmentId={APT_ID}
        onClose={jest.fn()}
      />
    )

    const script = document.querySelector('script[src*="8x8.vc"]')
    expect(script).not.toBeNull()
    expect(script!.getAttribute('src')).toBe(
      'https://8x8.vc/vpaas-magic-cookie-8ae09756b1f44059929e7161b9bd1031/external_api.js'
    )

    unmount()
    expect(document.querySelector('script[src*="8x8.vc"]')).toBeNull()
  })
})
