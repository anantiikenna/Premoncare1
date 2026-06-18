'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase'
import { toast } from 'sonner'
import { Loader2, Radio, AlertCircle } from 'lucide-react'

interface OnlineToggleProps {
  initialStatus: boolean
  profileId: string
}

export function OnlineToggle({ initialStatus, profileId }: OnlineToggleProps) {
  const [isOnline, setIsOnline] = useState(initialStatus)
  const [loading, setLoading] = useState(false)
  const supabase = createClient()

  // 1. Handle toggle click
  const handleToggle = async () => {
    setLoading(true)
    const newStatus = !isOnline
    
    try {
      const { error } = await supabase
        .from('profiles')
        .update({ 
          is_online: newStatus,
          last_seen: new Date().toISOString()
        })
        .eq('id', profileId)

      if (error) throw error

      setIsOnline(newStatus)
      if (newStatus) {
        toast.success('You are now active. Standing by for emergency consultations.')
      } else {
        toast.info('Emergency Mode disabled. You are now offline.')
      }
    } catch (err: any) {
      toast.error(err.message || 'Failed to update presence status')
    } finally {
      setLoading(false)
    }
  }

  // 2. Automated Heartbeat System
  useEffect(() => {
    if (!isOnline) return

    // Immediately send first heartbeat ping to initialize
    const sendHeartbeat = async () => {
      await supabase
        .from('profiles')
        .update({ last_seen: new Date().toISOString() })
        .eq('id', profileId)
    }

    sendHeartbeat()

    // Setup periodic interval heartbeat (every 60 seconds)
    const interval = setInterval(async () => {
      try {
        const { error } = await supabase
          .from('profiles')
          .update({ last_seen: new Date().toISOString() })
          .eq('id', profileId)
        
        if (error) console.error('Heartbeat sync failed:', error)
      } catch (err) {
        console.error('Heartbeat sweep failed:', err)
      }
    }, 60000)

    return () => clearInterval(interval)
  }, [isOnline, profileId, supabase])

  return (
    <div className="flex items-center gap-4 bg-white/5 backdrop-blur-xl border border-white/10 px-5 py-2.5 rounded-2xl shadow-xl">
      <div className="flex flex-col items-start">
        <span className="text-[9px] font-black text-slate-400 uppercase tracking-widest leading-none mb-1">
          Emergency Status
        </span>
        <div className="flex items-center gap-2">
          {loading ? (
            <Loader2 className="h-3 w-3 animate-spin text-slate-300" />
          ) : (
            <span className={`h-2.5 w-2.5 rounded-full ${isOnline ? 'bg-emerald-500 animate-pulse' : 'bg-slate-400'}`} />
          )}
          <span className="text-xs font-black text-white uppercase tracking-wider">
            {isOnline ? 'Online' : 'Offline'}
          </span>
        </div>
      </div>

      <button
        onClick={handleToggle}
        disabled={loading}
        role="switch"
        aria-checked={isOnline}
        aria-label="Toggle clinical emergency availability"
        className={`
          relative inline-flex h-7 w-12 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:ring-offset-2
          ${isOnline ? 'bg-emerald-500' : 'bg-slate-700'}
        `}
      >
        <span
          className={`
            pointer-events-none inline-block h-6 w-6 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out
            ${isOnline ? 'translate-x-5' : 'translate-x-0'}
          `}
        />
      </button>
    </div>
  )
}
