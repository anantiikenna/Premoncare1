import { createClient } from '@/lib/supabase-server'
import { getAppointments, getHealthRecords, getProfile } from '@/lib/queries'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { 
    Calendar, FileText, Activity, Lock, ShieldAlert, 
    ArrowUpRight, Heart, Bell, Search, Clock,
    Plus, Zap, ShieldCheck,
    Stethoscope, MessageSquare
} from 'lucide-react'
import { VerificationBanner } from '@/components/dashboard/verification-banner'
import { Badge } from '@/components/ui/badge'
import { WellnessTip } from '@/components/dashboard/wellness-tip'

export default async function PatientDashboard() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return null

    const { data: profile } = await getProfile(user.id)
    const isVerified = profile?.verification_status === 'approved'

    const [{ data: appointments }, { data: records }, { count: unreadCount }] = await Promise.all([
        getAppointments(user.id, 'patient'),
        getHealthRecords(user.id),
        supabase
            .from('notifications')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', user.id)
            .eq('is_read', false),
    ])

    const upcomingAppointments = appointments?.filter(a => ['pending', 'confirmed', 'rescheduled', 'ongoing', 'emergency_accepted'].includes(a.status)) || []

    return (
        <div className="space-y-12 pb-24 animate-in-fade relative overflow-hidden">
            {/* Background Mesh Decor */}
            <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-primary/5 rounded-full blur-[120px] -z-10 pointer-events-none" />
            
            {/* Header Section */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-8">
                <div className="space-y-1">
                    <div className="flex items-center gap-3">
                        <h1 className="text-4xl font-black tracking-tighter text-slate-900">
                            Hello, {profile?.full_name?.split(' ')[0] || 'User'}
                        </h1>
                        <Badge className="bg-primary/10 text-primary border-none rounded-full px-3 py-1 text-[10px] font-black tracking-widest uppercase">Wellness Pulse</Badge>
                    </div>
                    <p className="text-slate-500 font-medium">Tracking your health journey and upcoming clinical sessions.</p>
                </div>
                <div className="flex items-center gap-4">
                    <div className="hidden lg:flex flex-col items-end pr-6 border-r border-slate-200">
                        <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Account Status</span>
                        <div className="flex items-center gap-2 mt-1">
                            <span className={`h-2 w-2 rounded-full ${isVerified ? 'bg-emerald-500' : 'bg-orange-500'} animate-pulse`} />
                            <span className="text-xs font-black text-slate-900">{isVerified ? 'Fully Verified' : 'Action Required'}</span>
                        </div>
                    </div>
                    <div className="flex items-center gap-3">
                        <Button variant="outline" size="icon" className="rounded-2xl border-slate-200 shadow-sm h-11 w-11" asChild>
                            <Link href="/patient/doctors">
                                <Search className="h-4 w-4 text-slate-500" />
                            </Link>
                        </Button>
                        <div className="relative">
                            <Button variant="outline" size="icon" className="rounded-2xl border-slate-200 shadow-sm h-11 w-11" asChild>
                                <Link href="/patient/notifications">
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

            {/* Critical Banner Area */}
            <VerificationBanner status={profile?.verification_status || 'unsubmitted'} userId={user.id} />
            
            {/* Main Content Grid */}
            <div className="grid gap-8 lg:grid-cols-12">
                
                {/* Left Primary Column */}
                <div className="lg:col-span-8 space-y-10">
                    
                    {/* Immersive Welcome & Quick Action Card */}
                    <div className="relative overflow-hidden rounded-[3.5rem] bg-slate-900 p-1 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] shadow-2xl shadow-slate-900/20">
                        <div className="relative overflow-hidden rounded-[3.25rem] bg-linear-to-br from-primary via-blue-600 to-indigo-900 p-10 lg:p-12 text-white">
                            <div className="absolute top-0 right-0 p-12 opacity-10">
                                <Heart className="h-64 w-64 rotate-12" />
                            </div>
                            
                            <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-10">
                                <div className="space-y-6">
                                    <div className="space-y-2">
                                        <p className="text-xs font-black text-white/60 uppercase tracking-[0.3em]">Current Wellness Balance</p>
                                        <h2 className="text-6xl font-black tracking-tighter">Premium Care</h2>
                                    </div>
                                    <div className="flex flex-wrap gap-3">
                                        <Badge className="bg-white/20 text-white border-none rounded-full px-4 py-1.5 font-black text-[10px] uppercase tracking-widest gap-2 backdrop-blur-md">
                                            <ShieldCheck className="h-3.5 w-3.5" /> 24/7 Priority
                                        </Badge>
                                        <Badge className="bg-white/20 text-white border-none rounded-full px-4 py-1.5 font-black text-[10px] uppercase tracking-widest gap-2 backdrop-blur-md">
                                            <Zap className="h-3.5 w-3.5" /> Fast Track
                                        </Badge>
                                    </div>
                                </div>
                                <div className="space-y-4 shrink-0">
                                    <Button className="w-full md:w-auto h-14 rounded-2xl bg-white text-primary hover:bg-white/90 font-black uppercase tracking-widest text-xs px-10 shadow-xl shadow-black/10 flex items-center gap-3" asChild>
                                        <Link href="/patient/doctors">
                                            <Plus className="h-4 w-4" />
                                            Book Specialist
                                        </Link>
                                    </Button>
                                    <p className="text-[10px] font-black text-white/40 uppercase tracking-widest text-center">Consultations from ₦15,000</p>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Vitals Summary & Highlights */}
                    <div className="grid gap-6 md:grid-cols-2">
                        <Card className="rounded-[2.5rem] border-slate-100 shadow-xl shadow-slate-200/40 overflow-hidden group">
                            <CardHeader className="p-8 pb-4 flex flex-row items-center justify-between">
                                <div className="space-y-1">
                                    <CardTitle className="text-sm font-black uppercase tracking-widest text-slate-400">Health Overview</CardTitle>
                                    <p className="text-xs font-bold text-slate-900">Latest Biometrics</p>
                                </div>
                                <div className="h-10 w-10 rounded-xl bg-primary/5 flex items-center justify-center text-primary group-hover:scale-110 transition-transform">
                                    <Activity className="h-5 w-5" />
                                </div>
                            </CardHeader>
                            <CardContent className="p-8 pt-4">
                                <div className="grid grid-cols-2 gap-8">
                                    <div className="space-y-1">
                                        <p className="text-3xl font-black text-slate-900 tracking-tighter">{profile?.weight ? `${profile.weight}kg` : '—'}</p>
                                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Weight Status</p>
                                    </div>
                                    <div className="space-y-1 border-l border-slate-100 pl-8">
                                        <p className="text-3xl font-black text-slate-900 tracking-tighter">{profile?.blood_group || '—'}</p>
                                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Blood Type</p>
                                    </div>
                                </div>
                            </CardContent>
                        </Card>

                        <Card className="rounded-[2.5rem] border-slate-100 shadow-xl shadow-slate-200/40 overflow-hidden group">
                            <CardHeader className="p-8 pb-4 flex flex-row items-center justify-between">
                                <div className="space-y-1">
                                    <CardTitle className="text-sm font-black uppercase tracking-widest text-slate-400">Records Vault</CardTitle>
                                    <p className="text-xs font-bold text-slate-900">Medical Documents</p>
                                </div>
                                <div className="h-10 w-10 rounded-xl bg-indigo-50 flex items-center justify-center text-indigo-600 group-hover:scale-110 transition-transform">
                                    <FileText className="h-5 w-5" />
                                </div>
                            </CardHeader>
                            <CardContent className="p-8 pt-4">
                                <div className="flex items-center justify-between">
                                    <div className="space-y-1">
                                        <p className="text-3xl font-black text-slate-900 tracking-tighter">{records?.length || 0}</p>
                                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Active Records</p>
                                    </div>
                                    <Button variant="ghost" size="icon" className="rounded-xl h-10 w-10 bg-slate-50 hover:bg-indigo-50 hover:text-indigo-600 transition-all" asChild>
                                        <Link href="/patient/medical-profile">
                                            <ArrowUpRight className="h-5 w-5" />
                                        </Link>
                                    </Button>
                                </div>
                            </CardContent>
                        </Card>
                    </div>

                    {/* Schedule & Queue */}
                    <div className="space-y-6">
                        <div className="flex items-center justify-between px-2">
                            <h3 className="text-xl font-black tracking-tight text-slate-900">Clinical Schedule</h3>
                            <Link href="/patient/appointments" className="text-[10px] font-black text-primary uppercase tracking-widest hover:underline">View All Sessions</Link>
                        </div>
                        <div className="grid gap-4">
                            {upcomingAppointments.length === 0 ? (
                                <div className="p-12 text-center rounded-[3rem] border-2 border-dashed border-slate-100 bg-slate-50/50">
                                    <Calendar className="h-10 w-10 text-slate-300 mx-auto mb-4" />
                                    <p className="text-sm font-black text-slate-900">No sessions scheduled.</p>
                                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">Book your first consult today.</p>
                                </div>
                            ) : (
                                upcomingAppointments.map((apt) => (
                                    <div key={apt.id} className="group relative flex items-center gap-6 p-6 rounded-[2.5rem] bg-white border border-slate-100 hover:border-primary/20 hover:shadow-2xl transition-all overflow-hidden">
                                        <div className="absolute left-0 top-0 h-full w-1.5 bg-primary scale-y-0 group-hover:scale-y-100 transition-transform origin-top" />
                                        <div className="h-16 w-16 rounded-2xl bg-slate-50 flex flex-col items-center justify-center shrink-0 border border-slate-100 group-hover:bg-primary/5 group-hover:border-primary/10 transition-colors">
                                            <p className="text-xl font-black text-slate-900 group-hover:text-primary transition-colors">{new Date(apt.appointment_date).getDate()}</p>
                                            <p className="text-[9px] font-black text-slate-400 uppercase tracking-widest">{new Date(apt.appointment_date).toLocaleDateString(undefined, { month: 'short' })}</p>
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            <p className="text-sm font-black text-slate-900 truncate">Consultation with Dr. {apt.doctor.full_name}</p>
                                            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1 flex items-center gap-2">
                                                <Clock className="h-3 w-3" />
                                                {new Date(apt.appointment_date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} • {apt.doctor.specialty}
                                            </p>
                                        </div>
                                        <div className="text-right">
                                            <Badge className={`rounded-lg px-3 py-1 text-[9px] font-black uppercase tracking-widest border-none ${
                                                apt.status === 'confirmed' ? 'bg-emerald-50 text-emerald-600' : 'bg-blue-50 text-blue-600'
                                            }`}>
                                                {apt.status}
                                            </Badge>
                                        </div>
                                    </div>
                                ))
                            )}
                        </div>
                    </div>
                </div>

                {/* Right Operational Column */}
                <div className="lg:col-span-4 space-y-10">
                    
                    {/* Security & Verification Card */}
                    <Card className={`rounded-[3rem] border-slate-100 shadow-2xl shadow-slate-200/40 overflow-hidden ${!isVerified ? 'border-orange-100' : ''}`}>
                        <CardHeader className={`p-8 border-b border-dashed ${!isVerified ? 'bg-orange-50/50' : 'bg-slate-50/50'}`}>
                            <div className="flex items-center justify-between">
                                <CardTitle className="text-xl font-black tracking-tight">Health Pass</CardTitle>
                                {!isVerified ? <ShieldAlert className="h-5 w-5 text-orange-500" /> : <ShieldCheck className="h-5 w-5 text-emerald-500" />}
                            </div>
                            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">Verification Identity Status</p>
                        </CardHeader>
                        <CardContent className="p-8 space-y-6">
                            {!isVerified ? (
                                <>
                                    <div className="space-y-2">
                                        <p className="text-sm font-black text-slate-900 leading-tight">Your medical identity is currently being processed.</p>
                                        <p className="text-xs font-medium text-slate-500">Professional features will unlock once your clinical audit is complete.</p>
                                    </div>
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="p-4 rounded-2xl bg-slate-50 border border-slate-100 text-center">
                                            <p className="text-lg font-black text-slate-900">In Review</p>
                                            <p className="text-[9px] font-bold text-slate-400 uppercase tracking-widest">Audit Progress</p>
                                        </div>
                                        <div className="p-4 rounded-2xl bg-slate-50 border border-slate-100 text-center">
                                            <p className="text-lg font-black text-slate-900">--</p>
                                            <p className="text-[9px] font-bold text-slate-400 uppercase tracking-widest">Verification ID</p>
                                        </div>
                                    </div>
                                </>
                            ) : (
                                <div className="text-center py-6">
                                    <div className="h-20 w-20 bg-emerald-50 rounded-full flex items-center justify-center mx-auto mb-6 border-4 border-white shadow-xl shadow-emerald-500/10">
                                        <ShieldCheck className="h-10 w-10 text-emerald-500" />
                                    </div>
                                    <p className="text-lg font-black text-slate-900">Clinical Identity Verified</p>
                                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">Access to all platform assets enabled.</p>
                                </div>
                            )}
                            <Button className="w-full h-12 rounded-2xl bg-slate-900 font-black uppercase tracking-widest text-[10px]" asChild>
                                <Link href="/patient/medical-profile">
                                    {isVerified ? 'Manage Security' : 'Resume Verification'}
                                </Link>
                            </Button>
                        </CardContent>
                    </Card>

                    {/* Quick Access Matrix */}
                    <div className="space-y-6">
                        <h4 className="text-[10px] font-black text-slate-400 uppercase tracking-[0.4em] px-4">Services</h4>
                        <div className="grid grid-cols-2 gap-4">
                            {[
                                { label: 'Forum', icon: Activity, color: 'text-primary', bg: 'bg-primary/5', href: '/patient/forum' },
                                { label: 'Messages', icon: MessageSquare, color: 'text-indigo-600', bg: 'bg-indigo-50', href: '/patient/messages' },
                                { label: 'History', icon: Clock, color: 'text-amber-600', bg: 'bg-amber-50', href: '/patient/history' },
                                { label: 'Specialists', icon: Stethoscope, color: 'text-rose-600', bg: 'bg-rose-50', href: '/patient/doctors' },
                                { label: 'Vault', icon: Lock, color: 'text-purple-600', bg: 'bg-purple-50', href: '/patient/medical-profile' },
                                { label: 'Support', icon: Bell, color: 'text-slate-600', bg: 'bg-slate-50', href: '/support' }
                            ].map((action, idx) => (
                                <Link key={idx} href={action.href}>
                                    <button className="w-full flex flex-col items-center gap-4 p-6 rounded-[2.5rem] bg-white border border-slate-100 hover:border-primary/20 hover:shadow-2xl transition-all group cursor-pointer">
                                        <div className={`h-14 w-14 rounded-2xl ${action.bg} flex items-center justify-center ${action.color} group-hover:scale-110 transition-transform shadow-sm`}>
                                            <action.icon className="h-6 w-6" />
                                        </div>
                                        <span className="text-[10px] font-black uppercase tracking-widest text-slate-600 text-center leading-tight">{action.label}</span>
                                    </button>
                                </Link>
                            ))}
                        </div>
                    </div>

                    {/* Wellness Tip */}
                    <WellnessTip />
                </div>
            </div>
        </div>
    )
}
