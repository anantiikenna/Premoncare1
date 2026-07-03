'use client'

import { useEffect, useRef, useState, useCallback } from 'react'
import { Loader2 } from 'lucide-react'
import { createClient } from '@/lib/supabase'

declare global {
  interface Window {
    JitsiMeetExternalAPI: any
  }
}

interface MeetingRoomProps {
  roomName: string
  userName: string
  appointmentId?: string
  onClose: () => void
}

export function MeetingRoom({ roomName, userName, appointmentId, onClose }: MeetingRoomProps) {
  const jitsiContainerRef = useRef<HTMLDivElement>(null)
  const apiRef = useRef<any>(null)
  const [loading, setLoading] = useState(true)
  const [isMuted, setIsMuted] = useState(false)
  const [isVideoOff, setIsVideoOff] = useState(false)

  const updateAppointmentStatus = useCallback(async (status: string) => {
    if (!appointmentId) return
    try {
      const supabase = createClient()
      await supabase
        .from('appointments')
        .update({ status })
        .eq('id', appointmentId)
    } catch (e) {
      console.error('Failed to update appointment status:', e)
    }
  }, [appointmentId])

  useEffect(() => {
    const script = document.createElement('script')
    script.src = 'https://8x8.vc/vpaas-magic-cookie-8ae09756b1f44059929e7161b9bd1031/external_api.js'
    script.async = true
    script.onload = () => {
      if (jitsiContainerRef.current) {
        const options = {
          roomName: `PremonCare-${roomName}`,
          width: '100%',
          height: '100%',
          parentNode: jitsiContainerRef.current,
          userInfo: {
            displayName: userName
          },
          configOverwrite: {
            startWithAudioMuted: false,
            startWithVideoMuted: false,
            disableModeratorIndicator: true,
            startScreenSharing: false,
            enableEmailInStats: false
          },
          interfaceConfigOverwrite: {
            TOOLBAR_BUTTONS: [
                'microphone', 'camera', 'closedcaptions', 'desktop', 'fullscreen',
                'fodeviceselection', 'hangup', 'profile', 'chat', 'recording',
                'livestreaming', 'etherpad', 'sharedvideo', 'settings', 'raisehand',
                'videoquality', 'filmstrip', 'invite', 'feedback', 'stats', 'shortcuts',
                'tileview', 'videobackgroundblur', 'download', 'help', 'mute-everyone',
                'security'
            ],
            SETTINGS_SECTIONS: [ 'devices', 'language', 'profile', 'calendar' ],
            SHOW_CHROME_EXTENSION_BANNER: false
          }
        }
        const jitsiApi = new window.JitsiMeetExternalAPI('8x8.vc', options)
        apiRef.current = jitsiApi
        setLoading(false)

        jitsiApi.addEventListeners({
          readyToClose: () => {
            updateAppointmentStatus('completed')
            onClose()
          },
          videoConferenceLeft: () => {
            updateAppointmentStatus('completed')
            onClose()
          },
          audioMuteStatusChanged: (e: any) => setIsMuted(e.muted),
          videoMuteStatusChanged: (e: any) => setIsVideoOff(e.muted)
        })

        updateAppointmentStatus('ongoing')
      }
    }
    document.body.appendChild(script)

    return () => {
      if (apiRef.current) {
        apiRef.current.dispose()
        apiRef.current = null
      }
      if (script.parentNode) {
        script.parentNode.removeChild(script)
      }
    }
  }, [roomName, userName, onClose, updateAppointmentStatus])

  return (
    <div className="relative w-full h-full bg-zinc-950 flex flex-col">
      {loading && (
        <div className="absolute inset-0 flex flex-col items-center justify-center z-10 bg-zinc-950 text-white gap-4">
          <Loader2 className="h-12 w-12 animate-spin text-primary" />
          <p className="text-zinc-400 font-medium">Initializing encrypted room...</p>
        </div>
      )}
      
      <div ref={jitsiContainerRef} className="flex-1 w-full h-full" />

      {/* Custom Overlay Controls (Optional, as Jitsi has its own) */}
      {!loading && (
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2 flex items-center gap-4 px-6 py-3 bg-zinc-900/80 backdrop-blur-md rounded-full border border-zinc-800 shadow-2xl z-20 pointer-events-none opacity-0 hover:opacity-100 transition-opacity">
            {/* These would be mirror controls if we wanted to sync them, but Jitsi's UI is usually sufficient */}
            <span className="text-[10px] text-zinc-500 font-mono">SECURE CONNECTION</span>
        </div>
      )}
    </div>
  )
}
