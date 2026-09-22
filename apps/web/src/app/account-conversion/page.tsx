'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
  ShieldCheck, 
  CheckCircle2, 
  FolderOpen, 
  Calendar, 
  MessageSquare, 
  Bell, 
  ChevronRight, 
  Lock,
  ArrowRight,
  LogIn,
  Loader2,
  AlertCircle,
  User
} from 'lucide-react'
import Image from 'next/image'
import { createClient } from '@/lib/supabase'

export default function AccountConversionPage() {
  const router = useRouter()
  const supabase = createClient()
  const [email, setEmail] = useState<string | null>(null)
  const [appointmentId, setAppointmentId] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const storedEmail = localStorage.getItem('premon_guest_email')
    const storedAppointmentId = localStorage.getItem('premon_emergency_appointment_id')
    setEmail(storedEmail)
    setAppointmentId(storedAppointmentId)
    setLoading(false)
  }, [])

  const benefits = [
    {
      icon: FolderOpen,
      color: 'text-indigo-600',
      bgColor: 'bg-indigo-50',
      title: 'Access your health records',
      subtitle: 'View prescriptions, reports and visit history in one place.'
    },
    {
      icon: Calendar,
      color: 'text-emerald-600',
      bgColor: 'bg-emerald-50',
      title: 'Manage appointments',
      subtitle: 'Book, reschedule or cancel appointments with ease.'
    },
    {
      icon: MessageSquare,
      color: 'text-sky-600',
      bgColor: 'bg-sky-50',
      title: 'Consult anytime, anywhere',
      subtitle: 'Chat or video consult with doctors whenever you need.'
    },
    {
      icon: Bell,
      color: 'text-amber-600',
      bgColor: 'bg-amber-50',
      title: 'Stay updated',
      subtitle: 'Get reminders for appointments, medications and updates.'
    }
  ]

  const buildAuthUrl = (path: string) => {
    const params = new URLSearchParams()
    if (email) params.set('guest_email', email)
    if (appointmentId) params.set('appointment_id', appointmentId)
    const qs = params.toString()
    return `${path}${qs ? `?${qs}` : ''}`
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-6 font-sans">
      <div className="max-w-5xl w-full grid lg:grid-cols-2 gap-12 items-center">
        {/* Left Side: Illustration & Hero */}
        <div className="space-y-8 text-center lg:text-left">
          <div className="relative inline-block">
            <div className="relative h-48 w-48 md:h-64 md:w-64 rounded-full overflow-hidden border-8 border-white shadow-2xl mx-auto lg:mx-0 bg-indigo-100 flex items-center justify-center">
              <User className="h-24 w-24 text-indigo-400" />
            </div>
            <div className="absolute bottom-4 right-4 h-12 w-12 bg-emerald-500 rounded-full flex items-center justify-center text-white shadow-lg border-4 border-white animate-bounce-slow">
              <CheckCircle2 className="h-6 w-6" />
            </div>
          </div>

          <div className="space-y-4">
            <Badge className="bg-indigo-100 text-indigo-700 hover:bg-indigo-100 border-none px-4 py-1.5 rounded-full font-black text-[10px] uppercase tracking-widest mx-auto lg:mx-0">
              <ShieldCheck className="h-3.5 w-3.5 mr-2" />
              Emergency Session Successful
            </Badge>
            <h1 className="text-4xl md:text-6xl font-black text-slate-900 tracking-tighter leading-[0.95]">
              Secure your <br />
              <span className="text-transparent bg-clip-text bg-linear-to-r from-primary to-indigo-500">Care History.</span>
            </h1>
            <p className="text-slate-500 text-lg font-medium max-w-md mx-auto lg:mx-0">
              Your emergency consultation is complete. Convert your guest session into a permanent account to preserve your medical records.
            </p>
          </div>

          <div className="p-6 bg-white rounded-[2rem] border border-slate-200 flex items-center gap-4 max-w-sm mx-auto lg:mx-0 shadow-sm">
            <div className="h-12 w-12 rounded-2xl bg-slate-100 flex items-center justify-center text-slate-400">
              <Lock className="h-6 w-6" />
            </div>
            <div className="text-left">
              <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Protected Session</p>
              <p className="text-sm font-bold text-slate-900 truncate">{email || 'guest_session@premoncare.com'}</p>
            </div>
          </div>
        </div>

        {/* Right Side: Benefits & Action */}
        <Card className="border-none shadow-[0_50px_100px_-20px_rgba(30,41,59,0.15)] rounded-[3rem] overflow-hidden">
          <CardHeader className="bg-slate-900 text-white p-10">
            <CardTitle className="text-2xl font-black tracking-tight">Membership Benefits</CardTitle>
            <CardDescription className="text-slate-400 font-medium pt-2">Why you should create a permanent profile today.</CardDescription>
          </CardHeader>
          <CardContent className="p-10 space-y-6">
            {appointmentId && (
              <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-2xl flex items-center gap-3">
                <CheckCircle2 className="h-5 w-5 text-emerald-600 shrink-0" />
                <p className="text-xs font-bold text-emerald-800">
                  Your emergency booking is saved. Creating an account will link it to your profile automatically.
                </p>
              </div>
            )}

            <div className="space-y-6">
              {benefits.map((benefit, idx) => (
                <div key={idx} className="flex items-center gap-5 group cursor-default">
                  <div className={`h-14 w-14 rounded-2xl ${benefit.bgColor} flex items-center justify-center ${benefit.color} shrink-0 group-hover:scale-110 transition-transform shadow-sm`}>
                    <benefit.icon className="h-7 w-7" />
                  </div>
                  <div className="flex-1 space-y-0.5 border-b border-slate-100 pb-4 last:border-0 last:pb-0">
                    <h4 className="text-md font-black text-slate-900 flex items-center justify-between">
                      {benefit.title}
                      <ChevronRight className="h-4 w-4 text-slate-200 group-hover:text-primary transition-colors" />
                    </h4>
                    <p className="text-xs text-slate-500 font-medium leading-relaxed">{benefit.subtitle}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className="pt-6 space-y-4">
              <Button 
                onClick={() => router.push(buildAuthUrl('/register'))} 
                className="w-full h-16 rounded-2xl bg-primary text-white font-black hover:scale-[1.02] transition-transform shadow-2xl shadow-primary/20 text-lg uppercase tracking-widest"
              >
                Create Account <ArrowRight className="ml-3 h-6 w-6" />
              </Button>
              <Button 
                variant="outline"
                onClick={() => router.push(buildAuthUrl('/login'))} 
                className="w-full h-16 rounded-2xl border-slate-200 text-slate-600 font-black hover:bg-slate-50 transition-colors uppercase tracking-widest text-xs"
              >
                <LogIn className="mr-3 h-5 w-5" /> I already have an account
              </Button>
            </div>
          </CardContent>
          <CardFooter className="bg-slate-50 p-8 border-t border-slate-100 flex items-center gap-4">
            <div className="h-10 w-10 bg-white rounded-full flex items-center justify-center text-emerald-600 border border-emerald-100 shadow-sm">
              <ShieldCheck className="h-5 w-5" />
            </div>
            <p className="text-[10px] font-bold text-slate-500 leading-relaxed italic uppercase tracking-wider">
              Your health data is encrypted using military-grade AES-256 standards. <br />Only you can grant access to your medical vault.
            </p>
          </CardFooter>
        </Card>
      </div>
    </div>
  )
}
