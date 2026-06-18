'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { 
  Activity, Radio, Video, Users, User, ShieldAlert,
  Loader2, ExternalLink, Calendar, Stethoscope
} from 'lucide-react'
import { toast } from 'sonner'
import Image from 'next/image'

export function LiveMonitor() {
  const [onlineDoctors, setOnlineDoctors] = useState<any[]>([])
  const [activeSessions, setActiveSessions] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const supabase = createClient()

  // 1. Initial Fetch
  useEffect(() => {
    async function initData() {
      setLoading(true)
      try {
        // Fetch online doctors
        const { data: doctors } = await supabase
          .from('profiles')
          .select('id, full_name, specialty, avatar_url, last_seen')
          .eq('role', 'doctor')
          .eq('is_online', true)

        if (doctors) setOnlineDoctors(doctors)

        // Fetch ongoing appointments
        const { data: appointments } = await supabase
          .from('appointments')
          .select(`
            id,
            appointment_date,
            duration_minutes,
            status,
            reason,
            doctor:doctor_id(full_name, avatar_url),
            patient:patient_id(full_name, avatar_url),
            metadata
          `)
          .eq('status', 'ongoing')

        if (appointments) setActiveSessions(appointments)
      } catch (err: any) {
        toast.error('Failed to load live monitor logs')
      } finally {
        setLoading(false)
      }
    }
    initData()
  }, [supabase])

  // 2. Realtime listener setup
  useEffect(() => {
    // Listen to changes on profiles (online toggle status changes)
    const profileChannel = supabase
      .channel('live-profiles-channel')
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: 'profiles' },
        (payload: any) => {
          const updatedUser = payload.new
          if (updatedUser.role === 'doctor') {
            setOnlineDoctors((prev) => {
              const exists = prev.some((d) => d.id === updatedUser.id)
              if (updatedUser.is_online) {
                if (exists) {
                  return prev.map((d) => d.id === updatedUser.id ? updatedUser : d)
                } else {
                  return [...prev, updatedUser]
                }
              } else {
                return prev.filter((d) => d.id !== updatedUser.id)
              }
            })
          }
        }
      )
      .subscribe()

    // Listen to changes on appointments (live call status changes)
    const appointmentChannel = supabase
      .channel('live-appointments-channel')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'appointments' },
        async () => {
          // Re-fetch active appointments to handle fully nested relational schemas properly
          const { data: appointments } = await supabase
            .from('appointments')
            .select(`
              id,
              appointment_date,
              duration_minutes,
              status,
              reason,
              doctor:doctor_id(full_name, avatar_url),
              patient:patient_id(full_name, avatar_url),
              metadata
            `)
            .eq('status', 'ongoing')

          if (appointments) setActiveSessions(appointments)
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(profileChannel)
      supabase.removeChannel(appointmentChannel)
    }
  }, [supabase])

  return (
    <div className="grid gap-8 lg:grid-cols-12">
      {/* Live Consultations Widget */}
      <Card className="lg:col-span-8 rounded-[2.5rem] border-slate-100 shadow-2xl bg-white/50 backdrop-blur-xl overflow-hidden">
        <CardHeader className="p-8 bg-slate-900 text-white flex flex-row items-center justify-between">
          <div className="space-y-1">
            <CardTitle className="text-xl font-black flex items-center gap-2">
              <Video className="h-5 w-5 text-red-500 animate-pulse" /> Live Consultations
            </CardTitle>
            <CardDescription className="text-slate-400 font-medium text-xs">
              Direct administrative audit of ongoing patient-practitioner call sessions.
            </CardDescription>
          </div>
          <Badge className="bg-red-500 text-white border-none rounded-full px-3 py-1 font-black text-[10px] uppercase tracking-widest animate-pulse">
            Live Feed
          </Badge>
        </CardHeader>
        <CardContent className="p-8">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-20 gap-4">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
              <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Streaming live sessions...</p>
            </div>
          ) : activeSessions.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-center border-2 border-dashed border-slate-100 rounded-3xl bg-slate-50/20">
              <div className="h-14 w-14 rounded-2xl bg-slate-100 flex items-center justify-center mb-4 text-slate-400">
                <Video className="h-7 w-7" />
              </div>
              <h4 className="text-base font-black text-slate-900 mb-1">No Active Consultations</h4>
              <p className="text-xs text-slate-400 max-w-xs leading-relaxed">
                There are currently no active emergency or scheduled consultation sessions running on the server.
              </p>
            </div>
          ) : (
            <div className="grid gap-4 md:grid-cols-2">
              {activeSessions.map((session) => (
                <div key={session.id} className="relative p-6 rounded-3xl bg-white border border-slate-100 shadow-sm hover:shadow-lg transition-all space-y-4">
                  <div className="flex items-center justify-between">
                    <span className="text-[9px] font-black text-slate-400 uppercase tracking-widest">
                      {session.metadata?.is_emergency ? 'Emergency' : 'Scheduled'}
                    </span>
                    <Badge variant="outline" className="border-red-500 text-red-500 font-black text-[9px] uppercase px-2.5 py-0.5 rounded-full">
                      Ongoing
                    </Badge>
                  </div>

                  <div className="flex items-center justify-between gap-2 p-3 bg-slate-50 rounded-2xl">
                    <div className="flex items-center gap-2.5 min-w-0">
                      <div className="relative h-9 w-9 rounded-full overflow-hidden border border-white shadow-sm bg-white shrink-0">
                        <Image
                          src={session.patient?.avatar_url || `https://i.pravatar.cc/100?u=${session.id}`}
                          alt={session.patient?.full_name || 'Patient'}
                          fill
                          className="object-cover"
                        />
                      </div>
                      <span className="text-xs font-black text-slate-900 truncate">
                        {session.patient?.full_name || 'Emergency Guest'}
                      </span>
                    </div>
                    <span className="text-[10px] font-black text-slate-400 shrink-0">VS</span>
                    <div className="flex items-center gap-2.5 min-w-0">
                      <span className="text-xs font-black text-slate-900 truncate">
                        Dr. {session.doctor?.full_name || 'Specialist'}
                      </span>
                      <div className="relative h-9 w-9 rounded-full overflow-hidden border border-white shadow-sm bg-white shrink-0">
                        <Image
                          src={session.doctor?.avatar_url || `https://i.pravatar.cc/100?u=${session.id}`}
                          alt={session.doctor?.full_name || 'Doctor'}
                          fill
                          className="object-cover"
                        />
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center justify-between text-[10px] font-bold text-slate-500 pt-1">
                    <span className="flex items-center gap-1">
                      <Calendar className="h-3.5 w-3.5 text-slate-400" />
                      {new Date(session.appointment_date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </span>
                    <span>{session.duration_minutes} Mins Duration</span>
                  </div>

                  <Button variant="ghost" className="w-full h-10 rounded-xl bg-slate-900/5 hover:bg-slate-900/10 text-slate-900 font-black text-[10px] uppercase tracking-widest mt-2">
                    <ExternalLink className="mr-1.5 h-3.5 w-3.5" /> Moderate Meeting
                  </Button>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Online Doctor Registry Widget */}
      <Card className="lg:col-span-4 rounded-[2.5rem] border-slate-100 shadow-2xl bg-white/50 backdrop-blur-xl overflow-hidden">
        <CardHeader className="p-8 bg-slate-50 border-b">
          <CardTitle className="text-lg font-black flex items-center gap-2 text-slate-900">
            <Radio className="h-5 w-5 text-emerald-500" /> Active Specialist Pool
          </CardTitle>
          <CardDescription className="text-slate-400 font-medium text-xs">
            Practitioners currently standing by for consultation bookings.
          </CardDescription>
        </CardHeader>
        <CardContent className="p-8 space-y-4 max-h-[500px] overflow-y-auto custom-scrollbar">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-20 gap-4">
              <Loader2 className="h-6 w-6 animate-spin text-primary" />
            </div>
          ) : onlineDoctors.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-center border-2 border-dashed border-slate-100 rounded-3xl bg-slate-50/20">
              <span className="h-12 w-12 rounded-2xl bg-slate-100 flex items-center justify-center mb-3 text-slate-400">
                <Users className="h-6 w-6" />
              </span>
              <p className="text-xs font-black text-slate-400 uppercase tracking-widest">No Doctors Online</p>
            </div>
          ) : (
            onlineDoctors.map((doc) => (
              <div key={doc.id} className="flex items-center gap-4 p-4 rounded-2xl bg-white border border-slate-100 hover:border-emerald-200 transition-all shadow-sm">
                <div className="relative h-12 w-12 rounded-full overflow-hidden border-2 border-white shadow-md bg-slate-50 shrink-0">
                  <Image
                    src={doc.avatar_url || `https://i.pravatar.cc/100?u=${doc.id}`}
                    alt={doc.full_name}
                    fill
                    className="object-cover"
                  />
                  <span className="absolute bottom-0 right-0 h-3 w-3 rounded-full bg-emerald-500 border-2 border-white" />
                </div>
                <div className="flex-1 min-w-0">
                  <h5 className="text-sm font-black text-slate-900 truncate leading-snug">Dr. {doc.full_name}</h5>
                  <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mt-0.5">{doc.specialty || 'General Care'}</p>
                </div>
                <Badge className="bg-emerald-50 text-emerald-600 border-emerald-100 font-black text-[9px] uppercase px-2 py-0.5 rounded-full shrink-0">
                  Active
                </Badge>
              </div>
            ))
          )}
        </CardContent>
      </Card>
    </div>
  )
}
