'use client'

import { useState, useEffect, useCallback, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { toast } from 'sonner'
import { ShieldAlert, CheckCircle2, XCircle, Loader2, Clock, User } from 'lucide-react'

interface EmergencyRequest {
  id: string
  patient_id: string | null
  duration_minutes: number
  total_amount: number
  created_at: string
  status?: string
  metadata?: Record<string, unknown>
}

export function EmergencyRequestAlert({ doctorId }: { doctorId: string }) {
  const router = useRouter()
  const supabase = createClient()
  const [requests, setRequests] = useState<EmergencyRequest[]>([])
  const [processingId, setProcessingId] = useState<string | null>(null)
  const [secondsByRequest, setSecondsByRequest] = useState<Record<string, number>>({})
  const timersRef = useRef<Record<string, ReturnType<typeof setInterval>>>({})
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null)

  // Fetch initial emergency requests
  const fetchRequests = useCallback(async () => {
    try {
      const { data } = await supabase
        .from('appointments')
        .select('id, patient_id, duration_minutes, total_amount, created_at, metadata')
        .eq('doctor_id', doctorId)
        .eq('status', 'emergency_request')
        .order('created_at', { ascending: false })

      if (data) setRequests(data)
    } catch (err) {
      console.error('Failed to fetch emergency requests:', err)
    }
  }, [supabase, doctorId])

  useEffect(() => {
    fetchRequests()
  }, [fetchRequests])

  // Start countdown timers for each request
  useEffect(() => {
    requests.forEach((req) => {
      if (secondsByRequest[req.id] !== undefined) return

      const createdAt = new Date(req.created_at).getTime()
      const elapsed = Math.floor((Date.now() - createdAt) / 1000)
      const remaining = Math.max(0, 180 - elapsed)

      setSecondsByRequest((prev) => ({ ...prev, [req.id]: remaining }))

      if (remaining > 0) {
        timersRef.current[req.id] = setInterval(() => {
          setSecondsByRequest((prev) => {
            const current = prev[req.id] ?? 0
            if (current <= 1) {
              clearInterval(timersRef.current[req.id])
              // Auto-decline on timeout
              respondToRequest(req.id, req.patient_id, false)
              return { ...prev, [req.id]: 0 }
            }
            return { ...prev, [req.id]: current - 1 }
          })
        }, 1000)
      }
    })

    return () => {
      Object.values(timersRef.current).forEach(clearInterval)
    }
  }, [requests])

  // Real-time subscription
  useEffect(() => {
    const channel = supabase
      .channel(`doctor:emergency:${doctorId}`, {
        config: { private: true },
      })
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'appointments',
          filter: `doctor_id=eq.${doctorId}`,
        },
        (payload) => {
          const record = payload.new as EmergencyRequest
          if (record && record.status === 'emergency_request') {
            setRequests((prev) => [record, ...prev])
            toast.error('EMERGENCY REQUEST', {
              description: 'A patient needs immediate consultation!',
              duration: 30000,
            })
          }
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'DELETE',
          schema: 'public',
          table: 'appointments',
          filter: `doctor_id=eq.${doctorId}`,
        },
        (payload) => {
          const oldRecord = payload.old as EmergencyRequest
          if (oldRecord) {
            setRequests((prev) => prev.filter((r) => r.id !== oldRecord.id))
            if (timersRef.current[oldRecord.id]) {
              clearInterval(timersRef.current[oldRecord.id])
              delete timersRef.current[oldRecord.id]
            }
          }
        }
      )
      .subscribe()

    channelRef.current = channel

    return () => {
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current)
      }
    }
  }, [supabase, doctorId])

  const respondToRequest = async (appointmentId: string, patientId: string | null, accept: boolean) => {
    if (processingId) return
    setProcessingId(appointmentId)

    try {
      const newStatus = accept ? 'emergency_accepted' : 'emergency_declined'
      const { error } = await supabase
        .from('appointments')
        .update({ status: newStatus, is_doctor_approved: accept, ...(accept ? {} : { accepted_at: null }) })
        .eq('id', appointmentId)

      if (error) throw error

      // Notify patient (skip for guests — patient_id is null, they receive FCM push from creation)
      if (patientId) {
        try {
          await supabase.from('notifications').insert({
            user_id: patientId,
            title: accept ? 'Emergency Request Accepted' : 'Emergency Request Declined',
            message: accept
              ? 'Your doctor has accepted the emergency consultation. Please proceed with payment.'
              : 'The doctor is currently unavailable. Please try another doctor.',
            type: 'appointment',
            is_read: false,
          })
        } catch (_) {}
      }

      // Remove from local state
      setRequests((prev) => prev.filter((r) => r.id !== appointmentId))
      if (timersRef.current[appointmentId]) {
        clearInterval(timersRef.current[appointmentId])
        delete timersRef.current[appointmentId]
      }

      toast.success(accept ? 'Emergency Accepted' : 'Request Declined', {
        description: accept
          ? 'Patient notified. Awaiting payment confirmation.'
          : 'Patient has been notified.',
      })
    } catch (err) {
      console.error('Failed to respond:', err)
      toast.error('Action Failed', { description: 'Please try again.' })
    } finally {
      setProcessingId(null)
    }
  }

  if (requests.length === 0) return null

  return (
    <div className="space-y-4">
      {requests.map((req) => {
        const remaining = secondsByRequest[req.id] ?? 180
        const patientLabel = req.patient_id
          ? `Patient ···${req.patient_id.slice(-4)}`
          : 'Emergency Guest'
        const isExpired = remaining <= 0
        const isProcessing = processingId === req.id
        const mins = Math.floor(remaining / 60)
        const secs = remaining % 60
        const timerColor = remaining > 120 ? 'text-blue-600' : remaining > 60 ? 'text-amber-600' : 'text-red-600'
        const progress = remaining / 180

        return (
          <div
            key={req.id}
            className="relative overflow-hidden rounded-3xl border-2 border-red-200 bg-linear-to-br from-red-50 to-orange-50 p-6 shadow-xl"
          >
            {/* Animated pulse background */}
            {!isExpired && (
              <div className="absolute inset-0 bg-red-500/5 animate-pulse" />
            )}

            <div className="relative z-10 flex flex-col sm:flex-row sm:items-center gap-5">
              {/* Timer ring */}
              <div className="relative shrink-0 mx-auto sm:mx-0">
                <svg className="w-20 h-20 -rotate-90" viewBox="0 0 80 80">
                  <circle cx="40" cy="40" r="34" fill="none" stroke="#FEE2E2" strokeWidth="5" />
                  <circle
                    cx="40" cy="40" r="34"
                    fill="none"
                    stroke={isExpired ? '#EF4444' : remaining > 120 ? '#0F62FE' : remaining > 60 ? '#F59E0B' : '#EF4444'}
                    strokeWidth="5"
                    strokeLinecap="round"
                    strokeDasharray={`${2 * Math.PI * 34}`}
                    strokeDashoffset={`${2 * Math.PI * 34 * (1 - progress)}`}
                    className="transition-all duration-1000"
                  />
                </svg>
                <div className="absolute inset-0 flex items-center justify-center">
                  <span className={`text-base font-black tabular-nums ${isExpired ? 'text-red-500' : timerColor}`}>
                    {isExpired ? '0:00' : `${mins}:${secs.toString().padStart(2, '0')}`}
                  </span>
                </div>
              </div>

              {/* Info */}
              <div className="flex-1 text-center sm:text-left">
                <div className="flex items-center gap-2 justify-center sm:justify-start mb-1">
                  <ShieldAlert className="h-4 w-4 text-red-500" />
                  <span className="text-[10px] font-black text-red-600 uppercase tracking-widest">
                    Emergency Request
                  </span>
                </div>
                <p className="text-sm font-bold text-slate-700">
                  {patientLabel} — {req.duration_minutes}min consultation
                </p>
                <p className="text-xs text-slate-400 font-medium mt-0.5">
                  ₦{req.total_amount.toLocaleString()} • {new Date(req.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </p>
              </div>

              {/* Actions */}
              <div className="flex gap-3 shrink-0">
                <Button
                  variant="outline"
                  size="sm"
                  disabled={isProcessing || isExpired}
                  onClick={() => respondToRequest(req.id, req.patient_id, false)}
                  className="h-11 rounded-xl border-slate-200 text-slate-600 font-bold px-5"
                >
                  {isProcessing ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <>
                      <XCircle className="h-4 w-4 mr-1.5" />
                      Decline
                    </>
                  )}
                </Button>
                <Button
                  size="sm"
                  disabled={isProcessing || isExpired}
                  onClick={() => respondToRequest(req.id, req.patient_id, true)}
                  className="h-11 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold px-6 shadow-lg shadow-emerald-500/20"
                >
                  {isProcessing ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <>
                      <CheckCircle2 className="h-4 w-4 mr-1.5" />
                      Accept
                    </>
                  )}
                </Button>
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}
