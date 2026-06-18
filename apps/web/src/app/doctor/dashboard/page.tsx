import { createClient } from '@/lib/supabase-server'
import { getAppointments, getProfile } from '@/lib/queries'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { 
    Calendar, Users, Star, Lock, ShieldAlert, TrendingUp, 
    Video, ArrowUpRight, Bell, Search,
    CheckCircle2, Clock, FileText,
    CheckCircle, MessageSquare, Receipt, History,
    Stethoscope, Activity, Zap
} from 'lucide-react'
import { DoctorStatusGuard } from '@/components/doctor/status-guard'
import { PaymentVerification } from '@/components/doctor/payment-verification'
import { DoctorMedicalRecords } from '@/components/doctor/doctor-medical-records'
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { ProposeFollowupDialog } from '@/components/doctor/propose-followup-dialog'
import { Badge } from '@/components/ui/badge'
import { OnlineToggle } from '@/components/doctor/online-toggle'
import { ExportButton } from '@/components/doctor/export-button'

export default async function DoctorDashboard() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return null

    const { data: profile } = await getProfile(user.id)
    const { data: appointments } = await getAppointments(user.id, 'doctor')
    const { data: reviews } = await supabase.from('reviews').select('rating').eq('doctor_id', user.id)
    
    const averageRating = reviews && reviews.length > 0 
        ? (reviews.reduce((acc, rev) => acc + rev.rating, 0) / reviews.length).toFixed(1)
        : '—'

    // Real unread notification count
    const { count: unreadCount } = await supabase
        .from('notifications')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', user.id)
        .eq('is_read', false)

    // Real pending payment count
    const { count: pendingPaymentsCount } = await supabase
        .from('payments')
        .select('*', { count: 'exact', head: true })
        .eq('recipient_id', user.id)
        .eq('status', 'pending')

    // Fetch all payments for this doctor to compute revenue
    const { data: payments } = await supabase
        .from('payments')
        .select('amount, status, created_at')
        .eq('recipient_id', user.id)

    const approvedPayments = payments?.filter(p => p.status === 'approved' || p.status === 'completed') || []

    const totalEarnings = approvedPayments
        .reduce((sum, p) => sum + (Number(p.amount) || 0), 0)

    const now = new Date()
    const thisMonthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString()
    const sessionEarnings = approvedPayments
        .filter(p => p.created_at >= thisMonthStart)
        .reduce((sum, p) => sum + (Number(p.amount) || 0), 0)

    const today = new Date().toISOString().split('T')[0]
    const todaysAppointments = appointments?.filter(a => a.appointment_date.startsWith(today)) || []
    const completedToday = todaysAppointments.filter(a => a.status === 'completed').length
    const totalToday = todaysAppointments.length

    const expectedRevenue = todaysAppointments.length > 0
        ? todaysAppointments.reduce((sum, a) => sum + (Number(profile?.consultation_fee) || 0), 0)
        : 0

    const taskCompletion = totalToday > 0 ? Math.round((completedToday / totalToday) * 100) : null

    const stats = {
        totalEarnings: totalEarnings.toLocaleString('en-NG', { minimumFractionDigits: 2, maximumFractionDigits: 2 }),
        sessionEarnings: sessionEarnings.toLocaleString('en-NG', { minimumFractionDigits: 2, maximumFractionDigits: 2 }),
        activePatients: (appointments?.map(a => a.patient_id).filter((v,i,arr) => arr.indexOf(v) === i) || []).length,
        pendingVerifications: pendingPaymentsCount ?? 0,
        upcomingSessions: todaysAppointments.filter(a => a.status === 'scheduled' || a.status === 'confirmed').length,
        consultationRate: profile?.consultation_fee ? `₦${Number(profile.consultation_fee).toLocaleString()}` : '₦15,000',
        expectedRevenue,
        taskCompletion
    }

    return (
        <div className="space-y-12 pb-24 animate-in-fade relative overflow-hidden">
            {/* Background Decorative Mesh */}
            <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-primary/5 rounded-full blur-[100px] -z-10 pointer-events-none" />

            {/* Header Area */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-8">
                <div className="space-y-1">
                    <div className="flex items-center gap-3">
                        <h1 className="text-4xl font-black tracking-tighter text-slate-900">
                            Dr. {profile?.full_name?.split(' ')[0] || 'Professional'}
                        </h1>
                        <Badge className="bg-primary text-white border-none rounded-full px-3 py-1 text-[10px] font-black tracking-widest uppercase">Clinical Portal</Badge>
                    </div>
                    <p className="text-slate-500 font-medium">Monitoring practice health and patient activity for {new Date().toLocaleDateString(undefined, { month: 'long', year: 'numeric' })}.</p>
                </div>
                <div className="flex items-center gap-4">
                    <OnlineToggle initialStatus={profile?.is_online || false} profileId={profile?.id || ''} />
                    <div className="flex items-center gap-3">
                        <Button variant="outline" size="icon" className="rounded-2xl border-slate-200 shadow-sm h-11 w-11" asChild>
                            <Link href="/doctor/patients">
                                <Search className="h-4 w-4 text-slate-500" />
                            </Link>
                        </Button>
                        <div className="relative">
                            <Button variant="outline" size="icon" className="rounded-2xl border-slate-200 shadow-sm h-11 w-11" asChild>
                                <Link href="/doctor/notifications">
                                    <Bell className="h-4 w-4 text-slate-500" />
                                </Link>
                            </Button>
                            {(unreadCount ?? 0) > 0 && (
                                <span className="absolute -top-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[8px] font-black text-white ring-2 ring-white">
                                    {(unreadCount ?? 0) > 9 ? '9+' : unreadCount}
                                </span>
                            )}
                        </div>
                    </div>
                </div>
            </div>

            <DoctorStatusGuard profile={profile}>
                <div className="grid gap-8 lg:grid-cols-12">
                    {/* Primary Workflow Column */}
                    <div className="lg:col-span-8 space-y-10">
                        
                        {/* Immersive Earnings & Stats Card */}
                        <div className="relative overflow-hidden rounded-[3.5rem] bg-slate-900 p-1 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] shadow-2xl shadow-slate-900/20">
                            <div className="relative overflow-hidden rounded-[3.25rem] bg-linear-to-br from-primary via-indigo-600 to-indigo-900 p-10 lg:p-12 text-white">
                                <div className="absolute top-0 right-0 p-12 opacity-10">
                                    <Activity className="h-64 w-64 rotate-12" />
                                </div>
                                
                                <div className="relative z-10 space-y-10">
                                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-8">
                                        <div className="space-y-3">
                                            <p className="text-xs font-black text-white/60 uppercase tracking-[0.3em]">Monthly Revenue Assets</p>
                                            <div className="flex items-baseline gap-3">
                                                <h2 className="text-7xl font-black tracking-tighter">₦{stats.totalEarnings}</h2>
                                                <Badge className="bg-emerald-500/20 text-emerald-400 border-none rounded-full px-3 py-1 font-black text-[10px] gap-1">
                                                    <TrendingUp className="h-3 w-3" /> +12.4%
                                                </Badge>
                                            </div>
                                        </div>
                                        <div className="flex gap-4">
                                            <Button className="h-14 rounded-2xl bg-white text-primary hover:bg-white/90 font-black uppercase tracking-widest text-xs px-8 shadow-xl shadow-black/10" asChild>
                                                <Link href="/doctor/patient-payments">
                                                    Withdraw Funds
                                                </Link>
                                            </Button>
                                            <Button variant="outline" className="h-14 rounded-2xl border-white/20 bg-white/5 hover:bg-white/10 text-white font-black uppercase tracking-widest text-xs px-8" asChild>
                                                <Link href="/doctor/earnings">
                                                    Statement
                                                </Link>
                                            </Button>
                                        </div>
                                    </div>

                                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                                        {[
                                            { label: 'Sessions', val: stats.sessionEarnings, icon: Video, trend: '+8%' },
                                            { label: 'Active Care', val: stats.activePatients, icon: Users, trend: '+14' },
                                            { label: 'Rate/Hr', val: stats.consultationRate, icon: Stethoscope, trend: 'Stable' },
                                            { label: 'Upcoming', val: stats.upcomingSessions, icon: Clock, trend: 'Next 2h' }
                                        ].map((item, idx) => (
                                            <div key={idx} className="bg-white/10 backdrop-blur-xl rounded-3xl p-5 border border-white/10 group hover:bg-white/15 transition-all">
                                                <item.icon className="h-5 w-5 text-white/40 mb-3 group-hover:scale-110 transition-transform" />
                                                <p className="text-[10px] font-black uppercase tracking-widest text-white/40 mb-1">{item.label}</p>
                                                <div className="flex items-center justify-between">
                                                    <p className="text-lg font-black">{item.val}</p>
                                                    <span className="text-[9px] font-bold text-white/30">{item.trend}</span>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Recent Appointments & Clinical Requests */}
                        <div className="grid gap-10 lg:grid-cols-2">
                            <div className="space-y-6">
                                <div className="flex items-center justify-between px-2">
                                    <h3 className="text-xl font-black tracking-tight text-slate-900">Clinical Queue</h3>
                                    <Link href="/doctor/appointments" className="text-[10px] font-black text-primary uppercase tracking-widest hover:underline">Full Schedule</Link>
                                </div>
                                <div className="space-y-4">
                                    {appointments?.slice(0, 3).map((apt) => (
                                        <div key={apt.id} className="group relative flex items-center gap-5 p-6 rounded-[2rem] bg-white border border-slate-100 hover:border-primary/20 hover:shadow-2xl transition-all overflow-hidden">
                                            <div className="absolute left-0 top-0 h-full w-1 bg-primary scale-y-0 group-hover:scale-y-100 transition-transform origin-top" />
                                            <Avatar className="h-14 w-14 rounded-2xl border-2 border-white shadow-sm ring-4 ring-primary/5">
                                                <AvatarImage src={`https://i.pravatar.cc/150?u=${apt.patient_id}`} />
                                                <AvatarFallback>{apt.patient.full_name.charAt(0)}</AvatarFallback>
                                            </Avatar>
                                            <div className="flex-1 min-w-0">
                                                <p className="text-sm font-black text-slate-900 truncate group-hover:text-primary transition-colors">{apt.patient.full_name}</p>
                                                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">
                                                    {apt.status === 'scheduled' ? 'Incoming' : 'Session Review'} • {new Date(apt.appointment_date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                </p>
                                            </div>
                                            <Button variant="ghost" size="icon" className="rounded-xl h-10 w-10 opacity-0 group-hover:opacity-100 transition-opacity bg-primary/5 text-primary" asChild>
                                                <Link href="/doctor/appointments">
                                                    <ArrowUpRight className="h-5 w-5" />
                                                </Link>
                                            </Button>
                                        </div>
                                    ))}
                                </div>
                            </div>

                            <div className="space-y-6">
                                <div className="flex items-center justify-between px-2">
                                    <h3 className="text-xl font-black tracking-tight text-slate-900">Financial Alerts</h3>
                                    <Link href="/doctor/payments" className="text-[10px] font-black text-primary uppercase tracking-widest hover:underline">Verification Hub</Link>
                                </div>
                                <div className="space-y-4">
                                    <div className="p-6 rounded-[2rem] bg-orange-50/50 border border-orange-100 space-y-4 relative overflow-hidden group">
                                        <div className="absolute top-0 right-0 p-4 opacity-10 rotate-12 group-hover:rotate-0 transition-transform">
                                            <ShieldAlert className="h-16 w-16 text-orange-500" />
                                        </div>
                                        <div className="flex items-center gap-4">
                                            <div className="h-12 w-12 rounded-2xl bg-orange-500 flex items-center justify-center text-white shadow-lg shadow-orange-500/20">
                                                <Receipt className="h-6 w-6" />
                                            </div>
                                            <div>
                                                <p className="text-sm font-black text-orange-900">{stats.pendingVerifications} Pending P2P Actions</p>
                                                <p className="text-[10px] font-bold text-orange-700/60 uppercase tracking-widest">Immediate review recommended</p>
                                            </div>
                                        </div>
                                        <Button className="w-full h-11 rounded-xl bg-orange-500 hover:bg-orange-600 text-white font-black uppercase tracking-widest text-[10px] shadow-lg shadow-orange-500/20" asChild>
                                            <Link href="/doctor/patient-payments">
                                                Process Receipts
                                            </Link>
                                        </Button>
                                    </div>
                                    <div className="p-6 rounded-[2rem] bg-emerald-50/50 border border-emerald-100 flex items-center justify-between">
                                        <div className="flex items-center gap-4">
                                            <div className="h-10 w-10 rounded-xl bg-emerald-500/10 flex items-center justify-center text-emerald-600">
                                                <CheckCircle2 className="h-5 w-5" />
                                            </div>
                                            <p className="text-xs font-black text-emerald-900 uppercase tracking-widest">Platform Status: Active</p>
                                        </div>
                                        <Zap className="h-5 w-5 text-emerald-500" />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Operational Intelligence Column */}
                    <div className="lg:col-span-4 space-y-10">
                        {/* Daily Insights */}
                        <Card className="rounded-[3rem] border-slate-100 shadow-2xl shadow-slate-200/40 overflow-hidden bg-white/50 backdrop-blur-xl">
                            <CardHeader className="p-8 bg-slate-50/50 border-b border-dashed">
                                <div className="flex items-center justify-between">
                                    <CardTitle className="text-xl font-black tracking-tight">Today&apos;s Protocol</CardTitle>
                                    <div className="h-10 w-10 rounded-xl bg-white shadow-sm border border-slate-100 flex items-center justify-center">
                                        <Calendar className="h-5 w-5 text-primary" />
                                    </div>
                                </div>
                                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-[0.3em] mt-2">{new Date().toLocaleDateString(undefined, { weekday: 'long', day: 'numeric', month: 'short' })}</p>
                            </CardHeader>
                            <CardContent className="p-8 space-y-8">
                                {[
                                    { label: 'Expected Revenue', val: stats.expectedRevenue > 0 ? `₦${stats.expectedRevenue.toLocaleString()}` : 'N/A', icon: TrendingUp, color: 'text-emerald-500', bg: 'bg-emerald-50' },
                                    { label: 'Patient Interaction', val: stats.upcomingSessions, icon: MessageSquare, color: 'text-blue-500', bg: 'bg-blue-50' },
                                    { label: 'Task Completion', val: stats.taskCompletion !== null ? `${stats.taskCompletion}%` : 'N/A', icon: CheckCircle, color: 'text-indigo-500', bg: 'bg-indigo-50' },
                                    { label: 'Doctor Rating', val: averageRating, icon: Star, color: 'text-amber-500', bg: 'bg-amber-50' }
                                ].map((item, idx) => (
                                    <div key={idx} className="flex items-center justify-between group">
                                        <div className="flex items-center gap-4">
                                            <div className={`h-11 w-11 rounded-2xl ${item.bg} flex items-center justify-center ${item.color} group-hover:rotate-6 transition-transform`}>
                                                <item.icon className="h-5 w-5" />
                                            </div>
                                            <p className="text-sm font-bold text-slate-600">{item.label}</p>
                                        </div>
                                        <span className="text-lg font-black text-slate-900 tracking-tight">{item.val}</span>
                                    </div>
                                ))}
                                <ExportButton />
                            </CardContent>
                        </Card>

                        {/* Quick Action Matrix */}
                        <div className="space-y-6">
                            <h4 className="text-[10px] font-black text-slate-400 uppercase tracking-[0.4em] px-4">Toolkit</h4>
                            <div className="grid grid-cols-2 gap-4">
                                <ProposeFollowupDialog doctorProfile={profile} patients={appointments?.map(a => ({ id: a.patient_id, full_name: a.patient?.full_name || 'Patient', lastVisit: a.appointment_date })).filter((v, i, arr) => arr.findIndex(x => x.id === v.id) === i) || []} appointmentPatientId={appointments?.[0]?.patient_id} appointmentReason={appointments?.[0]?.reason} />
                                {[
                                    { label: 'My Vault', icon: FileText, color: 'text-purple-600', bg: 'bg-purple-50', href: '/doctor/records' },
                                    { label: 'Prescribe', icon: Stethoscope, color: 'text-rose-600', bg: 'bg-rose-50', href: '/doctor/appointments' },
                                    { label: 'Reviews', icon: Star, color: 'text-amber-600', bg: 'bg-amber-50', href: '/doctor/reviews' },
                                    { label: 'Payouts', icon: History, color: 'text-emerald-600', bg: 'bg-emerald-50', href: '/doctor/patient-payments' },
                                    { label: 'Security', icon: Lock, color: 'text-slate-600', bg: 'bg-slate-50', href: '/doctor/profile' }
                                ].map((action, idx) => (
                                    <Link key={idx} href={action.href}>
                                        <button className="flex flex-col items-center gap-4 p-6 rounded-[2.5rem] bg-white border border-slate-100 hover:border-primary/20 hover:shadow-2xl transition-all group w-full">
                                            <div className={`h-14 w-14 rounded-2xl ${action.bg} flex items-center justify-center ${action.color} group-hover:scale-110 transition-transform shadow-sm`}>
                                                <action.icon className="h-6 w-6" />
                                            </div>
                                            <span className="text-[10px] font-black uppercase tracking-widest text-slate-600 text-center leading-tight">{action.label}</span>
                                        </button>
                                    </Link>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>

                {/* Sub-Layout Modules */}
                <div className="grid gap-8 mt-20 lg:grid-cols-2">
                    <Card className="rounded-[3.5rem] border-slate-100 shadow-2xl shadow-slate-200/40 overflow-hidden">
                        <CardHeader className="p-10 pb-0">
                            <CardTitle className="text-3xl font-black tracking-tighter">Verified Payments</CardTitle>
                            <CardDescription className="text-xs font-bold uppercase tracking-widest text-slate-400 mt-1">Transaction audit & p2p verification</CardDescription>
                        </CardHeader>
                        <CardContent className="p-10 pt-6">
                            <PaymentVerification doctorId={user.id} />
                        </CardContent>
                    </Card>

                    <Card className="rounded-[3.5rem] border-slate-100 shadow-2xl shadow-slate-200/40 overflow-hidden">
                        <CardHeader className="p-10 pb-0">
                            <CardTitle className="text-3xl font-black tracking-tighter">Clinical Vault</CardTitle>
                            <CardDescription className="text-xs font-bold uppercase tracking-widest text-slate-400 mt-1">Secure medical record decryption</CardDescrip