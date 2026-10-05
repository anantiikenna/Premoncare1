'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { getAppointments } from '@/lib/queries-client'
import { Calendar, CheckCircle2, Star, Video, Clock, Plus, Search, CalendarPlus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { ReviewForm } from '@/components/appointments/review-form'
import { MeetingRoom } from '@/components/appointments/meeting-room'
import { Dialog, DialogContent, DialogTrigger } from '@/components/ui/dialog'
import { createClient } from '@/lib/supabase'
import Link from 'next/link'
import { Badge } from '@/components/ui/badge'

export function PatientAppointmentsList({ userId }: { userId: string }) {
    const [appointments, setAppointments] = useState<any[]>([])
    const [loading, setLoading] = useState(true)
    const [selectedApt, setSelectedApt] = useState<any | null>(null)
    const [meetingApt, setMeetingApt] = useState<any | null>(null)
    const [isReviewOpen, setIsReviewOpen] = useState(false)
    const [reviewedAptIds, setReviewedAptIds] = useState<Set<string>>(new Set())
    const supabase = createClient()

    const fetchAppointments = async () => {
        const { data } = await getAppointments(userId, 'patient')
        if (data) setAppointments(data)
        
        const { data: reviews } = await supabase
            .from('reviews')
            .select('appointment_id')
            .eq('patient_id', userId)
        
        if (reviews) {
            setReviewedAptIds(new Set(reviews.map(r => r.appointment_id)))
        }
        
        setLoading(false)
    }

    useEffect(() => {
        fetchAppointments()
    }, [userId])

    // Realtime subscription for appointment changes
    useEffect(() => {
        const channel = supabase
            .channel('patient:appointments')
            .on(
                'postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'appointments',
                    filter: `patient_id=eq.${userId}`,
                },
                () => {
                    fetchAppointments()
                }
            )
            .subscribe()

        return () => {
            supabase.removeChannel(channel)
        }
    }, [userId, supabase])

    const upcomingApts = appointments.filter(a => ['pending', 'confirmed', 'rescheduled', 'ongoing', 'emergency_request', 'emergency_accepted'].includes(a.status))
    const completedApts = appointments.filter(a => a.status === 'completed')

    if (loading) {
        return (
            <div className="grid gap-6 md:grid-cols-2">
                {[1, 2].map(i => (
                    <Card key={i} className="animate-pulse h-48 rounded-[2rem] border-none bg-muted/20" />
                ))}
            </div>
        )
    }

    return (
        <div className="space-y-12 pb-20">
            {/* Upcoming Appointments */}
            <section>
                <div className="flex items-center justify-between mb-6 px-2">
                    <div className="flex items-center gap-3">
                        <div className="bg-primary/10 p-2.5 rounded-2xl">
                            <Clock className="h-5 w-5 text-primary" />
                        </div>
                        <h2 className="text-2xl font-black tracking-tight text-foreground uppercase">Upcoming</h2>
                    </div>
                </div>

                {upcomingApts.length === 0 ? (
                    <Card className="border-none bg-primary/5 rounded-[3rem] overflow-hidden group hover:shadow-2xl hover:shadow-primary/5 transition-all duration-500">
                        <CardContent className="py-20 flex flex-col items-center justify-center text-center space-y-8">
                            <div className="relative">
                                <div className="absolute inset-0 bg-primary/20 blur-3xl rounded-full animate-pulse" />
                                <div className="h-32 w-32 rounded-[2.5rem] bg-white shadow-xl flex items-center justify-center text-primary relative z-10 rotate-3 group-hover:rotate-0 transition-transform duration-500">
                                    <CalendarPlus className="h-16 w-16 opacity-80" />
                                </div>
                            </div>
                            <div className="space-y-2 max-w-sm">
                                <h3 className="font-black text-2xl tracking-tighter">No Active Consultations</h3>
                                <p className="text-muted-foreground font-bold text-sm uppercase tracking-widest leading-loose">
                                    Your schedule is clear. Book a consultation with a top specialist to start your recovery.
                                </p>
                            </div>
                            <div className="flex flex-col sm:flex-row gap-4 w-full max-w-xs">
                                <Button asChild className="h-14 rounded-2xl bg-primary hover:bg-primary/90 font-black uppercase tracking-widest text-[10px] shadow-xl shadow-primary/20">
                                    <Link href="/patient/appointments">
                                        <Plus className="h-4 w-4 mr-2" /> Book Appointment
                                    </Link>
                                </Button>
                            </div>
                        </CardContent>
                    </Card>
                ) : (
                    <div className="grid gap-6 md:grid-cols-2">
                        {upcomingApts.map((apt) => (
                            <Card key={apt.id} className="rounded-[2.5rem] border-none shadow-xl hover:shadow-2xl transition-all duration-300 overflow-hidden group">
                                <CardHeader className="p-6 pb-2">
                                    <div className="flex justify-between items-start">
                                        <div className="flex items-center gap-4">
                                            <div className="h-12 w-12 rounded-2xl bg-primary/10 flex items-center justify-center text-primary font-black">
                                                {apt.doctor.full_name.charAt(0)}
                                            </div>
                                            <div>
                                                <CardTitle className="text-lg font-black tracking-tight text-foreground">Dr. {apt.doctor.full_name}</CardTitle>
                                                <CardDescription className="text-xs font-bold uppercase tracking-widest text-primary/60">
                                                    {new Date(apt.appointment_date).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })}
                                                </CardDescription>
                                            </div>
                                        </div>
                                        <Badge className={`uppercase text-[9px] font-black tracking-widest px-3 py-1 rounded-full ${apt.status === 'confirmed' ? 'bg-green-100 text-green-700 hover:bg-green-100' : 'bg-amber-100 text-amber-700 hover:bg-amber-100'}`}>
                                            {apt.status}
                                        </Badge>
                                    </div>
                                </CardHeader>
                                <CardContent className="px-6 py-4">
                                    <p className="text-sm font-medium text-muted-foreground line-clamp-2 leading-relaxed bg-muted/30 p-4 rounded-2xl border border-dashed">
                                        {apt.reason || 'General Health Consultation and Review'}
                                    </p>
                                </CardContent>
                                <CardFooter className="p-6 pt-2">
                                    {apt.status === 'confirmed' || apt.status === 'rescheduled' || apt.status === 'ongoing' || apt.status === 'completed' || (apt.status === 'emergency_accepted' && apt.payment_status === 'completed') ? (
                                        <Button className="w-full h-12 rounded-2xl gap-3 font-black uppercase tracking-widest text-[10px] bg-primary hover:bg-primary/90 shadow-lg shadow-primary/20" onClick={() => setMeetingApt(apt)}>
                                            <Video className="h-4 w-4" /> {apt.status === 'ongoing' || apt.status === 'completed' ? 'Rejoin Meeting Room' : 'Enter Meeting Room'}
                                        </Button>
                                    ) : (
                                        <Button variant="outline" className="w-full h-12 rounded-2xl font-black uppercase tracking-widest text-[10px] border-primary/20 text-primary hover:bg-primary/5" disabled>
                                            Awaiting Confirmation
                                        </Button>
                                    )}
                                </CardFooter>
                            </Card>
                        ))}
                    </div>
                )}
            </section>

            {/* Past Appointments */}
            <section>
                <div className="flex items-center justify-between mb-6 px-2">
                    <div className="flex items-center gap-3">
                        <div className="bg-green-100 p-2.5 rounded-2xl">
                            <CheckCircle2 className="h-5 w-5 text-green-600" />
                        </div>
                        <h2 className="text-2xl font-black tracking-tight text-foreground uppercase">Medical History</h2>
                    </div>
                </div>

                {completedApts.length === 0 ? (
                    <Card className="border-none bg-slate-50 rounded-[3rem] overflow-hidden group">
                        <CardContent className="py-16 flex flex-col items-center justify-center text-center space-y-6">
                            <div className="h-20 w-20 rounded-3xl bg-white shadow-lg flex items-center justify-center text-slate-300">
                                <Search className="h-10 w-10" />
                            </div>
                            <div className="space-y-1">
                                <h3 className="font-black text-xl tracking-tight">No Past Records</h3>
                                <p className="text-muted-foreground font-bold text-xs uppercase tracking-widest">
                                    Your consultation history will appear here once completed.
                                </p>
                            </div>
                        </CardContent>
                    </Card>
                ) : (
                    <div className="grid gap-6 md:grid-cols-2">
                        {completedApts.map((apt) => {
                            const isReviewed = reviewedAptIds.has(apt.id)
                            return (
                                <Card key={apt.id} className="rounded-[2.5rem] border-none shadow-lg hover:shadow-xl transition-all duration-300 bg-card/50 overflow-hidden">
                                    <CardHeader className="p-6 pb-2">
                                        <div className="flex justify-between items-center">
                                            <div className="flex items-center gap-4">
                                                <div className="h-10 w-10 rounded-xl bg-slate-100 flex items-center justify-center text-slate-500 font-black text-sm">
                                                    {apt.doctor.full_name.charAt(0)}
                                                </div>
                                                <div>
                                                    <CardTitle className="text-base font-black tracking-tight">Dr. {apt.doctor.full_name}</CardTitle>
                                                    <CardDescription className="text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
                                                        {new Date(apt.appointment_date).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' })}
                                                    </CardDescription>
                                                </div>
                                            </div>
                                            <Badge variant="secondary" className="bg-green-50 text-green-700 border-none font-black text-[9px] uppercase tracking-widest">Completed</Badge>
                                        </div>
                                    </CardHeader>
                                    <CardFooter className="p-6 pt-4 border-t border-dashed flex justify-between items-center bg-muted/5">
                                        {isReviewed ? (
                                            <div className="flex items-center gap-2 text-[10px] text-green-600 font-black uppercase tracking-widest">
                                                <CheckCircle2 className="h-3 w-3" /> Reviewed
                                            </div>
                                        ) : (
                                            <Dialog open={isReviewOpen && selectedApt?.id === apt.id} onOpenChange={(open) => {
                                                setIsReviewOpen(open)
                                                if (!open) setSelectedApt(null)
                                            }}>
                                                <DialogTrigger render={
                                                    <Button variant="ghost" size="sm" className="h-10 px-4 rounded-xl gap-2 font-black uppercase tracking-widest text-[9px] text-primary hover:bg-primary/5" onClick={() => setSelectedApt(apt)}>
                                                        <Star className="h-3.5 w-3.5" /> Rate Doctor
                                                    </Button>
                                                } />
                                                <DialogContent className="sm:max-w-md rounded-[2.5rem] p-0 overflow-hidden border-none shadow-2xl">
                                                    <ReviewForm 
                                                        appointmentId={apt.id}
                                                        patientId={userId}
                                                        doctorId={apt.doctor_id}
                                                        doctorName={apt.doctor.full_name}
                                                        onSuccess={() => {
                                                            setIsReviewOpen(false)
                                                            fetchAppointments()
                                                        } }
                                                        onCancel={() => setIsReviewOpen(false)}
                                                    />
                                                </DialogContent>
                                            </Dialog>
                                        )}
                                        <Button variant="ghost" size="sm" className="h-10 px-4 rounded-xl font-black uppercase tracking-widest text-[9px] text-muted-foreground hover:text-primary" asChild>
                                            <Link href={`/patient/records`}>View Medical Notes</Link>
                                        </Button>
                                    </CardFooter>
                                </Card>
                            )
                        })}
                    </div>
                )}
            </section>

            {meetingApt && (
                <Dialog open={!!meetingApt} onOpenChange={(open) => !open && setMeetingApt(null)}>
                    <DialogContent className="max-w-[95vw] w-full h-[90vh] p-0 overflow-hidden border-none bg-black rounded-[2rem] shadow-2xl">
                        <MeetingRoom 
                            roomName={meetingApt.id}
                            userName={meetingApt.patient?.full_name || 'Patient'}
                            appointmentId={meetingApt.id}
                            onClose={() => setMeetingApt(null)}
                        />
                    </DialogContent>
                </Dialog>
            )}
        </div>
    )
}
