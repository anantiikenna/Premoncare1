'use client'

import { useState, useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { 
  ShieldAlert, 
  ArrowRight, 
  ArrowLeft, 
  CheckCircle2, 
  Loader2, 
  Banknote, 
  Star, 
  Clock, 
  Activity,
  AlertCircle
} from 'lucide-react'
import Image from 'next/image'
import { OTPForm } from '@/components/auth/otp-form'
import { toast } from 'sonner'
import { getUserFacingError } from '@/lib/user-facing-errors'
import { emergencyAmount, emergencyHourlyRate } from '@/lib/emergency-pricing'
async function dispatchNotificationViaApi(payload: {
  userId: string;
  title: string;
  message: string;
  type: string;
  link?: string;
  sendEmail?: boolean;
  emailTemplate?: string;
  emailData?: Record<string, any>;
}) {
  try {
    await fetch('/api/notifications/dispatch', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
  } catch (err) {
    console.error('Failed to dispatch notification:', err)
  }
}

interface EmergencyDoctor {
  id: string
  full_name: string
  specialty?: string | null
  avatar_url?: string | null
  consultation_fee?: number | null
  hourly_rate?: number | null
  experience_years?: number | null
  clinic_address?: string | null
  payment_instructions?: string | null
  reviews?: { rating: number | null }[] | null
}

export default function EmergencyBookingPage() {
  const [step, setStep] = useState(1)
  const [doctors, setDoctors] = useState<EmergencyDoctor[]>([])
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  
  const [selectedDoctor, setSelectedDoctor] = useState<EmergencyDoctor | null>(null)
  const [duration, setDuration] = useState(15)
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')

  const router = useRouter()
  const supabase = createClient()
  const [otpVerified, setOtpVerified] = useState(false)
  const [showOtp, setShowOtp] = useState(false)

  const sendOtp = async () => {
    const { error: otpError } = await supabase.auth.signInWithOtp({
      email,
      options: {
        shouldCreateUser: false,
      },
    })

    if (otpError) throw otpError
    toast.success('Verification code sent to ' + email)
  }

  const handleVerifyOtp = async (code: string) => {
    const { error: verifyError } = await supabase.auth.verifyOtp({
      email,
      token: code,
      type: 'email',
    })

    if (verifyError) throw verifyError
    setOtpVerified(true)
    setShowOtp(false)
    handleNext()
    toast.success('Identity Verified')
  }

  const handleResendOtp = async () => {
    await sendOtp()
  }

  useEffect(() => {
    let cancelled = false

    async function fetchDoctors() {
      setLoading(true)
      const now = new Date().toISOString()
      const { data } = await supabase
        .from('profiles')
        .select('id, full_name, specialty, avatar_url, consultation_fee, hourly_rate, experience_years, clinic_address, payment_instructions, is_online, is_emergency, reviews(rating)')
        .eq('role', 'doctor')
        .eq('verification_status', 'approved')
        .eq('subscription_status', 'active')
        .gt('subscription_expires_at', now)
        .eq('is_online', true)
        .eq('is_emergency', true)

      if (!cancelled && data) setDoctors(data)
      if (!cancelled) setLoading(false)
    }

    fetchDoctors()

    const channel = supabase
      .channel('emergency:doctors-live')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'profiles', filter: 'role=eq.doctor' },
        () => { fetchDoctors() }
      )
      .subscribe()

    return () => {
      cancelled = true
      supabase.removeChannel(channel)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleNext = () => setStep(step + 1)
  const handleBack = () => setStep(step - 1)

  const handleSubmit = async () => {
    if (!selectedDoctor) {
      setError('Please select a doctor before starting emergency booking')
      return
    }

    setSubmitting(true)
    setError(null)

    try {
      const guestToken = `guest_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`
      localStorage.setItem('premon_guest_token', guestToken)
      localStorage.setItem('premon_guest_email', email)
      localStorage.setItem('premon_guest_phone', phone)

      const totalAmount = emergencyAmount(selectedDoctor.consultation_fee, selectedDoctor.hourly_rate, duration)

      const { data: appointmentData, error: bookingError } = await supabase
        .from('appointments')
        .insert({
          patient_id: null,
          doctor_id: selectedDoctor.id,
          appointment_date: new Date().toISOString(),
          reason: 'EMERGENCY CONSULTATION (Guest)',
          duration_minutes: duration,
          status: 'emergency_request',
          is_patient_approved: true,
          is_emergency: true,
          total_amount: totalAmount,
          metadata: {
            is_emergency: true,
            guest_email: email,
            guest_phone: phone,
            guest_token: guestToken,
            pricing_multiplier: 5
          }
        })
        .select('id')
        .single()

      if (bookingError) throw bookingError

      // Link the authenticated user (from OTP) to the appointment
      const { data: { user } } = await supabase.auth.getUser()
      if (user?.id && appointmentData?.id) {
        await supabase
          .from('appointments')
          .update({ patient_id: user.id })
          .eq('id', appointmentData.id)
      }

      // Store appointment data for the waiting page
      if (appointmentData?.id) {
        localStorage.setItem('premon_emergency_appointment_id', appointmentData.id)
        localStorage.setItem('premon_emergency_doctor_name', selectedDoctor.full_name)
        localStorage.setItem('premon_emergency_doctor_id', selectedDoctor.id)
        localStorage.setItem('premon_emergency_amount', String(totalAmount))
        localStorage.setItem('premon_emergency_duration', String(duration))
      }

      // Notify the doctor via full notification pipeline (DB + FCM push + email)
      dispatchNotificationViaApi({
        userId: selectedDoctor.id,
        title: 'EMERGENCY Consultation Request',
        message: `A patient has requested an EMERGENCY ${duration}-minute consultation. Fee: ₦${totalAmount.toLocaleString()}`,
        type: 'appointment',
        link: '/doctor/appointments',
        sendEmail: true,
        emailTemplate: 'doctorAppointment',
        emailData: {
          doctorName: selectedDoctor.full_name,
          patientEmail: email,
          duration: duration,
          amount: totalAmount,
          isEmergency: true,
        },
      })

      // Redirect to waiting page (patient waits for doctor acceptance)
      router.push('/emergency-waiting')
    } catch (err: unknown) {
      console.error('Emergency booking failed', err)
      setError(getUserFacingError(err, 'We could not start the emergency booking. Please try again or contact support.'))
    } finally {
      setSubmitting(false)
    }
  }

  // Removed success screen — redirect to /emergency-waiting instead

  return (
    <div className="min-h-screen bg-slate-50 font-sans selection:bg-red-100 selection:text-red-900">
      <div className="max-w-4xl mx-auto py-12 md:py-20 px-6">
        <header className="text-center space-y-4 mb-12">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-red-100 text-red-600 text-[10px] font-black uppercase tracking-[0.2em] animate-pulse">
            <ShieldAlert className="h-4 w-4" /> Emergency Access Mode
          </div>
          <h1 className="text-4xl md:text-6xl font-black text-slate-900 tracking-tighter">
            Rapid Consult. <span className="text-red-600 italic">No Wait.</span>
          </h1>
          <p className="text-slate-500 font-medium max-w-xl mx-auto">
            Bypass registration and connect with a verified specialist in minutes. 
            <span className="block mt-2 font-bold text-red-500">Premium 5x emergency rates apply.</span>
          </p>
        </header>

        <Card className="border-none shadow-[0_20px_50px_-20px_rgba(220,38,38,0.15)] overflow-hidden">
          <CardHeader className="bg-slate-900 text-white p-8 md:p-10">
            <div className="flex justify-between items-center">
              <div className="space-y-1">
                <CardTitle className="text-2xl font-black">Emergency Booking</CardTitle>
                <CardDescription className="text-slate-400 font-medium">Step {step} of 3</CardDescription>
              </div>
              <div className="h-12 w-12 rounded-2xl bg-red-600 flex items-center justify-center shadow-[0_0_20px_rgba(220,38,38,0.5)]">
                <Activity className="h-6 w-6 text-white" />
              </div>
            </div>
            <div className="w-full bg-white/10 h-1.5 rounded-full mt-8 overflow-hidden">
              <div 
                className="bg-red-600 h-full transition-all duration-500 ease-out"
                style={{ width: `${(step / 3) * 100}%` }}
              />
            </div>
          </CardHeader>

          <CardContent className="p-8 md:p-10 space-y-8">
            {error && (
              <div className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">
                {error}
              </div>
            )}
            {step === 1 && (
              <div className="space-y-6">
                <div className="grid gap-4 max-h-125 overflow-y-auto pr-2 custom-scrollbar">
                  {loading ? (
                    <div className="flex flex-col items-center justify-center py-20 gap-4">
                      <Loader2 className="h-10 w-10 animate-spin text-red-600" />
                      <p className="text-slate-400 font-bold uppercase text-xs tracking-widest">Searching Online Doctors...</p>
                    </div>
                  ) : doctors.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-16 px-6 text-center border-2 border-dashed border-red-100 rounded-[2rem] bg-red-50/10">
                      <div className="h-16 w-16 rounded-2xl bg-red-100 flex items-center justify-center mb-4 shadow-inner text-red-600">
                        <ShieldAlert className="h-8 w-8" />
                      </div>
                      <h4 className="text-lg font-black text-slate-900 mb-2">No Specialists Online</h4>
                      <p className="text-sm text-slate-500 max-w-sm mb-6 leading-relaxed">
                        All verified doctors are currently offline or handling critical clinical cases. Please try again in a few minutes, or return to safety.
                      </p>
                      <Button 
                        onClick={() => router.push('/')} 
                        className="h-11 rounded-xl bg-slate-900 text-white font-black text-xs uppercase tracking-widest px-6"
                      >
                        Return to Safety
                      </Button>
                    </div>
                  ) : (
                    doctors.map((doctor) => (
                      <div 
                        key={doctor.id}
                        onClick={() => setSelectedDoctor(doctor)}
                        className={`
                          group relative flex items-center gap-5 p-6 rounded-[2rem] border-2 transition-all cursor-pointer
                          ${selectedDoctor?.id === doctor.id 
                            ? 'border-red-600 bg-red-50/50 shadow-lg' 
                            : 'border-slate-100 hover:border-red-200 hover:bg-slate-50'}
                        `}
                      >
                        <div className="relative h-16 w-16 md:h-20 md:w-20 rounded-full overflow-hidden border-4 border-white shadow-md bg-red-50 flex items-center justify-center">
                          {doctor.avatar_url ? (
                            <Image 
                              src={doctor.avatar_url} 
                              alt={doctor.full_name} 
                              fill 
                              className="object-cover"
                            />
                          ) : (
                            <span className="text-xl font-black text-red-400">{doctor.full_name?.charAt(0) || 'D'}</span>
                          )}
                        </div>
                        <div className="flex-1 space-y-1">
                          <div className="flex items-center gap-2">
                            <h4 className="text-lg font-black text-slate-900">Dr. {doctor.full_name}</h4>
                            <CheckCircle2 className="h-4 w-4 text-red-600" />
                          </div>
                          <p className="text-sm text-slate-500 font-bold">{doctor.specialty || 'Emergency Care'}</p>
                          <div className="flex items-center gap-4 pt-1">
                            <div className="flex items-center gap-1 text-amber-500 font-black text-xs">
                              <Star className="h-3 w-3 fill-current" /> {doctor.reviews?.length ? (doctor.reviews.reduce((sum, r) => sum + (r.rating || 0), 0) / doctor.reviews.length).toFixed(1) : 'N/A'}
                            </div>
                            <div className="text-[10px] text-slate-400 font-black uppercase tracking-widest">
                              {doctor.experience_years || 5}+ Years Exp.
                            </div>
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="text-xl font-black text-red-600">₦{emergencyHourlyRate(doctor.consultation_fee, doctor.hourly_rate).toLocaleString()}</div>
                          <div className="text-[10px] text-slate-400 font-bold uppercase tracking-tighter">Emergency Rate</div>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>
            )}


    {step === 2 && (
      <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
        {!showOtp ? (
          <>
            <div className="grid md:grid-cols-2 gap-8">
              <div className="space-y-3">
                <Label className="text-xs font-black uppercase tracking-widest text-slate-500">Your Contact Email</Label>
                <Input 
                  placeholder="email@example.com" 
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="h-14 rounded-2xl border-slate-200 focus:ring-red-600 focus:border-red-600 text-lg"
                />
              </div>
              <div className="space-y-3">
                <Label className="text-xs font-black uppercase tracking-widest text-slate-500">Mobile Number</Label>
                <Input 
                  placeholder="+234..." 
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="h-14 rounded-2xl border-slate-200 focus:ring-red-600 focus:border-red-600 text-lg"
                />
              </div>
            </div>

            <div className="space-y-6">
              <Label className="text-xs font-black uppercase tracking-widest text-slate-500">Consultation Duration</Label>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {[15, 30, 45, 60].map((mins) => (
                  <div 
                    key={mins}
                    onClick={() => setDuration(mins)}
                    className={`
                      p-4 rounded-2xl border-2 text-center transition-all cursor-pointer
                      ${duration === mins 
                        ? 'border-red-600 bg-red-600 text-white shadow-lg' 
                        : 'border-slate-100 hover:border-red-200'}
                    `}
                  >
                    <div className="text-xl font-black">{mins}</div>
                    <div className="text-[10px] font-bold uppercase tracking-widest opacity-70">Minutes</div>
                  </div>
                ))}
              </div>
            </div>
          </>
        ) : (
          <div className="py-4">
            <OTPForm email={email} onVerify={handleVerifyOtp} onResend={handleResendOtp} />
          </div>
        )}

                <div className="p-6 bg-slate-900 rounded-[2rem] text-white flex items-center justify-between shadow-2xl">
                  <div className="flex items-center gap-4">
                    <div className="h-12 w-12 rounded-2xl bg-white/10 flex items-center justify-center">
                      <Clock className="h-6 w-6 text-red-500" />
                    </div>
                    <div>
                      <div className="text-xs font-bold uppercase tracking-widest opacity-50">Total Emergency Fee</div>
                      <div className="text-2xl font-black">
                        ₦{emergencyAmount(selectedDoctor?.consultation_fee, selectedDoctor?.hourly_rate, duration).toLocaleString()}
                      </div>
                    </div>
                  </div>
                  <Badge variant="outline" className="border-red-500 text-red-500 font-black px-4 py-1 rounded-full uppercase tracking-widest text-[10px]">
                    5x Premium Included
                  </Badge>
                </div>
              </div>
            )}

            {step === 3 && (
              <div className="space-y-8 animate-in zoom-in-95 duration-500">
                <div className="bg-red-50 border-2 border-red-100 p-8 rounded-[3rem] text-center space-y-6">
                  <div className="h-20 w-20 bg-red-600 rounded-full flex items-center justify-center mx-auto shadow-xl shadow-red-200">
                    <AlertCircle className="h-10 w-10 text-white" />
                  </div>
                  <div className="space-y-2">
                    <h3 className="text-2xl font-black text-slate-900">Confirm Emergency Consult</h3>
                    <p className="text-slate-600 font-medium">
                      You are about to initiate an emergency session with <span className="font-bold text-red-600">Dr. {selectedDoctor?.full_name}</span>.
                    </p>
                  </div>
                  <div className="grid grid-cols-2 gap-4 text-left">
                    <div className="p-4 bg-white rounded-2xl shadow-sm border border-slate-100">
                      <div className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Duration</div>
                      <div className="text-lg font-black text-slate-900">{duration} Minutes</div>
                    </div>
                    <div className="p-4 bg-white rounded-2xl shadow-sm border border-slate-100">
                      <div className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Pricing</div>
                      <div className="text-lg font-black text-red-600">5x Multiplier</div>
                    </div>
                  </div>
                  <div className="flex items-start gap-3 p-4 bg-white/50 rounded-2xl border border-red-200 text-left">
                    <ShieldAlert className="h-5 w-5 text-red-600 shrink-0 mt-0.5" />
                    <p className="text-xs text-red-900 font-bold leading-relaxed italic">
                      By proceeding, you acknowledge that payment must be verified by the doctor before the session starts.
                    </p>
                  </div>
                </div>
              </div>
            )}
          </CardContent>

          <CardFooter className="p-8 md:p-10 bg-slate-50 border-t border-slate-100 flex justify-between gap-6">
            <Button 
              variant="ghost" 
              onClick={step === 1 ? () => router.push('/') : handleBack}
              className="h-14 px-8 rounded-2xl font-bold hover:bg-slate-200 transition-colors"
            >
              <ArrowLeft className="mr-2 h-5 w-5" /> {step === 1 ? 'Cancel' : 'Back'}
            </Button>
            
            {step < 3 ? (
              <Button 
                onClick={() => {
                  if (step === 1) handleNext()
                  else if (step === 2) {
                    if (!otpVerified) {
                      if (!email || !phone) {
                        toast.error('Email and Phone are required')
                        return
                      }
                      sendOtp()
                        .then(() => setShowOtp(true))
                        .catch((otpError) => {
                          console.error('Emergency OTP send failed', otpError)
                          toast.error(getUserFacingError(otpError, 'We could not send the verification code. Please try again.'))
                        })
                    } else {
                      handleNext()
                    }
                  }
                }}
                disabled={step === 1 ? !selectedDoctor : (!email || !phone) || (step === 2 && showOtp)}
                className="h-14 px-12 rounded-2xl bg-slate-900 text-white font-black hover:scale-105 transition-transform"
              >
                {step === 2 && !otpVerified ? 'Verify Identity' : 'Continue'} <ArrowRight className="ml-2 h-5 w-5" />
              </Button>
            ) : (
              <Button 
                onClick={handleSubmit}
                disabled={submitting}
                className="h-14 px-16 rounded-2xl bg-red-600 text-white font-black hover:scale-105 transition-transform shadow-xl shadow-red-200"
              >
                {submitting ? (
                  <Loader2 className="h-6 w-6 animate-spin mr-2" />
                ) : (
                  <Activity className="h-6 w-6 mr-2" />
                )}
                Initiate Consult Now
              </Button>
            )}
          </CardFooter>
        </Card>

        <footer className="mt-12 text-center text-slate-400 text-[10px] font-black uppercase tracking-[0.3em]">
          © 2026 Premon Care - Rapid Response Infrastructure
        </footer>
      </div>
    </div>
  )
}
