'use client'

import { useState, useEffect } from 'react'
import { getAdminUserDetail, createNotification } from '@/lib/queries-client'
import { logPHIAccess } from '@/lib/audit'
import { createClient } from '@/lib/supabase'
import { AdminUserDetail } from '@/lib/types'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { ScrollArea } from '@/components/ui/scroll-area'
import {
    X, User, Calendar, CreditCard, FileText, Pill,
    Loader2, HeartPulse, Stethoscope, ShieldCheck, MessageSquare
} from 'lucide-react'
import { format } from 'date-fns'

interface UserDetailDrawerProps {
    userId: string
    userName: string
    userRole: string
    requestedRole?: string
    isOpen: boolean
    onClose: () => void
}

export function UserDetailDrawer({ userId, userName, userRole, requestedRole, isOpen, onClose }: UserDetailDrawerProps) {
    const [loading, setLoading] = useState(false)
    const [detail, setDetail] = useState<AdminUserDetail | null>(null)
    const [isMessaging, setIsMessaging] = useState(false)
    const [messageTopic, setMessageTopic] = useState('Account Verification')
    const [messageContent, setMessageContent] = useState('')
    const [sendingMessage, setSendingMessage] = useState(false)
    const [adminId, setAdminId] = useState<string | null>(null)

    useEffect(() => {
        const getAdmin = async () => {
            const supabase = createClient()
            const { data: { user } } = await supabase.auth.getUser()
            if (user) setAdminId(user.id)
        }
        getAdmin()
    }, [])

    useEffect(() => {
        setIsMessaging(false)
        setMessageContent('')
        if (!isOpen || !userId) return
        setLoading(true)
        getAdminUserDetail(userId).then(data => {
            setDetail(data)
            setLoading(false)
            if (adminId) {
                logPHIAccess(adminId, userId, 'user_detail_view')
            }
        })
    }, [isOpen, userId, adminId])

    if (!isOpen) return null

    const getStatusBadge = (status: string) => {
        const map: Record<string, string> = {
            approved: 'bg-green-100 text-green-700 border-green-200',
            pending: 'bg-amber-100 text-amber-700 border-amber-200',
            rejected: 'bg-red-100 text-red-700 border-red-200',
            completed: 'bg-blue-100 text-blue-700 border-blue-200',
            confirmed: 'bg-purple-100 text-purple-700 border-purple-200',
            cancelled: 'bg-zinc-100 text-zinc-600 border-zinc-200',
        }
        return (
            <Badge variant="outline" className={`capitalize text-xs ${map[status] || 'bg-zinc-100 text-zinc-600'}`}>
                {status}
            </Badge>
        )
    }

    return (
        <div className="fixed inset-0 z-50 flex justify-end">
            {/* Backdrop */}
            <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />

            {/* Drawer Panel */}
            <div className="relative z-10 w-full max-w-2xl bg-card shadow-2xl flex flex-col h-full border-l animate-in slide-in-from-right">
                {/* Header */}
                <div className="flex items-center justify-between p-6 border-b bg-linear-to-r from-primary/10 to-background">
                    <div className="flex items-center gap-3">
                        <div className="h-12 w-12 rounded-full bg-primary/15 flex items-center justify-center">
                            {userRole === 'doctor' ? (
                                <Stethoscope className="h-6 w-6 text-primary" />
                            ) : userRole === 'admin' ? (
                                <ShieldCheck className="h-6 w-6 text-primary" />
                            ) : (
                                <User className="h-6 w-6 text-primary" />
                            )}
                        </div>
                        <div>
                            <h2 className="text-xl font-bold">{userName}</h2>
                            <div className="flex items-center gap-2 mt-0.5">
                                <Badge variant="outline" className="capitalize text-xs">
                                    {userRole}
                                </Badge>
                                {requestedRole && requestedRole !== userRole && userRole === 'patient' && (
                                    <Badge variant="secondary" className="text-[10px] bg-primary/10 text-primary border-primary/20 font-bold uppercase tracking-wider">
                                        Candidate: {requestedRole}
                                    </Badge>
                                )}
                            </div>
                        </div>
                    </div>
                    <div className="flex items-center gap-2">
                        <Button variant="outline" size="sm" onClick={() => setIsMessaging(!isMessaging)}>
                            <MessageSquare className="h-4 w-4 md:mr-2" /> <span className="hidden md:inline">Message</span>
                        </Button>
                        <Button variant="ghost" size="icon" onClick={onClose}>
                            <X className="h-5 w-5" />
                        </Button>
                    </div>
                </div>

                {isMessaging && (
                    <div className="p-4 border-b bg-muted/30 space-y-3 animate-in slide-in-from-top-2">
                        <h3 className="text-sm font-semibold">Send Notification</h3>
                        <select 
                            className="w-full text-sm p-2 rounded-md border bg-background"
                            value={messageTopic}
                            onChange={(e) => setMessageTopic(e.target.value)}
                        >
                            <option>Account Verification</option>
                            <option>Invalid ID Document</option>
                            <option>Community Guidelines Violation</option>
                            <option>Payment Issue</option>
                            <option>Other</option>
                        </select>
                        <textarea 
                            className="w-full text-sm p-2 rounded-md border bg-background min-h-[80px]"
                            placeholder={`Type message to ${userName}...`}
                            value={messageContent}
                            onChange={(e) => setMessageContent(e.target.value)}
                        />
                        <div className="flex justify-end gap-2">
                            <Button variant="ghost" size="sm" onClick={() => setIsMessaging(false)}>Cancel</Button>
                            <Button size="sm" disabled={sendingMessage || !messageContent.trim()} onClick={async () => {
                                setSendingMessage(true)
                                try {
                                    await createNotification({
                                        user_id: userId,
                                        title: messageTopic,
                                        message: messageContent,
                                        type: 'system'
                                    })
                                    setIsMessaging(false)
                                    setMessageContent('')
                                } catch (e) {
                                    console.error(e)
                                } finally {
                                    setSendingMessage(false)
                                }
                            }}>
                                {sendingMessage ? <Loader2 className="h-4 w-4 animate-spin mr-2"/> : null}
                                Send
                            </Button>
                        </div>
                    </div>
                )}

                {loading ? (
                    <div className="flex-1 flex items-center justify-center">
                        <Loader2 className="h-8 w-8 animate-spin text-primary" />
                    </div>
                ) : detail ? (
                    <Tabs defaultValue="appointments" className="flex-1 flex flex-col overflow-hidden">
                        <div className="mx-6 mt-4 overflow-x-auto no-scrollbar scroll-smooth">
                            <TabsList className="w-max flex bg-muted/50 p-1 min-w-full">
                                <TabsTrigger value="appointments" className="gap-1.5 whitespace-nowrap">
                                    <Calendar className="h-3.5 w-3.5" /> Appointments
                                    {detail.appointments.length > 0 && (
                                        <Badge className="ml-1 text-[10px] px-1.5 py-0 h-4">{detail.appointments.length}</Badge>
                                    )}
                                </TabsTrigger>
                                <TabsTrigger value="payments" className="gap-1.5 whitespace-nowrap">
                                    <CreditCard className="h-3.5 w-3.5" /> Payments
                                    {detail.payments.length > 0 && (
                                        <Badge className="ml-1 text-[10px] px-1.5 py-0 h-4">{detail.payments.length}</Badge>
                                    )}
                                </TabsTrigger>
                                {(userRole === 'patient' || userRole === 'doctor') && (
                                    <>
                                        <TabsTrigger value="medical" className="gap-1.5 whitespace-nowrap">
                                            <HeartPulse className="h-3.5 w-3.5" /> Medical
                                        </TabsTrigger>
                                        <TabsTrigger value="prescriptions" className="gap-1.5 whitespace-nowrap">
                                            <Pill className="h-3.5 w-3.5" /> Rx
                                            {detail.prescriptions.length > 0 && (
                                                <Badge className="ml-1 text-[10px] px-1.5 py-0 h-4">{detail.prescriptions.length}</Badge>
                                            )}
                                        </TabsTrigger>
                                    </>
                                )}
                            </TabsList>
                        </div>

                        <ScrollArea className="flex-1 px-6 pb-6">
                            {/* Appointments Tab */}
                            <TabsContent value="appointments" className="mt-4 space-y-3">
                                {detail.appointments.length === 0 ? (
                                    <div className="text-center py-10 text-muted-foreground text-sm">No appointments found</div>
                                ) : detail.appointments.map((apt: any) => {
                                    const doctor = (Array.isArray(apt.doctor) ? apt.doctor[0] : apt.doctor) as any
                                    const patient = (Array.isArray(apt.patient) ? apt.patient[0] : apt.patient) as any
                                    return (
                                        <div key={apt.id} className="flex items-center justify-between p-4 rounded-xl border bg-card hover:bg-accent/30 transition-colors">
                                            <div className="space-y-1">
                                                <p className="text-sm font-semibold">
                                                    {userRole === 'patient'
                                                        ? `Dr. ${doctor?.full_name || '—'}`
                                                        : patient?.full_name || '—'}
                                                </p>
                                                <p className="text-xs text-muted-foreground">
                                                    {doctor?.specialty && <span className="mr-2 text-primary">{doctor.specialty}</span>}
                                                    {apt.appointment_date ? format(new Date(apt.appointment_date), 'PPP') : '—'}
                                                </p>
                                                {apt.reason && <p className="text-xs text-muted-foreground italic">"{apt.reason}"</p>}
                                            </div>
                                            {getStatusBadge(apt.status)}
                                        </div>
                                    )
                                })}
                            </TabsContent>

                            {/* Payments Tab */}
                            <TabsContent value="payments" className="mt-4 space-y-3">
                                {detail.payments.length === 0 ? (
                                    <div className="text-center py-10 text-muted-foreground text-sm">No payments found</div>
                                ) : (
                                    <>
                                        <div className="grid grid-cols-2 gap-3 mb-4">
                                            <div className="p-3 rounded-xl border bg-green-50 dark:bg-green-950/20">
                                                <p className="text-xs text-muted-foreground">Total Approved</p>
                                                <p className="text-xl font-bold text-green-700">
                                                    ₦{detail.payments.filter((p: any) => p.status === 'approved').reduce((s: number, p: any) => s + Number(p.amount), 0).toFixed(2)}
                                                </p>
                                            </div>
                                            <div className="p-3 rounded-xl border bg-amber-50 dark:bg-amber-950/20">
                                                <p className="text-xs text-muted-foreground">Total Pending</p>
                                                <p className="text-xl font-bold text-amber-700">
                                                    ₦{detail.payments.filter((p: any) => p.status === 'pending').reduce((s: number, p: any) => s + Number(p.amount), 0).toFixed(2)}
                                                </p>
                                            </div>
                                        </div>
                                        {detail.payments.map((p: any) => (
                                            <div key={p.id} className="flex items-center justify-between p-4 rounded-xl border bg-card hover:bg-accent/30 transition-colors">
                                                <div>
                                                    <p className="text-sm font-semibold">₦{Number(p.amount).toFixed(2)}</p>
                                                    <p className="text-xs text-muted-foreground capitalize">{p.method} · {format(new Date(p.created_at), 'PP')}</p>
                                                </div>
                                                {getStatusBadge(p.status)}
                                            </div>
                                        ))}
                                    </>
                                )}
                            </TabsContent>

                            {/* Medical Profile Tab */}
                            <TabsContent value="medical" className="mt-4">
                                {!detail.medicalProfile ? (
                                    <div className="text-center py-10 text-muted-foreground text-sm">No medical profile on file</div>
                                ) : (
                                    <div className="space-y-4">
                                        <div className="p-4 rounded-xl border space-y-3">
                                            <div>
                                                <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Blood Type</p>
                                                <p className="text-sm mt-1">{detail.medicalProfile.blood_type || 'Not specified'}</p>
                                            </div>
                                            <div>
                                                <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Allergies</p>
                                                <div className="flex flex-wrap gap-1 mt-1">
                                                    {detail.medicalProfile.allergies?.length > 0
                                                        ? detail.medicalProfile.allergies.map((a: string) => (
                                                            <Badge key={a} variant="outline" className="text-rose-600 border-rose-200 bg-rose-50">{a}</Badge>
                                                        ))
                                                        : <p className="text-sm text-muted-foreground">None on file</p>}
                                                </div>
                                            </div>
                                            <div>
                                                <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Current Medications</p>
                                                <div className="flex flex-wrap gap-1 mt-1">
                                                    {detail.medicalProfile.current_medications?.length > 0
                                                        ? detail.medicalProfile.current_medications.map((m: string) => (
                                                            <Badge key={m} variant="outline" className="text-blue-600 border-blue-200 bg-blue-50">{m}</Badge>
                                                        ))
                                                        : <p className="text-sm text-muted-foreground">None on file</p>}
                                                </div>
                                            </div>
                                            <div>
                                                <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Past Medical History</p>
                                                <p className="text-sm mt-1 text-muted-foreground">{detail.medicalProfile.past_medical_history || 'None recorded'}</p>
                                            </div>
                                        </div>
                                    </div>
                                )}
                            </TabsContent>

                            {/* Prescriptions Tab */}
                            <TabsContent value="prescriptions" className="mt-4 space-y-3">
                                {detail.prescriptions.length === 0 ? (
                                    <div className="text-center py-10 text-muted-foreground text-sm">No prescriptions on file</div>
                                ) : detail.prescriptions.map((rx: any) => {
                                    const doctor = (Array.isArray(rx.doctor) ? rx.doctor[0] : rx.doctor) as any
                                    return (
                                        <div key={rx.id} className="p-4 rounded-xl border space-y-2">
                                            <div className="flex items-center justify-between">
                                                <p className="font-semibold text-sm">{rx.medication_name}</p>
                                                <p className="text-xs text-muted-foreground">{format(new Date(rx.created_at), 'PP')}</p>
                                            </div>
                                            <p className="text-xs text-muted-foreground">by Dr. {doctor?.full_name}</p>
                                            <div className="flex flex-wrap gap-2 text-xs">
                                                <span className="px-2 py-0.5 bg-primary/10 rounded-full">{rx.dosage}</span>
                                                <span className="px-2 py-0.5 bg-primary/10 rounded-full">{rx.frequency}</span>
                                                <span className="px-2 py-0.5 bg-primary/10 rounded-full">{rx.duration}</span>
                                            </div>
                                            {rx.special_instructions && (
                                                <p className="text-xs text-muted-foreground italic">Note: {rx.special_instructions}</p>
                                            )}
                                        </div>
                                    )
                                })}
                            </TabsContent>
                        </ScrollArea>
                    </Tabs>
                ) : (
                    <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm">
                        Could not load user data.
                    </div>
                )}
            </div>
        </div>
    )
}
