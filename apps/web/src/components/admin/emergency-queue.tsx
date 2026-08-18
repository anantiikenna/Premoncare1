'use client'

import { useState, useEffect, useCallback } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { cn } from '@/lib/utils'
import {
    Loader2, ShieldAlert, Zap, Clock,
    User, Stethoscope, ArrowUpRight, TrendingUp,
    CheckCircle2, Activity, Radio, RefreshCw
} from 'lucide-react'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Profile, AdminAppointment } from '@/lib/types'

export function EmergencyQueue() {
    const [loading, setLoading] = useState(true)
    const [requests, setRequests] = useState<(AdminAppointment & { priority?: string; profiles?: Profile })[]>([])
    const [availableDoctors, setAvailableDoctors] = useState<Profile[]>([])
    const [assigningId, setAssigningId] = useState<string | null>(null)
    const [resolvedToday, setResolvedToday] = useState(0)
    const [activeTab, setActiveTab] = useState('All')
    const supabase = createClient()

    const fetchQueue = useCallback(async () => {
        const { data, error } = await supabase
            .from('appointments')
            .select('*, profiles!appointments_patient_id_fkey(full_name, avatar_url, dob, gender), doctor:profiles!appointments_doctor_id_fkey(full_name, avatar_url)')
            .eq('is_emergency', true)
            .not('status', 'eq', 'completed')
            .order('created_at', { ascending: false })

        if (data) setRequests(data)

        const todayStart = new Date()
        todayStart.setHours(0, 0, 0, 0)
        const { count } = await supabase
            .from('appointments')
            .select('*', { count: 'exact', head: true })
            .eq('is_emergency', true)
            .eq('status', 'completed')
            .gte('created_at', todayStart.toISOString())

        if (count !== null) setResolvedToday(count)
    }, [supabase])

    const fetchDoctors = useCallback(async () => {
        const { data } = await supabase
            .from('profiles')
            .select('*')
            .eq('role', 'doctor')
            .eq('is_online', true)

        if (data) setAvailableDoctors(data)
    }, [supabase])

    useEffect(() => {
        Promise.all([fetchQueue(), fetchDoctors()]).then(() => setLoading(false))

        const channel = supabase.channel('admin:emergency:ops', {
                config: { private: true },
            })
            .on(
                'postgres_changes',
                { event: '*', schema: 'public', table: 'appointments', filter: 'is_emergency=eq.true' },
                () => {
                    fetchQueue()
                }
            )
            .subscribe()

        return () => { supabase.removeChannel(channel) }
    }, [supabase, fetchQueue, fetchDoctors])

    const handleAssignDoctor = async (requestId: string, doctorId: string) => {
        setAssigningId(requestId)
        try {
            const { error } = await supabase
                .from('appointments')
                .update({
                    doctor_id: doctorId,
                    status: 'confirmed'
                })
                .eq('id', requestId)

            if (error) throw error
            toast.success('Doctor assigned to emergency request')
            fetchQueue()
        } catch (error: any) {
            toast.error(error.message || 'Failed to assign doctor')
        } finally {
            setAssigningId(null)
        }
    }

    const handleAutoAssign = async (requestId: string) => {
        if (availableDoctors.length === 0) {
            toast.error('No doctors currently online to assign')
            return
        }
        setAssigningId(requestId)
        try {
            const doctor = availableDoctors[0]
            const { error } = await supabase
                .from('appointments')
                .update({
                    doctor_id: doctor.id,
                    status: 'confirmed'
                })
                .eq('id', requestId)

            if (error) throw error
            toast.success(`Assigned to Dr. ${doctor.full_name}`)
            fetchQueue()
        } catch (error: any) {
            toast.error(error.message || 'Failed to auto-assign doctor')
        } finally {
            setAssigningId(null)
        }
    }

    const filteredRequests = requests.filter(r => {
        if (activeTab === 'All') return true
        if (activeTab === 'Waiting') return !r.doctor_id
        if (activeTab === 'In Progress') return r.status === 'ongoing'
        return true
    })

    return (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
            <div className="lg:col-span-8 space-y-8">
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <StatCard label="Active Emergencies" value={requests.length} icon={ShieldAlert} color="text-rose-600" bg="bg-rose-50" trend="Needs Attention" />
                    <StatCard label="Waiting for Doctor" value={requests.filter(r => !r.doctor_id).length} icon={Clock} color="text-amber-600" bg="bg-amber-50" trend={`${requests.filter(r => !r.doctor_id).length} pending`} />
                    <StatCard label="In Consultation" value={requests.filter(r => r.status === 'ongoing').length} icon={Activity} color="text-emerald-600" bg="bg-emerald-50" trend="Active calls" />
                    <StatCard label="Resolved Today" value={resolvedToday} icon={CheckCircle2} color="text-blue-600" bg="bg-blue-50" trend="Completed" />
                </div>

                <div className="flex items-center gap-2 overflow-x-auto pb-2 no-scrollbar">
                    <QueueTab label="All" count={requests.length} active={activeTab === 'All'} onClick={() => setActiveTab('All')} />
                    <QueueTab label="Waiting" count={requests.filter(r => !r.doctor_id).length} active={activeTab === 'Waiting'} onClick={() => setActiveTab('Waiting')} />
                    <QueueTab label="In Progress" count={requests.filter(r => r.status === 'ongoing').length} active={activeTab === 'In Progress'} onClick={() => setActiveTab('In Progress')} />
                </div>

                <div className="space-y-4">
                    {filteredRequests.length === 0 ? (
                        <div className="bg-white rounded-[2.5rem] border-2 border-dashed p-20 text-center">
                            <div className="bg-emerald-50 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-4">
                                <CheckCircle2 className="h-10 w-10 text-emerald-500" />
                            </div>
                            <h3 className="text-xl font-black text-slate-900">Queue is Clear</h3>
                            <p className="text-slate-500 font-medium">All emergency requests are currently being handled.</p>
                        </div>
                    ) : (
                        filteredRequests.map((req, idx) => (
                            <EmergencyRequestCard
                                key={req.id}
                                request={req}
                                index={idx + 1}
                                isAssigning={assigningId === req.id}
                                onAssign={() => handleAutoAssign(req.id)}
                                availableDoctors={availableDoctors}
                                onAssignSpecific={(doctorId) => handleAssignDoctor(req.id, doctorId)}
                            />
                        ))
                    )}
                </div>
            </div>

            <div className="lg:col-span-4 space-y-8">
                <Card className="rounded-[2.5rem] border-none shadow-xl bg-slate-900 text-white overflow-hidden">
                    <CardHeader className="p-8 pb-4">
                        <div className="flex justify-between items-center">
                            <CardTitle className="text-xl font-black tracking-tight">Available Doctors</CardTitle>
                            <Badge variant="outline" className="bg-emerald-500/10 text-emerald-400 border-none text-[10px]">{availableDoctors.length} online</Badge>
                        </div>
                    </CardHeader>
                    <CardContent className="p-8 pt-4">
                        <ScrollArea className="h-[400px] pr-4">
                            <div className="space-y-6">
                                {availableDoctors.length === 0 ? (
                                    <p className="text-slate-400 text-center py-10">No doctors currently online.</p>
                                ) : (
                                    availableDoctors.map((doc) => (
                                        <div key={doc.id} className="flex items-center justify-between group">
                                            <div className="flex items-center gap-4">
                                                <div className="relative">
                                                    <Avatar className="h-12 w-12 border-2 border-slate-800">
                                                        <AvatarImage src={doc.avatar_url} />
                                                        <AvatarFallback>{doc.full_name?.charAt(0)}</AvatarFallback>
                                                    </Avatar>
                                                    <div className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 rounded-full border-2 border-slate-900" />
                                                </div>
                                                <div>
                                                    <p className="font-bold text-sm">{doc.full_name}</p>
                                                    <p className="text-[10px] font-black uppercase text-slate-500 tracking-wider">{doc.specialty || 'General Physician'}</p>
                                                    <Badge variant="outline" className="bg-emerald-500/10 text-emerald-400 border-none text-[8px] mt-1">Available</Badge>
                                                </div>
                                            </div>
                                        </div>
                                    ))
                                )}
                            </div>
                        </ScrollArea>
                    </CardContent>
                </Card>

                <Card className="rounded-[2.5rem] border shadow-xl bg-white p-8 space-y-6">
                    <h3 className="text-lg font-black tracking-tight">Queue Analytics</h3>
                    <div className="space-y-4">
                        <div className="flex items-center justify-between">
                            <span className="text-xs font-bold text-slate-500 uppercase tracking-widest">Priority Breakdown</span>
                            <span className="text-xs font-black text-rose-600">
                                CRITICAL: {requests.length > 0 ? Math.round((requests.filter(r => r.priority === 'Critical').length / requests.length) * 100) : 0}%
                            </span>
                        </div>
                        <div className="h-3 w-full bg-slate-100 rounded-full overflow-hidden flex">
                            <div className="h-full bg-rose-500" style={{ width: `${requests.length > 0 ? (requests.filter(r => r.priority === 'Critical').length / requests.length) * 100 : 0}%` }} />
                            <div className="h-full bg-amber-500" style={{ width: `${requests.length > 0 ? (requests.filter(r => r.priority === 'High').length / requests.length) * 100 : 0}%` }} />
                            <div className="h-full bg-blue-500" style={{ width: `${requests.length > 0 ? (requests.filter(r => r.priority === 'Medium').length / requests.length) * 100 : 0}%` }} />
                        </div>
                        <div className="grid grid-cols-2 gap-4 pt-4 border-t">
                            <div className="text-center">
                                <p className="text-[10px] font-black text-slate-400 uppercase">Total Today</p>
                                <p className="text-2xl font-black text-slate-900 mt-1">{resolvedToday + requests.length}</p>
                            </div>
                            <div className="text-center">
                                <p className="text-[10px] font-black text-slate-400 uppercase">Online Doctors</p>
                                <p className="text-2xl font-black text-slate-900 mt-1">{availableDoctors.length}</p>
                            </div>
                        </div>
                    </div>
                </Card>

                <div className="grid grid-cols-2 gap-4">
                    <QuickAction icon={Radio} label="Broadcast Alert" color="text-rose-600" bg="bg-rose-50" onClick={async () => {
                        const supabase = createClient()
                        const { data: { user } } = await supabase.auth.getUser()
                        if (!user) return
                        const { data: onlineDoctors } = await supabase
                            .from('profiles')
                            .select('id')
                            .eq('role', 'doctor')
                            .eq('is_online', true)
                        if (onlineDoctors && onlineDoctors.length > 0) {
                            try {
                                for (const doc of onlineDoctors) {
                                    await fetch('/api/notifications/dispatch', {
                                        method: 'POST',
                                        headers: { 'Content-Type': 'application/json' },
                                        body: JSON.stringify({
                                            user_id: doc.id,
                                            title: 'Emergency Broadcast Alert',
                                            message: 'A new emergency broadcast has been issued. Please check the emergency queue immediately.',
                                            type: 'system',
                                        })
                                    })
                                }
                                toast.success(`Broadcast sent to ${onlineDoctors.length} online doctor(s)`)
                            } catch {
                                toast.error('Failed to send broadcast. Please try again.')
                            }
                        } else {
                            toast.info('No online doctors to broadcast to')
                        }
                    }} />
                    <QuickAction icon={ArrowUpRight} label="Escalate Case" color="text-amber-600" bg="bg-amber-50" onClick={async () => {
                        const supabase = createClient()
                        const waiting = requests.find(r => !r.doctor_id && r.status === 'emergency_request')
                        if (!waiting) { toast.info('No waiting emergencies to escalate'); return }
                        const { error } = await supabase
                            .from('appointments')
                            .update({ priority: 'Critical' })
                            .eq('id', waiting.id)
                        if (!error) { toast.success('Emergency escalated to Critical priority'); fetchQueue() }
                    }} />
                    <QuickAction icon={RefreshCw} label="Reassign Doctor" color="text-blue-600" bg="bg-blue-50" onClick={async () => {
                        const supabase = createClient()
                        const ongoing = requests.find(r => r.doctor_id && r.status === 'ongoing')
                        if (!ongoing) { toast.info('No ongoing consultations to reassign'); return }
                        if (availableDoctors.length === 0) { toast.info('No online doctors available for reassignment'); return }
                        const nextDoctor = availableDoctors.find(d => d.id !== ongoing.doctor_id)
                        if (!nextDoctor) { toast.info('No other doctors available'); return }
                        const { error } = await supabase
                            .from('appointments')
                            .update({ doctor_id: nextDoctor.id })
                            .eq('id', ongoing.id)
                        if (!error) { toast.success(`Reassigned to ${nextDoctor.full_name}`); fetchQueue() }
                    }} />
                    <QuickAction icon={CheckCircle2} label="End Emergency" color="text-emerald-600" bg="bg-emerald-50" onClick={async () => {
                        const supabase = createClient()
                        const ongoing = requests.find(r => r.status === 'ongoing')
                        if (!ongoing) { toast.info('No ongoing consultations to end'); return }
                        const { error } = await supabase
                            .from('appointments')
                            .update({ status: 'completed' })
                            .eq('id', ongoing.id)
                        if (!error) { toast.success('Emergency consultation ended'); fetchQueue() }
                    }} />
                </div>
            </div>
        </div>
    )
}

function EmergencyRequestCard({ request, index, isAssigning, onAssign, availableDoctors, onAssignSpecific }: {
    request: any, index: number, isAssigning: boolean, onAssign: () => void, availableDoctors: any[], onAssignSpecific: (doctorId: string) => void
}) {
    const [showDoctorPicker, setShowDoctorPicker] = useState(false)
    const priority = request.priority || 'High'
    const colorClass = priority === 'Critical' ? 'border-rose-500 text-rose-500' :
                      priority === 'High' ? 'border-amber-500 text-amber-500' :
                      'border-blue-500 text-blue-500'

    const createdDate = new Date(request.created_at)
    const waitMinutes = Math.floor((Date.now() - createdDate.getTime()) / 60000)
    const waitDisplay = waitMinutes >= 60
        ? `${Math.floor(waitMinutes / 60)}h ${waitMinutes % 60}m`
        : `${waitMinutes}:${String(Math.floor((Date.now() - createdDate.getTime()) / 1000 % 60)).padStart(2, '0')}`

    return (
        <div className={`bg-white rounded-[2rem] border-l-8 ${colorClass.split(' ')[0]} shadow-sm p-6 flex flex-col md:flex-row items-center justify-between gap-6 group hover:shadow-xl transition-all`}>
            <div className="flex items-center gap-6 flex-1">
                <span className="text-4xl font-black text-slate-100 group-hover:text-slate-200 transition-colors">
                    {index.toString().padStart(2, '0')}
                </span>
                <div className="space-y-2">
                    <div className="flex items-center gap-2">
                        <Badge variant="outline" className={`${colorClass} font-black text-[10px] uppercase tracking-widest`}>{priority}</Badge>
                        <span className="text-xs font-bold text-slate-400 uppercase tracking-widest">• Waiting: {waitDisplay}</span>
                    </div>
                    <h4 className="text-lg font-black text-slate-900 leading-tight">
                        {request.metadata?.emergency_symptoms || 'Emergency Consultation'}
                    </h4>
                    <div className="flex items-center gap-4 text-xs font-medium text-slate-500">
                        <span className="flex items-center gap-1"><User className="h-3 w-3" /> {request.profiles?.full_name || 'Unknown Patient'}</span>
                    </div>
                </div>
            </div>

            <div className="flex items-center gap-4">
                <div className="text-right hidden md:block">
                    <p className="text-[10px] font-black uppercase text-slate-400 mb-1">Doctor Status</p>
                    {request.doctor ? (
                        <div className="flex items-center gap-2">
                            <span className="text-xs font-bold text-slate-900">{request.doctor.full_name}</span>
                            <Avatar className="h-8 w-8">
                                <AvatarImage src={request.doctor.avatar_url} />
                                <AvatarFallback>D</AvatarFallback>
                            </Avatar>
                        </div>
                    ) : (
                        <p className="text-xs font-black text-rose-500 animate-pulse">NO DOCTOR ASSIGNED</p>
                    )}
                </div>
                <div className="relative">
                    <Button
                        onClick={onAssign}
                        disabled={isAssigning || !!request.doctor_id}
                        className="rounded-xl h-14 px-8 font-black bg-slate-50 hover:bg-slate-100 text-slate-900 border border-slate-200 gap-2 disabled:opacity-50"
                    >
                        {isAssigning ? (
                            <Loader2 className="h-4 w-4 animate-spin" />
                        ) : (
                            <Stethoscope className="h-4 w-4" />
                        )}
                        {request.doctor_id ? 'Assigned' : 'Assign'}
                    </Button>
                </div>
            </div>
        </div>
    )
}

function StatCard({ label, value, icon: Icon, color, bg, trend }: { label: string, value: number, icon: any, color: string, bg: string, trend: string }) {
    return (
        <div className="bg-white p-6 rounded-[2rem] border shadow-sm group hover:shadow-xl transition-all duration-500">
            <div className={cn("p-3 rounded-2xl w-fit mb-4 transition-transform group-hover:scale-110", bg)}>
                <Icon className={cn("h-6 w-6", color)} />
            </div>
            <div>
                <p className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-400">{label}</p>
                <div className="flex items-end gap-3 mt-1">
                    <h3 className="text-3xl font-black text-slate-900">{value}</h3>
                    <span className={cn("text-[10px] font-black uppercase tracking-widest mb-1.5", color)}>{trend}</span>
                </div>
            </div>
        </div>
    )
}

function QueueTab({ label, count, active = false, onClick }: { label: string, count: number, active?: boolean; onClick?: () => void }) {
    return (
        <button onClick={onClick} className={cn(
            "flex items-center gap-2 px-6 py-3 rounded-2xl font-black text-xs uppercase tracking-widest whitespace-nowrap transition-all cursor-pointer",
            active ? "bg-slate-900 text-white shadow-lg" : "bg-white text-slate-500 hover:bg-slate-50"
        )}>
            {label}
            <span className={cn(
                "px-2 py-0.5 rounded-lg text-[10px]",
                active ? "bg-white/20" : "bg-slate-100"
            )}>{count}</span>
        </button>
    )
}

function QuickAction({ icon: Icon, label, color, bg, onClick }: { icon: any, label: string, color: string, bg: string; onClick?: () => void }) {
    return (
        <button onClick={onClick} className="bg-white p-5 rounded-[2rem] border shadow-sm hover:shadow-xl transition-all flex flex-col items-center gap-3 text-center group cursor-pointer">
            <div className={cn("p-3 rounded-2xl transition-transform group-hover:rotate-12", bg)}>
                <Icon className={cn("h-5 w-5", color)} />
            </div>
            <span className="text-[10px] font-black uppercase tracking-widest text-slate-600">{label}</span>
        </button>
    )
}
