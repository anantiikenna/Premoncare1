'use client'

import { useState, useEffect, useCallback, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import {
  Loader2,
  CheckCircle2,
  XCircle,
  Clock,
  AlertTriangle,
  ArrowRight,
  User,
} from 'lucide-react'

type WaitingStatus = 'waiting' | 'accepted' | 'declined' | 'timeout'

export default function EmergencyWaitingPage() {
  const router = useRouter()
  const supabase = createClient()

  const [appointmentId, setAppointmentId] = useState<string>('')
  const [doctorName, setDoctorName] = useState<string>('')
  const [doctorId, setDoctorId] = useState<string>('')
  const [amount, setAmount] = useState<number>(0)
  const [duration, setDuration] = useState<number>(15)
  const [status, setStatus] = useState<WaitingStatus>('waiting')
  const [secondsRemaining, setSecondsRemaining] = useState(180)
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null)
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)

  // Load data from localStorage on mount
  useEffect(() => {
    const id = localStorage.getItem('premon_emergency_appointment_id')
    const name = localStorage.getItem('premon_emergency_doctor_name')
    const docId = localStorage.getItem('premon_emergency_doctor_id')
    const amt = localStorage.getItem('premon_emergency_amount')
    const dur = localStorage.getItem('premon_emergency_duration')

    if (!id) {
      router.push('/emergency')
      return
    }

    setAppointmentId(id)
    setDoctorName(name || 'Doctor')
    setDoctorId(docId || '')
    setAmount(amt ? Number(amt) : 0)
    setDuration(dur ? Number(dur) : 15)
  }, [router])

  // Countdown timer
  useEffect(() => {
    if (status !== 'waiting') return

    timerRef.current = setInterval(() => {
      setSecondsRemaining((prev) => {
        if (prev <= 1) {
          if (timerRef.current) clearInterval(timerRef.current)
          return 0
        }
        return prev - 1
      })
    }, 1000)

    return () => {
      if (timerRef.current) clearInterval(timerRef.current)
    }
  }, [status])

  // Auto-decline on timeout
  useEffect(() => {
    if (secondsRemaining === 0 && status === 'waiting') {
      handleTimeout()
    }
  }, [secondsRemaining, status])

  // Real-time subscription to appointment status
  const subscribeToAppointment = useCallback(() => {
    if (!appointmentId) return

    const channel = supabase
      .channel(`emergency:waiting:${appointmentId}`, {
        config: { private: true },
      })
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'appointments',
          filter: `id=eq.${appointmentId}`,
        },
        (payload) => {
          const newStatus = payload.new?.status as string
          if (newStatus === 'emergency_accepted') {
            setStatus('accepted')
            // Redirect to checkout after brief delay
            setTimeout(() => {
              localStorage.setItem('premon_emergency_accepted', 'true')
              router.push(`/checkout?appointmentId=${appointmentId}`)
            }, 2000)
          } else if (newStatus === 'emergency_declined') {
            setStatus('declined')
          }
        }
      )
      .subscribe()

    channelRef.current = channel
  }, [appointmentId, supabase, router])

  useEffect(() => {
    subscribeToAppointment()
    return () => {
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current)
      }
    }
  }, [subscribeToAppointment, supabase])

  const handleTimeout = async () => {
    if (!appointmentId) return
    try {
      await supabase
        .from('appointments')
        .update({ status: 'emergency_declined' })
        .eq('id', appointmentId)
    } catch (err) {
      console.error('Failed to auto-decline:', err)
    }
    setStatus('timeout')
  }

  const handleCancel = async () => {
    if (!appointmentId) return
    try {
      await supabase
        .from('appointments')
        .update({ status: 'emergency_declined' })
        .eq('id', appointmentId)
    } catch (err) {
      console.error('Failed to cancel:', err)
    }
    router.push('/doctors')
  }

  const handleFindAnother = () => {
    localStorage.removeItem('premon_emergency_appointment_id')
    localStorage.removeItem('premon_emergency_doctor_name')
    localStorage.removeItem('premon_emergency_doctor_id')
    localStorage.removeItem('premon_emergency_amount')
    localStorage.removeItem('premon_emergency_duration')
    router.push('/doctors')
  }

  const formatTime = (s: number) => {
    const mins = Math.floor(s / 60)
    const secs = s % 60
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  const progress = secondsRemaining / 180
  const timerColor =
    secondsRemaining > 120
      ? 'text-blue-600'
      : secondsRemaining > 60
        ? 'text-amber-600'
      : 'text-red-600'

  const strokeColor =
    secondsRemaining > 120
      ? '#0F62FE'
      : secondsRemaining > 60
        ? '#F59E0B'
      : '#EF4444'

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-6">
      <Card className="w-full max-w-xl border-slate-200 shadow-2xl overflow-hidden">
        <CardContent className="p-8 space-y-8">
          {/* Status Header */}
          <div className="text-center space-y-4">
            {status === 'waiting' && (
              <>
                <div className="relative mx-auto w-24 h-24">
                  <svg className="w-24 h-24 -rotate-90" viewBox="0 0 96 96">
                    <circle
                      cx="48" cy="48" r="42"
                      fill="none"
                      stroke="#E2E8F0"
                      strokeWidth="6"
                    />
                    <circle
                      cx="48" cy="48" r="42"
                      fill="none"
                      stroke={strokeColor}
                      strokeWidth="6"
                      strokeLinecap="round"
                      strokeDasharray={`${2 * Math.PI * 42}`}
                      strokeDashoffset={`${2 * Math.PI * 42 * (1 - progress)}`}
                      className="transition-all duration-1000"
                    />
                  </svg>
                  <div className="absolute inset-0 flex items-center justify-center">
                    <span className={`text-2xl font-black tabular-nums ${timerColor}`}>
                      {formatTime(secondsRemaining)}
                    </span>
                  </div>
                </div>
                <h1 className="text-2xl font-black text-slate-900">Connecting You...</h1>
                <p className="text-sm text-slate-500 font-medium">
                  Sending your emergency request to <span className="font-bold text-slate-700">{doctorName}</span>
                </p>
              </>
            )}

            {status === 'accepted' && (
              <>
                <div className="mx-auto w-20 h-20 rounded-full bg-emerald-100 flex items-center justify-center">
                  <CheckCircle2 className="h-10 w-10 text-emerald-600" />
                </div>
                <h1 className="text-2xl font-black text-emerald-700">Doctor Accepted!</h1>
                <p className="text-sm text-slate-500 font-medium">
                  {doctorName} is ready for your consultation. Redirecting to payment...
                </p>
              </>
            )}

            {(status === 'declined' || status === 'timeout') && (
              <>
                <div className="mx-auto w-20 h-20 rounded-full bg-red-100 flex items-center justify-center">
                  <XCircle className="h-10 w-10 text-red-600" />
                </div>
                <h1 className="text-2xl font-black text-red-700">
                  {status === 'declined' ? 'Doctor Unavailable' : 'Request Expired'}
                </h1>
                <p className="text-sm text-slate-500 font-medium">
                  {status === 'declined'
                    ? `${doctorName} is currently unavailable. Let us find you another specialist.`
                    : 'The request timed out. We will find you another available doctor.'}
                </p>
              </>
            )}
          </div>

          {/* Doctor Card */}
          <div className="bg-white border border-slate-200 rounded-2xl p-5 flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center">
              <User className="h-6 w-6 text-slate-400" />
            </div>
            <div className="flex-1">
              <p className="font-black text-slate-900">{doctorName}</p>
              <p className="text-xs text-red-600 font-bold uppercase tracking-wider">
                Emergency Consultation
              </p>
            </div>
            {status === 'accepted' && (
              <div className="w-8 h-8 rounded-full bg-emerald-100 flex items-center justify-center">
                <CheckCircle2 className="h-4 w-4 text-emerald-600" />
              </div>
            )}
          </div>

          {/* Info Banner */}
          {status === 'waiting' && (
            <div className="bg-blue-50 border border-blue-100 rounded-xl p-4 flex gap-3">
              <AlertTriangle className="h-5 w-5 text-blue-600 shrink-0 mt-0.5" />
              <p className="text-xs text-blue-700 font-medium leading-relaxed">
                The doctor will receive an urgent notification. You will be connected immediately once they accept.
              </p>
            </div>
          )}

          {/* Action Buttons */}
          {status === 'waiting' && (
            <Button
              onClick={handleCancel}
              variant="outline"
              className="w-full h-14 text-base font-bold border-slate-200"
            >
              Cancel Request
            </Button>
          )}

          {(status === 'declined' || status === 'timeout') && (
            <div className="space-y-3">
              <Button
                onClick={handleFindAnother}
                className="w-full h-14 text-base font-bold bg-[#0F62FE] hover:bg-[#0050CC]"
              >
                Find Another Doctor
              </Button>
              <Button
                onClick={() => router.push('/')}
                variant="outline"
                className="w-full h-14 text-base font-bold"
              >
                Back to Home
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
