'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { toast } from 'sonner'
import { updateAppointmentStatus, createNotification, getMedicalProfile } from '@/lib/queries-client'
import { 
    Loader2, Video, Check, X, Calendar, User, Clock, FileText, 
    AlertCircle, Search, Bell, Users, Star, TrendingUp, Filter,
    ChevronLeft, ChevronRight, MoreHorizontal
} from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Textarea } from '@/components/ui/textarea'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { createClient } from '@/lib/supabase'
import { MeetingRoom } from '../appointments/meeting-room'
import { cn } from '@/lib/utils'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { getUserFacingError } from '@/lib/user-facing-errors'

export function DoctorAppointmentManager({ appointments, docId, doctorName }: { appointments: any[], docId: string, doctorName: string }) {
    const router = useRouter()
    const [processingId, setProcessingId] = useState<string | null>(null)
    const [activeMeeting, setActiveMeeting] = useState<any | null>(null)
    const [patientMedicalProfile, setPatientMedicalProfile] = useState<any | null>(null)
    const [activeTab, setActiveTab] = useState<'notes' | 'prescription'>('notes')
    const [viewTab, setViewTab] = useState<'incoming' | 'confirmed' | 'upcoming' | 'past'>('incoming')
    const [newRecord, setNewRecord] = useState('')
    const [savingRecord, setSavingRecord] = useState(false)
    const [confirmingPaymentId, setConfirmingPaymentId] = useState<string | null>(null)
    const [creditedMinutes, setCreditedMinutes] = useState(15)
    const [isCrediting, setIsCrediting] = useState(false)
    const supabase = createClient()
    
    // Prescription State
    const [prescription, setPrescription] = useState({
        medication_name: '',
        dosage: '',
        frequency: '',
        duration: '',
        special_instructions: ''
    })
    const [savingPrescription, setSavingPrescription] = useState(false)

    const todayStr = new Date().toISOString().split('T')[0]

    // Realtime subscription for appointment changes
    useEffect(() => {
        const channel = supabase
            .channel('doctor:appointments')
            .on(
                'postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'appointments',
                    filter: `doctor_id=eq.${docId}`,
                },
                () => {
                    router.refresh()
                }
            )
            .subscribe()

        return () => {
            supabase.removeChannel(channel)
        }
    }, [docId, supabase, router])

    // Stats Calculation
    const todayAppointments = appointments.filter(a => a.appointment_date.startsWith(todayStr)).sort((a, b) => new Date(a.appointment_date).getTime() - new Date(b.appointment_date).getTime())

    const stats = {
        today: appointments.filter(a => a.appointment_date.startsWith(todayStr)).length,
        upcoming: appointments.filter(a => a.status === 'confirmed' || a.status === 'rescheduled').length,
        pending: appointments.filter(a => a.status === 'pending').length,
        completed: appointments.filter(a => a.status === 'completed').length,
    }

    const filteredAppointments = appointments.filter(a => {
        if (viewTab === 'incoming') return a.status === 'pending'
        if (viewTab === 'confirmed') return a.status === 'confirmed' || a.status === 'rescheduled'
        if (viewTab === 'upcoming') return a.status === 'confirmed' || a.status === 'rescheduled'
        if (viewTab === 'past') return a.status === 'completed' || a.status === 'cancelled'
        return true
    })

    const handleConfirmPayment = async (apt: any) => {
        setIsCrediting(true)
        try {
            const { error: balanceError } = await supabase.rpc('increment_time_balance', {
                p_patient_id: apt.patient_id,
                p_doctor_id: docId,
                p_minutes: creditedMinutes
            })
            
            if (balanceError) {
                const { data: currentBalance } = await supabase
                    .from('time_balances')
                    .select('minutes_remaining')
                    .eq('patient_id', apt.patient_id)
                    .eq('doctor_id', docId)
                    .single()
                
                const newTotal = (currentBalance?.minutes_remaining || 0) + creditedMinutes
                
                const { error: upsertError } = await supabase.from('time_balances').upsert({
                    patient_id: apt.patient_id,
                    doctor_id: docId,
                    minutes_remaining: newTotal,
                    updated_at: new Date().toISOString()
                })
                if (upsertError) throw upsertError
            }

            const { error: aptError } = await updateAppointmentStatus(apt.id, { 
                status: 'confirmed'
            })
            if (aptError) throw aptError

            await createNotification({
                user_id: apt.patient_id,
                title: 'Payment Confirmed',
                message: `Payment confirmed. ${creditedMinutes} minutes added to your balance.`,
                type: 'payment',
                link: '/patient/appointments'
            })

            toast.success(`Payment confirmed! ${creditedMinutes} minutes credited.`)
            setConfirmingPaymentId(null)
            window.location.reload()
        } catch (error: unknown) {
            console.error('Payment verification failed', error)
            toast.error(getUserFacingError(error, 'We could not verify this payment. Please try again.'))
        } finally {
            setIsCrediting(false)
        }
    }

    const handleAction = async (id: string, updates: any) => {
        setProcessingId(id)
        try {
            const { error } = await updateAppointmentStatus(id, updates)
            if (error) throw error
            toast.success('Appointment updated')
            window.location.reload()
        } catch (error: unknown) {
            console.error('Appointment update failed', error)
            toast.error(getUserFacingError(error, 'We could not update this appointment. Please try again.'))
        } finally {
            setProcessingId(null)
        }
    }

    const startMeeting = async (apt: any) => {
        setActiveMeeting(apt)
        const { data } = await getMedicalProfile(apt.patient_id)
        setPatientMedicalProfile(data || null)
    }

    if (activeMeeting) {
        return (
            <div className="fixed inset-0 z-50 bg-background flex flex-col md:flex-row h-screen">
                <div className="flex-1 bg-black relative flex items-center justify-center overflow-hidden">
                    <MeetingRoom 
                        roomName={activeMeeting.id} 
                        userName={doctorName}
                        appointmentId={activeMeeting.id}
                        onClose={() => {
                            setActiveMeeting(null)
                            setPatientMedicalProfile(null)
                        }}
                    />
                </div>
                <div className="w-full md:w-[400px] border-l bg-card flex flex-col h-full overflow-hidden">
                    <div className="flex border-b flex-shrink-0">
                        <button 
                            className={`flex-1 p-4 text-sm font-black flex items-center justify-center gap-2 transition-all ${activeTab === 'notes' ? 'bg-background border-b-2 border-primary text-primary' : 'hover:bg-accent text-muted-foreground'}`}
                            onClick={() => setActiveTab('notes')}
                        >
                            <FileText className="h-4 w-4" /> Notes
                        </button>
                        <button 
                            className={`flex-1 p-4 text-sm font-black flex items-center justify-center gap-2 transition-all ${activeTab === 'prescription' ? 'bg-background border-b-2 border-primary text-primary' : 'hover:bg-accent text-muted-foreground'}`}
                            onClick={() => setActiveTab('prescription')}
                        >
                            <AlertCircle className="h-4 w-4" /> Prescription
                        </button>
                    </div>
                    <div className="flex-1 overflow-y-auto p-6 space-y-8">
                        {activeTab === 'notes' ? (
                            <>
                                <div className="space-y-4">
                                    <div className="p-5 bg-primary/5 rounded-[2rem] border border-primary/10 space-y-3">
                                        <div className="flex justify-between items-center border-b border-primary/10 pb-3">
                                            <span className="font-black text-[10px] uppercase tracking-[0.2em] text-primary/60">Patient Details</span>
                                            <Badge className="bg-primary/20 text-primary border-none font-black text-[9px] uppercase tracking-widest">
                                                Blood: {patientMedicalProfile?.blood_type || 'N/A'}
                                            </Badge>
                                        </div>
                                        <p className="font-black text-lg text-slate-900">{activeMeeting.patient.full_name}</p>
                                        <div className="pt-2">
                                            <p className="text-[9px] text-slate-400 uppercase tracking-widest font-black">Reason for visit</p>
                                            <p className="text-sm font-medium mt-1 leading-relaxed">{activeMeeting.reason}</p>
                                        </div>
                                    </div>
                                </div>
                                <div className="space-y-4">
                                    <h4 className="text-sm font-black flex items-center gap-2 text-destructive uppercase tracking-widest">
                                        <AlertCircle className="h-4 w-4" /> Allergies
                                    </h4>
                                    <div className="flex flex-wrap gap-2">
                                        {patientMedicalProfile?.allergies?.length > 0 ? (
                                            patientMedicalProfile.allergies.map((a: string, i: number) => (
                                                <Badge key={i} variant="destructive" className="rounded-xl px-3 py-1 font-black text-[10px] uppercase tracking-widest">{a}</Badge>
                                            ))
                                        ) : (
                                            <span className="text-xs font-bold text-slate-400 italic">No reported allergies</span>
                                        )}
                                    </div>
                                </div>
                                <div className="space-y-2">
                                    <Label className="font-black text-xs uppercase tracking-widest text-slate-400">Consultation Notes</Label>
                                    <Textarea
                                        className="min-h-[250px] rounded-[1.5rem] border-slate-200 focus:ring-primary/20 focus:border-primary transition-all p-4 text-sm font-medium"
                                        placeholder="Type clinical findings, diagnosis, and plan..."
                                        value={newRecord}
                                        onChange={(e) => setNewRecord(e.target.value)}
                                    />
                                </div>
                            </>
                        ) : (
                            <div className="space-y-6">
                                <div className="space-y-2">
                                    <Label className="font-black text-xs uppercase tracking-widest text-slate-400">Medication Name</Label>
                                    <Input 
                                        className="rounded-xl h-12 border-slate-200"
                                        placeholder="e.g. Paracetamol" 
                                        value={prescription.medication_name}
                                        onChange={e => setPrescription({...prescription, medication_name: e.target.value})}
                                    />
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2">
                                        <Label className="font-black text-xs uppercase tracking-widest text-slate-400">Dosage</Label>
                                        <Input 
                                            className="rounded-xl h-12 border-slate-200"
                                            placeholder="500mg" 
                                            value={prescription.dosage}
                                            onChange={e => setPrescription({...prescription, dosage: e.target.value})}
                                        />
                                    </div>
                                    <div className="space-y-2">
                                        <Label className="font-black text-xs uppercase tracking-widest text-slate-400">Frequency</Label>
                                        <Input 
                                            className="rounded-xl h-12 border-slate-200"
                                            placeholder="2x Daily" 
                                            value={prescription.frequency}
                                            onChange={e => setPrescription({...prescription, frequency: e.target.value})}
                                        />
                                    </div>
                                </div>
                                <div className="space-y-2">
                                    <Label className="font-black text-xs uppercase tracking-widest text-slate-400">Duration</Label>
                                    <Input 
                                        className="rounded-xl h-12 border-slate-200"
                                        placeholder="7 Days" 
                                        value={prescription.duration}
                                        onChange={e => setPrescription({...prescription, duration: e.target.value})}
                                    />
                                </div>
                                <div className="space-y-2">
                                    <Label className="font-black text-xs uppercase tracking-widest text-slate-400">Instructions</Label>
                                    <Textarea 
                                        className="rounded-xl border-slate-200 min-h-[100px]"
                                        placeholder="Take after meals..." 
                                        value={prescription.special_instructions}
                                        onChange={e => setPrescription({...prescription, special_instructions: e.target.value})}
                                    />
                                </div>
                            </div>
                        )}
                    </div>
                    <div className="p-6 border-t bg-slate-50/50">
                        <Button 
                            className="w-full h-12 rounded-2xl bg-primary hover:bg-primary/90 text-white font-black uppercase tracking-widest text-[10px] shadow-lg shadow-primary/20"
                            onClick={activeTab === 'notes' ? async () => {
                                if (!newRecord.trim()) return
                                setSavingRecord(true)
                                try {
                                    const { error } = await supabase.from('health_records').insert({
                                        patient_id: activeMeeting.patient_id,
                                        doctor_id: docId,
                                        content: newRecord
                                    })
                                    if (error) throw error
                                    toast.success('Record saved')
                                    setNewRecord('')
                                } catch (e: unknown) {
                                    console.error('Medical note save failed', e)
                                    toast.error(getUserFacingError(e, 'We could not save this medical note. Please try again.'))
                                } finally {
                                    setSavingRecord(false)
                                }
                            } : async () => {
                                if (!prescription.medication_name.trim()) return
                                setSavingPrescription(true)
                                try {
                                    const { error } = await supabase.from('prescriptions').insert({
                                        appointment_id: activeMeeting.id,
                                        patient_id: activeMeeting.patient_id,
                                        doctor_id: docId,
                                        ...prescription
                                    })
                                    if (error) throw error
                                    toast.success('Prescription issued')
                                    setPrescription({medication_name:'',dosage:'',frequency:'',duration:'',special_instructions:''})
                                } catch (e: unknown) {
                                    console.error('Prescription issue failed', e)
                                    toast.error(getUserFacingError(e, 'We could not issue this prescription. Please try again.'))
                                } finally {
                                    setSavingPrescription(false)
                                }
                            }}
                            disabled={savingRecord || savingPrescription}
                        >
                            {(savingRecord || savingPrescription) && <Loader2 className="h-4 w-4 animate-spin mr-2" />}
                            {activeTab === 'notes' ? 'Save Medical Note' : 'Issue Prescription'}
                        </Button>
                    </div>
                </div>
            </div>
        )
    }

    return (
        <div className="space-y-8 pb-20">
            {/* Stats Overview */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                {[
                    { label: "Today's Appointments", val: stats.today, icon: Calendar, color: "text-indigo-600", bg: "bg-indigo-50", link: "#" },
                    { label: "Upcoming Sessions", val: stats.upcoming, icon: Users, color: "text-emerald-600", bg: "bg-emerald-50", link: "#" },
                    { label: "Pending Requests", val: stats.pending, icon: Clock, color: "text-orange-600", bg: "bg-orange-50", link: "#" },
                    { label: "Completed (Month)", val: stats.completed, icon: Check, color: "text-primary", bg: "bg-primary/10", link: "#" }
                ].map((stat, i) => (
                    <Card key={i} className="rounded-[2rem] border-slate-100 shadow-xl shadow-slate-200/50 hover:scale-[1.02] transition-all cursor-pointer group">
                        <CardContent className="p-6 space-y-4">
                            <div className={cn("h-12 w-12 rounded-2xl flex items-center justify-center transition-transform group-hover:rotate-6", stat.bg, stat.color)}>
                                <stat.icon className="h-6 w-6" />
                            </div>
                            <div className="space-y-1">
                                <p className="text-[10px] font-black uppercase tracking-widest text-slate-400">{stat.label}</p>
                                <h3 className="text-3xl font-black tracking-tighter text-slate-900">{stat.val}</h3>
                            </div>
                            <div className="flex items-center text-[9px] font-black uppercase tracking-[0.2em] text-primary pt-2 group-hover:translate-x-1 transition-transform">
                                View Details <ChevronRight className="ml-1 h-3 w-3" />
                            </div>
                        </CardContent>
                    </Card>
                                ))}
                            </div>

            {/* Sub Navigation Tabs */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-200 pb-4">
                <div className="flex items-center gap-1 bg-slate-100/50 p-1 rounded-2xl overflow-x-auto no-scrollbar">
                    {[
                        { id: 'incoming', label: 'Incoming Requests', count: stats.pending },
                        { id: 'confirmed', label: 'Confirmed', count: stats.upcoming },
                        { id: 'upcoming', label: 'Upcoming', count: 0 }, // Placeholder for 'scheduled' specific
                        { id: 'past', label: 'Past', count: stats.completed }
                    ].map((tab) => (
                        <button
                            key={tab.id}
                            onClick={() => setViewTab(tab.id as any)}
                            className={cn(
                                "relative px-6 py-2.5 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all whitespace-nowrap",
                                viewTab === tab.id 
                                    ? "bg-white text-primary shadow-sm ring-1 ring-slate-200" 
                                    : "text-slate-400 hover:text-slate-600"
                            )}
                        >
                            {tab.label}
                            {tab.count > 0 && (
                                <span className="ml-2 bg-primary/10 text-primary px-1.5 py-0.5 rounded-md">
                                    {tab.count}
                                </span>
                            )}
                            {viewTab === tab.id && (
                                <div className="absolute -bottom-[17px] left-0 right-0 h-0.5 bg-primary rounded-full" />
                            )}
                        </button>
                    ))}
                </div>
                <div className="flex items-center gap-3">
                    <div className="flex items-center gap-2 bg-white px-4 py-2 rounded-xl border border-slate-200 text-[10px] font-black text-slate-600">
                        <Calendar className="h-3 w-3" /> {new Date().toLocaleDateString(undefined, { month: 'long', day: 'numeric', year: 'numeric' })}
                    </div>
                    <Button variant="outline" size="sm" className="rounded-xl h-10 border-slate-200 text-[10px] font-black uppercase tracking-widest">
                        <Filter className="h-3.5 w-3.5 mr-2" /> Filters
                    </Button>
                </div>
            </div>

            {/* Main Content Grid */}
            <div className="grid gap-8 lg:grid-cols-12">
                {/* Left Column: Requests List */}
                <div className="lg:col-span-7 space-y-6">
                    <div className="flex items-center justify-between">
                        <h3 className="text-xl font-black tracking-tight text-slate-900">
                            {viewTab === 'incoming' ? 'Incoming Appointment Requests' : 
                             viewTab === 'confirmed' ? 'Confirmed Appointments' :
                             viewTab === 'upcoming' ? 'Upcoming Sessions' : 'Past Consultations'}
                        </h3>
                        <Link href="/doctor/appointments" className="text-[10px] font-black text-primary uppercase tracking-[0.2em] hover:underline">
                            View all ({filteredAppointments.length})
                        </Link>
                    </div>

                    {filteredAppointments.length === 0 ? (
                        <Card className="rounded-[2.5rem] border-dashed border-2 border-slate-200 bg-slate-50/30">
                            <CardContent className="py-20 flex flex-col items-center justify-center text-center">
                                <div className="h-16 w-16 rounded-full bg-slate-100 flex items-center justify-center text-slate-300 mb-4">
                                    <Calendar className="h-8 w-8" />
                                </div>
                                <h4 className="font-black text-slate-400 uppercase tracking-[0.2em] text-xs">No Appointments Found</h4>
                                <p className="text-slate-400 text-[10px] mt-2 font-bold italic">Your schedule is currently clear in this category.</p>
                            </CardContent>
                        </Card>
                    ) : (
                        <div className="space-y-4">
                            {filteredAppointments.map((apt) => (
                                <Card key={apt.id} className="rounded-[2rem] border-slate-100 shadow-lg shadow-slate-200/40 hover:shadow-xl transition-all group overflow-hidden">
                                    <CardContent className="p-0">
                                        <div className="p-6 flex flex-col md:flex-row items-center gap-6">
                                            <div className="relative">
                                                <div className="h-16 w-16 rounded-[1.5rem] bg-slate-100 overflow-hidden ring-4 ring-slate-50 flex items-center justify-center">
                                                    {apt.patient?.avatar_url ? (
                                                        <img 
                                                            src={apt.patient.avatar_url} 
                                                            alt={apt.patient.full_name}
                                                            className="w-full h-full object-cover"
                                                        />
                                                    ) : (
                                                        <span className="text-lg font-black text-slate-400">{apt.patient?.full_name?.charAt(0) || '?'}</span>
                                                    )}
                                                </div>
                                                <div className="absolute -bottom-1 -right-1 h-5 w-5 rounded-full bg-emerald-500 border-2 border-white" />
                                            </div>
                                            
                                            <div className="flex-1 space-y-1 text-center md:text-left">
                                                <div className="flex flex-wrap items-center justify-center md:justify-start gap-2">
                                                    <h4 className="font-black text-lg text-slate-900">{apt.patient.full_name}</h4>
                                                    <Badge className="bg-orange-50 text-orange-600 border-none font-black text-[8px] uppercase tracking-widest px-2 py-0.5">Self-Pay</Badge>
                                                </div>
                                                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">
                                                    {apt.reason} • 29 years • Female
                                                </p>
                                                <div className="flex items-center justify-center md:justify-start gap-4 pt-2">
                                                    <div className="flex items-center gap-2 text-[10px] font-black text-slate-500">
                                                        <Calendar className="h-3 w-3 text-primary" />
                                                        {new Date(apt.appointment_date).toLocaleDateString(undefined, { month: 'long', day: 'numeric', year: 'numeric' })}
                                                    </div>
                                                    <div className="flex items-center gap-2 text-[10px] font-black text-slate-500">
                                                        <Clock className="h-3 w-3 text-primary" />
                                                        {new Date(apt.appointment_date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                    </div>
                                                </div>
                                            </div>

                                            <div className="flex flex-col md:flex-row items-center gap-2 w-full md:w-auto">
                                                {apt.status === 'pending' ? (
                                                    <>
                                                        <Button 
                                                            variant="outline" 
                                                            className="w-full md:w-24 h-10 rounded-xl border-slate-200 text-destructive font-black uppercase tracking-widest text-[9px] hover:bg-destructive/5"
                                                            onClick={() => handleAction(apt.id, { status: 'cancelled' })}
                                                            disabled={processingId === apt.id}
                                                        >
                                                            Reject
                                                        </Button>
                                                        <Dialog open={confirmingPaymentId === apt.id} onOpenChange={(open) => !open && setConfirmingPaymentId(null)}>
                                                            <DialogTrigger render={
                                                                <Button 
                                                                    className="w-full md:w-32 h-10 rounded-xl bg-primary hover:bg-primary/90 text-white font-black uppercase tracking-widest text-[9px] shadow-lg shadow-primary/20"
                                                                    onClick={() => {
                                                                        setConfirmingPaymentId(apt.id)
                                                                        setCreditedMinutes(apt.duration_minutes || 15)
                                                                    }}
                                                                >
                                                                    Accept
                                                                </Button>
                                                            } />
                                                            <DialogContent className="rounded-[2.5rem] p-0 overflow-hidden border-none shadow-2xl">
                                                                <div className="p-8 space-y-6">
                                                                    <div className="space-y-2">
                                                                        <h3 className="text-2xl font-black tracking-tighter text-slate-900">Confirm Appointment</h3>
                                                                        <p className="text-sm text-slate-500 font-medium leading-relaxed">
                                                                            Verify you have received the payment from <strong>{apt.patient.full_name}</strong>.
                                                                        </p>
                                                                    </div>
                                                                    <div className="space-y-3">
                                                                        <Label className="font-black text-[10px] uppercase tracking-widest text-slate-400">Session Duration (Minutes)</Label>
                                                                        <Select value={creditedMinutes.toString()} onValueChange={v => setCreditedMinutes(parseInt(v))}>
                                                                            <SelectTrigger className="h-12 rounded-xl border-slate-200 font-black">
                                                                                <SelectValue />
                                                                            </SelectTrigger>
                                                                            <SelectContent>
                                                                                {[15, 30, 45, 60, 90, 120].map(m => (
                                                                                    <SelectItem key={m} value={m.toString()}>{m} Minutes</SelectItem>
                                                                                ))}
                                                                            </SelectContent>
                                                                        </Select>
                                                                    </div>
                                                                    <Button 
                                                                        className="w-full h-14 bg-emerald-500 hover:bg-emerald-600 text-white rounded-2xl font-black text-lg shadow-xl shadow-emerald-500/20 transition-all active:scale-[0.98]"
                                                                        onClick={() => handleConfirmPayment(apt)}
                                                                        disabled={isCrediting}
                                                                    >
                                                                        {isCrediting ? <Loader2 className="h-5 w-5 animate-spin mr-3" /> : <Check className="h-6 w-6 mr-3" />}
                                                                        Verify & Accept
                                                                    </Button>
                                                                </div>
                                                            </DialogContent>
                                                        </Dialog>
                                                    </>
                                                ) : apt.status === 'confirmed' || apt.status === 'rescheduled' || apt.status === 'ongoing' || apt.status === 'completed' || (apt.status === 'emergency_accepted' && apt.payment_status === 'completed') ? (
                                                    <Button 
                                                        className="w-full md:w-40 h-10 rounded-xl bg-primary hover:bg-primary/90 text-white font-black uppercase tracking-widest text-[9px] shadow-lg shadow-primary/20"
                                                        onClick={() => startMeeting(apt)}
                                                    >
                                                        <Video className="h-4 w-4 mr-2" /> {apt.status === 'ongoing' || apt.status === 'completed' ? 'Rejoin Meeting' : 'Start Meeting'}
                                                    </Button>
                                                ) : (
                                                    <Badge className="bg-slate-100 text-slate-400 border-none font-black text-[9px] uppercase tracking-widest px-4 py-2">
                                                        {apt.status}
                                                    </Badge>
                                                )}
                                            </div>
                                        </div>
                                    </CardContent>
                                </Card>
                            ))}
                            <Button variant="ghost" className="w-full h-12 rounded-2xl bg-primary/5 text-primary font-black uppercase tracking-widest text-[10px] hover:bg-primary/10" onClick={() => router.push('/doctor/appointments')}>
                                View All Requests
                            </Button>
                        </div>
                    )}
                </div>

                {/* Right Column: Schedule & Overview */}
                <div className="lg:col-span-5 space-y-8">
                    {/* Today's Schedule Timeline */}
                    <Card className="rounded-[3rem] border-slate-100 shadow-2xl shadow-slate-200/40 overflow-hidden">
                        <CardHeader className="bg-slate-50/50 border-b border-dashed p-8">
                            <div className="flex items-center justify-between">
                                <CardTitle className="text-xl font-black tracking-tight text-slate-900">Today&apos;s Schedule</CardTitle>
                                <span className="text-[10px] font-black text-primary bg-primary/10 px-2 py-1 rounded-md uppercase tracking-widest">{stats.today} Appointments</span>
                            </div>
                        </CardHeader>
                        <CardContent className="p-8">
                            <div className="space-y-0 relative">
                                {/* Vertical Line */}
                                <div className="absolute left-[70px] top-4 bottom-4 w-0.5 bg-slate-100" />
                                
                                {(todayAppointments.length > 0 ? todayAppointments : []).map((apt, idx) => {
                                    const aptDate = new Date(apt.appointment_date)
                                    const item = {
                                        time: aptDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
                                        user: apt.patient?.full_name || 'Patient',
                                        type: apt.reason || 'Consultation',
                                        status: apt.status === 'confirmed' ? 'confirmed' : apt.status === 'rescheduled' ? 'rescheduled' : apt.status === 'pending' ? 'upcoming' : apt.status,
                                        current: false,
                                        label: apt.reason || 'Consultation'
                                    }
                                    return (
                                    <div key={idx} className="flex gap-6 min-h-[80px]">
                                        <div className="w-[70px] pt-1 text-[10px] font-black text-slate-400 uppercase tracking-tighter">
                                            {item.time}
                                        </div>
                                        <div className="relative flex-1 pb-8">
                                            {/* Dot */}
                                            <div className={cn(
                                                "absolute -left-[11px] top-2 h-4 w-4 rounded-full border-4 border-white shadow-sm transition-transform hover:scale-125 z-10",
                                                item.current ? "bg-emerald-500 scale-125 ring-4 ring-emerald-500/20" : 
                                                item.status === 'upcoming' ? "bg-primary" : 
                                                item.status === 'break' ? "bg-orange-400" : "bg-slate-200"
                                            )} />
                                            
                                            {item.user ? (
                                                <div className={cn(
                                                    "rounded-2xl p-4 border transition-all hover:shadow-md cursor-pointer",
                                                    item.current ? "bg-emerald-50/50 border-emerald-100" : "bg-white border-slate-100"
                                                )}>
                                                    <div className="flex items-center justify-between gap-4">
                                                        <div className="flex items-center gap-3">
                                                            <div className="h-8 w-8 rounded-xl bg-slate-100 overflow-hidden flex items-center justify-center text-xs font-bold text-slate-400">
                                                                {(item.user || '?').charAt(0).toUpperCase()}
                                                            </div>
                                                            <div>
                                                                <p className="text-xs font-black text-slate-900 leading-none">{item.user}</p>
                                                                <p className="text-[9px] font-bold text-slate-400 uppercase tracking-widest mt-1">{item.type}</p>
                                                            </div>
                                                        </div>
                                                        {item.current && <Video className="h-4 w-4 text-emerald-500" />}
                                                    </div>
                                                    <div className="flex items-center justify-between mt-3">
                                                        <Badge className={cn(
                                                            "text-[8px] font-black uppercase tracking-widest px-2 py-0.5 border-none",
                                                            item.current ? "bg-emerald-100 text-emerald-700" : "bg-primary/10 text-primary"
                                                        )}>
                                                            {item.status}
                                                        </Badge>
                                                    </div>
                                                </div>
                                            ) : (
                                                <div className={cn(
                                                    "rounded-2xl p-4 border border-dashed flex items-center justify-between",
                                                    item.status === 'break' ? "bg-orange-50/30 border-orange-100 text-orange-600" : "bg-slate-50/30 border-slate-100 text-slate-400"
                                                )}>
                                                    <div className="flex items-center gap-3">
                                                        <Clock className="h-4 w-4" />
                                                        <span className="text-[10px] font-black uppercase tracking-widest">{item.label}</span>
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                    )
                                })}
                            </div>
                        </CardContent>
                    </Card>

                    {/* Schedule Overview Donut */}
                    <Card className="rounded-[3rem] border-slate-100 shadow-2xl shadow-slate-200/40">
                        <CardHeader className="p-8 pb-0">
                            <div className="flex items-center justify-between">
                                <CardTitle className="text-xl font-black tracking-tight text-slate-900">Schedule Overview</CardTitle>
                                <Link href="/doctor/schedule" className="text-[10px] font-black text-primary uppercase tracking-[0.2em] hover:underline">Full Calendar</Link>
                            </div>
                        </CardHeader>
                        <CardContent className="p-8 flex items-center gap-8">
                            {/* SVG Donut Chart */}
                            <div className="relative h-32 w-32 shrink-0">
                                {(() => {
                                    const total = stats.completed + stats.upcoming + stats.pending || 1
                                    const completedPct = Math.round((stats.completed / total) * 100)
                                    const upcomingPct = Math.round((stats.upcoming / total) * 100)
                                    const pendingPct = Math.round((stats.pending / total) * 100)
                                    return (
                                        <svg viewBox="0 0 36 36" className="h-full w-full -rotate-90">
                                            <circle cx="18" cy="18" r="16" fill="transparent" stroke="#f1f5f9" strokeWidth="3.5" />
                                            <circle cx="18" cy="18" r="16" fill="transparent" stroke="#10b981" strokeWidth="3.5" strokeDasharray={`${completedPct} 100`} strokeDashoffset="0" strokeLinecap="round" />
                                            <circle cx="18" cy="18" r="16" fill="transparent" stroke="#6366f1" strokeWidth="3.5" strokeDasharray={`${upcomingPct} 100`} strokeDashoffset={`-${completedPct}`} strokeLinecap="round" />
                                            <circle cx="18" cy="18" r="16" fill="transparent" stroke="#f59e0b" strokeWidth="3.5" strokeDasharray={`${pendingPct} 100`} strokeDashoffset={`-${completedPct + upcomingPct}`} strokeLinecap="round" />
                                        </svg>
                                    )
                                })()}
                                <div className="absolute inset-0 flex flex-col items-center justify-center">
                                    <span className="text-2xl font-black text-slate-900 leading-none">{stats.completed + stats.upcoming + stats.pending}</span>
                                    <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest mt-1">Total</span>
                                </div>
                            </div>
                            
                            <div className="flex-1 space-y-3">
                                {(() => {
                                    const total = stats.completed + stats.upcoming + stats.pending || 1
                                    return [
                                        { label: "Completed", val: `${stats.completed} (${Math.round((stats.completed / total) * 100)}%)`, color: "bg-emerald-500" },
                                        { label: "Upcoming", val: `${stats.upcoming} (${Math.round((stats.upcoming / total) * 100)}%)`, color: "bg-primary" },
                                        { label: "Pending", val: `${stats.pending} (${Math.round((stats.pending / total) * 100)}%)`, color: "bg-orange-500" }
                                    ]
                                })().map((row, i) => (
                                    <div key={i} className="flex items-center justify-between">
                                        <div className="flex items-center gap-2">
                                            <div className={cn("h-2 w-2 rounded-full", row.color)} />
                                            <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">{row.label}</span>
                                        </div>
                                        <span className="text-[10px] font-black text-slate-900">{row.val}</span>
                                    </div>
                                ))}
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    )
}
