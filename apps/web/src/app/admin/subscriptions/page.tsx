'use client'

import { useState, useEffect, useCallback } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { createNotification } from '@/lib/queries-client'
import { getUserFacingError } from '@/lib/user-facing-errors'
import { Profile } from '@/lib/types'
import {
    Users, CheckCircle2, AlertCircle, Clock,
    CreditCard, ArrowUpRight, Search,
    MoreHorizontal, Send, Calendar, ShieldBan,
    BarChart3, PieChart, LayoutGrid, List,
    TrendingUp, Loader2
} from 'lucide-react'
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import {
    DropdownMenu, DropdownMenuContent, DropdownMenuItem,
    DropdownMenuTrigger, DropdownMenuSeparator
} from '@/components/ui/dropdown-menu'
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import {
    Dialog, DialogContent, DialogHeader, DialogTitle,
    DialogDescription, DialogFooter
} from '@/components/ui/dialog'

type SubStatus = 'active' | 'expiring' | 'expired' | 'overdue'

function getStatus(doctor: Profile): SubStatus {
    if (doctor.subscription_status === 'active' && doctor.subscription_expires_at) {
        const daysLeft = Math.ceil((new Date(doctor.subscription_expires_at).getTime() - Date.now()) / 86400000)
        if (daysLeft <= 7 && daysLeft > 0) return 'expiring'
        if (daysLeft <= 0) return 'expired'
        return 'active'
    }
    if (doctor.subscription_status === 'active') return 'active'
    if (doctor.account_status === 'suspended') return 'overdue'
    return 'expired'
}

function getExpiryText(doctor: Profile): string {
    if (doctor.subscription_expires_at) {
        const daysLeft = Math.ceil((new Date(doctor.subscription_expires_at).getTime() - Date.now()) / 86400000)
        if (daysLeft <= 0) return `Expired ${Math.abs(daysLeft)}d ago`
        if (daysLeft <= 7) return `Expires in ${daysLeft}d`
        return `Expires ${new Date(doctor.subscription_expires_at).toLocaleDateString('en-NG', { month: 'short', day: 'numeric', year: 'numeric' })}`
    }
    return doctor.subscription_status === 'active' ? 'Active' : 'No subscription'
}

export default function AdminSubscriptionsPage() {
    const [loading, setLoading] = useState(true)
    const [doctors, setDoctors] = useState<Profile[]>([])
    const [searchTerm, setSearchTerm] = useState('')
    const [activeTab, setActiveTab] = useState('all')
    const [processingId, setProcessingId] = useState<string | null>(null)

    const [reminderDialog, setReminderDialog] = useState<Profile | null>(null)
    const [extendDialog, setExtendDialog] = useState<Profile | null>(null)
    const [suspendDialog, setSuspendDialog] = useState<Profile | null>(null)

    const supabase = createClient()

    const fetchDoctors = useCallback(async () => {
        setLoading(true)
        try {
            const { data, error } = await supabase
                .from('profiles')
                .select('*')
                .or('role.eq.doctor,requested_role.eq.doctor')
                .order('created_at', { ascending: false })
            if (error) throw error
            setDoctors((data as unknown as Profile[]) || [])
        } catch (error: unknown) {
            console.error('Error fetching doctors:', error)
            toast.error(getUserFacingError(error, 'Failed to load subscription data.'))
        } finally {
            setLoading(false)
        }
    }, [supabase])

    useEffect(() => {
        fetchDoctors()
    }, [fetchDoctors])

    const stats = {
        totalSubscribers: doctors.length,
        active: doctors.filter(d => getStatus(d) === 'active').length,
        expiringSoon: doctors.filter(d => getStatus(d) === 'expiring').length,
        expired: doctors.filter(d => getStatus(d) === 'expired').length,
        overdue: doctors.filter(d => getStatus(d) === 'overdue').length,
    }

    const filteredDoctors = doctors.filter(doc => {
        const status = getStatus(doc)
        const matchesSearch = doc.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
            doc.specialty?.toLowerCase().includes(searchTerm.toLowerCase())
        const matchesTab = activeTab === 'all' ||
            (activeTab === 'active' && status === 'active') ||
            (activeTab === 'expiring' && status === 'expiring') ||
            (activeTab === 'expired' && (status === 'expired' || status === 'overdue'))
        return matchesSearch && matchesTab
    })

    const handleSendReminder = async (doctor: Profile) => {
        setProcessingId(doctor.id)
        try {
            await createNotification({
                user_id: doctor.id,
                title: 'Subscription Renewal Reminder',
                message: 'Your subscription is expiring soon. Please renew to maintain access to your practice dashboard and avoid service interruption.',
                type: 'payment',
                link: '/doctor/dashboard'
            })
            toast.success(`Reminder sent to ${doctor.full_name}`)
            setReminderDialog(null)
        } catch (error: unknown) {
            toast.error(getUserFacingError(error, 'Failed to send reminder.'))
        } finally {
            setProcessingId(null)
        }
    }

    const handleExtendSubscription = async (doctor: Profile) => {
        setProcessingId(doctor.id)
        try {
            const newExpiry = new Date()
            newExpiry.setMonth(newExpiry.getMonth() + 1)
            const { error } = await supabase
                .from('profiles')
                .update({
                    subscription_status: 'active',
                    subscription_expires_at: newExpiry.toISOString()
                })
                .eq('id', doctor.id)
            if (error) throw error
            await createNotification({
                user_id: doctor.id,
                title: 'Subscription Extended',
                message: 'Your subscription has been extended by 30 days. Thank you for staying with PremonCare!',
                type: 'system',
                link: '/doctor/dashboard'
            })
            toast.success(`Subscription extended for ${doctor.full_name}`)
            setExtendDialog(null)
            fetchDoctors()
        } catch (error: unknown) {
            toast.error(getUserFacingError(error, 'Failed to extend subscription.'))
        } finally {
            setProcessingId(null)
        }
    }

    const handleSuspendAccount = async (doctor: Profile) => {
        setProcessingId(doctor.id)
        try {
            const { error } = await supabase
                .from('profiles')
                .update({
                    account_status: 'suspended',
                    subscription_status: 'expired'
                })
                .eq('id', doctor.id)
            if (error) throw error
            await createNotification({
                user_id: doctor.id,
                title: 'Account Suspended',
                message: 'Your account has been suspended due to a subscription issue. Please contact support to resolve this.',
                type: 'system',
                link: '/doctor/dashboard'
            })
            toast.success(`Account suspended for ${doctor.full_name}`)
            setSuspendDialog(null)
            fetchDoctors()
        } catch (error: unknown) {
            toast.error(getUserFacingError(error, 'Failed to suspend account.'))
        } finally {
            setProcessingId(null)
        }
    }

    const statusBadgeClass = (s: SubStatus) =>
        s === 'active' ? 'bg-emerald-50 text-emerald-600' :
        s === 'expiring' ? 'bg-orange-50 text-orange-600' :
        'bg-rose-50 text-rose-600'

    const statusColor = (s: SubStatus) =>
        s === 'active' ? 'text-emerald-500' :
        s === 'expiring' ? 'text-orange-500' : 'text-rose-500'

    const statusBg = (s: SubStatus) =>
        s === 'active' ? 'bg-emerald-50' :
        s === 'expiring' ? 'bg-orange-50' : 'bg-rose-50'

    if (loading) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[60vh]">
                <Loader2 className="h-10 w-10 animate-spin text-primary mb-4" />
                <p className="text-sm text-slate-500 font-bold uppercase tracking-widest">Loading subscriptions...</p>
            </div>
        )
    }

    return (
        <div className="space-y-10 pb-20 animate-in-fade">
            {/* Header */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div className="space-y-1">
                    <h1 className="text-4xl font-black tracking-tighter text-slate-900 flex items-center gap-3">
                        Doctor Subscriptions
                        <Badge className="bg-primary/10 text-primary border-none rounded-full px-3 py-1 text-xs font-black tracking-widest uppercase">Console</Badge>
                    </h1>
                    <p className="text-slate-500 font-medium">Monitor, manage and control practitioner subscription lifecycles.</p>
                </div>
                <div className="flex items-center gap-3">
                    <Button variant="outline" className="rounded-2xl border-slate-200 shadow-sm h-12 px-6 font-bold text-slate-600 gap-2"
                        onClick={() => toast.info('Full analytics coming soon')}>
                        <BarChart3 className="h-4 w-4" />
                        Full Analytics
                    </Button>
                    <Button className="rounded-2xl shadow-lg shadow-primary/20 h-12 px-8 font-black uppercase tracking-widest text-[11px] gap-2"
                        onClick={() => toast.info('Billing settings coming soon')}>
                        <CreditCard className="h-4 w-4" />
                        Billing Settings
                    </Button>
                </div>
            </div>

            {/* Metrics Grid */}
            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-5">
                {[
                    { label: 'Total Subscribers', val: stats.totalSubscribers, icon: Users, color: 'text-primary', bg: 'bg-primary/5' },
                    { label: 'Active', val: stats.active, icon: CheckCircle2, color: 'text-emerald-500', bg: 'bg-emerald-50', trend: stats.totalSubscribers ? `${((stats.active / stats.totalSubscribers) * 100).toFixed(1)}%` : '0%', sub: 'of total' },
                    { label: 'Expiring Soon', val: stats.expiringSoon, icon: Clock, color: 'text-orange-500', bg: 'bg-orange-50', trend: 'Next 7 days', sub: 'Action required' },
                    { label: 'Expired / Overdue', val: stats.expired + stats.overdue, icon: AlertCircle, color: 'text-rose-500', bg: 'bg-rose-50', trend: 'Overdue', sub: 'Requires attention' },
                    { label: 'Revenue (Est.)', val: `₦${(stats.active * 25000).toLocaleString()}`, icon: TrendingUp, color: 'text-primary', bg: 'bg-primary/10', trend: 'This month', sub: 'Based on active' },
                ].map((stat, i) => (
                    <Card key={i} className="rounded-[2rem] border-slate-100 shadow-sm hover:shadow-xl transition-all group">
                        <CardContent className="p-8 space-y-4">
                            <div className="flex items-center justify-between">
                                <div className={`${stat.bg} ${stat.color} p-3 rounded-2xl group-hover:scale-110 transition-transform`}>
                                    <stat.icon className="h-5 w-5" />
                                </div>
                                {'trend' in stat && stat.trend && (
                                    <span className={`text-[10px] font-black uppercase tracking-widest ${stat.color}`}>{stat.trend}</span>
                                )}
                            </div>
                            <div className="space-y-1">
                                <h3 className="text-3xl font-black tracking-tight text-slate-900">{stat.val}</h3>
                                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-[0.1em]">{stat.label}</p>
                            </div>
                        </CardContent>
                    </Card>
                ))}
            </div>

            {/* Main Content */}
            <div className="grid gap-8 lg:grid-cols-12">
                {/* Subscription List */}
                <div className="lg:col-span-8 space-y-6">
                    <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 bg-white p-4 rounded-[2.5rem] border border-slate-100 shadow-sm">
                        <Tabs value={activeTab} onValueChange={setActiveTab}>
                            <TabsList className="bg-slate-50 p-1 rounded-xl h-12">
                                {['all', 'active', 'expiring', 'expired'].map((tab) => (
                                    <TabsTrigger key={tab} value={tab} className="rounded-lg px-6 h-10 font-bold text-xs uppercase tracking-widest data-[state=active]:bg-white data-[state=active]:shadow-sm">
                                        {tab === 'all' ? 'All' : tab === 'active' ? 'Active' : tab === 'expiring' ? 'Expiring' : 'Expired'}
                                    </TabsTrigger>
                                ))}
                            </TabsList>
                        </Tabs>
                        <div className="flex items-center gap-3 w-full md:w-auto">
                            <div className="relative flex-1 md:w-80">
                                <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
                                <Input
                                    className="w-full pl-11 rounded-xl bg-slate-50 border-none focus-visible:ring-1 focus-visible:ring-primary h-11"
                                    placeholder="Search doctor or specialty..."
                                    value={searchTerm}
                                    onChange={(e) => setSearchTerm(e.target.value)}
                                />
                            </div>
                        </div>
                    </div>

                    <Card className="rounded-[3rem] border-slate-100 shadow-xl shadow-slate-200/40 overflow-hidden bg-white/50 backdrop-blur-xl">
                        <CardHeader className="bg-slate-50/50 border-b border-slate-100 p-8">
                            <div className="flex items-center justify-between">
                                <div className="space-y-1">
                                    <CardTitle className="text-xl font-black tracking-tight">Practitioner Directory</CardTitle>
                                    <CardDescription className="text-xs font-bold text-slate-400 uppercase tracking-widest">
                                        {filteredDoctors.length} doctor{filteredDoctors.length !== 1 ? 's' : ''} found
                                    </CardDescription>
                                </div>
                            </div>
                        </CardHeader>
                        <CardContent className="p-0">
                            <div className="overflow-x-auto">
                                <table className="w-full text-left border-collapse">
                                    <thead>
                                        <tr className="border-b border-slate-50">
                                            <th className="p-8 text-[10px] font-black uppercase tracking-widest text-slate-400">Doctor</th>
                                            <th className="p-8 text-[10px] font-black uppercase tracking-widest text-slate-400">Specialty & Fee</th>
                                            <th className="p-8 text-[10px] font-black uppercase tracking-widest text-slate-400">Status & Expiry</th>
                                            <th className="p-8 text-[10px] font-black uppercase tracking-widest text-slate-400">Verification</th>
                                            <th className="p-8 text-[10px] font-black uppercase tracking-widest text-slate-400 text-right">Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-slate-50">
                                        {filteredDoctors.length === 0 ? (
                                            <tr>
                                                <td colSpan={5} className="p-20 text-center">
                                                    <div className="bg-slate-50 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-4">
                                                        <Search className="h-8 w-8 text-slate-300" />
                                                    </div>
                                                    <p className="text-slate-500 font-bold">No doctors match your filters.</p>
                                                </td>
                                            </tr>
                                        ) : (
                                            filteredDoctors.map((doc) => {
                                                const status = getStatus(doc)
                                                return (
                                                    <tr key={doc.id} className="hover:bg-slate-50/50 transition-colors group">
                                                        <td className="p-8">
                                                            <div className="flex items-center gap-4">
                                                                <Avatar className="h-12 w-12 rounded-2xl border-2 border-white shadow-sm ring-2 ring-primary/5">
                                                                    <AvatarImage src={doc.avatar_url} />
                                                                    <AvatarFallback>{doc.full_name?.charAt(0) || 'D'}</AvatarFallback>
                                                                </Avatar>
                                                                <div className="space-y-1">
                                                                    <p className="text-sm font-black text-slate-900 group-hover:text-primary transition-colors">{doc.full_name}</p>
                                                                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">
                                                                        {doc.email || `ID: ${doc.id.substring(0, 8)}`}
                                                                    </p>
                                                                </div>
                                                            </div>
                                                        </td>
                                                        <td className="p-8">
                                                            <div className="space-y-1">
                                                                <p className="text-[10px] font-black text-slate-500 uppercase tracking-widest">{doc.specialty || 'General'}</p>
                                                                <p className="text-sm font-black text-slate-900">{doc.negotiated_fee ? `₦${doc.negotiated_fee.toLocaleString()}/mo` : '—'}</p>
                                                            </div>
                                                        </td>
                                                        <td className="p-8">
                                                            <div className="space-y-2">
                                                                <Badge
                                                                    variant="outline"
                                                                    className={`rounded-lg px-3 py-1 text-[9px] font-black uppercase tracking-widest border-none ${statusBadgeClass(status)}`}
                                                                >
                                                                    {status === 'overdue' ? 'Suspended' : status}
                                                                </Badge>
                                                                <p className="text-[10px] font-bold text-slate-400">{getExpiryText(doc)}</p>
                                                            </div>
                                                        </td>
                                                        <td className="p-8">
                                                            <Badge
                                                                variant="outline"
                                                                className={`rounded-lg px-3 py-1 text-[9px] font-black uppercase tracking-widest border-none ${
                                                                    doc.verification_status === 'approved' ? 'bg-emerald-50 text-emerald-600' :
                                                                    doc.verification_status === 'pending' ? 'bg-amber-50 text-amber-600' :
                                                                    'bg-slate-100 text-slate-500'
                                                                }`}
                                                            >
                                                                {doc.verification_status || 'unsubmitted'}
                                                            </Badge>
                                                        </td>
                                                        <td className="p-8 text-right">
                                                            <DropdownMenu>
                                                                <DropdownMenuTrigger asChild>
                                                                    <Button variant="ghost" size="icon" className="rounded-xl h-10 w-10 hover:bg-white hover:shadow-sm">
                                                                        <MoreHorizontal className="h-5 w-5 text-slate-400" />
                                                                    </Button>
                                                                </DropdownMenuTrigger>
                                                                <DropdownMenuContent align="end" className="w-56 rounded-2xl p-2 shadow-2xl border-none">
                                                                    <DropdownMenuItem
                                                                        className="rounded-xl p-3 font-bold text-xs uppercase tracking-widest gap-3"
                                                                        onClick={() => setReminderDialog(doc)}
                                                                    >
                                                                        <Send className="h-4 w-4" /> Send Reminder
                                                                    </DropdownMenuItem>
                                                                    <DropdownMenuItem
                                                                        className="rounded-xl p-3 font-bold text-xs uppercase tracking-widest gap-3"
                                                                        onClick={() => setExtendDialog(doc)}
                                                                    >
                                                                        <Calendar className="h-4 w-4" /> Extend Sub
                                                                    </DropdownMenuItem>
                                                                    <DropdownMenuSeparator />
                                                                    <DropdownMenuItem
                                                                        className="rounded-xl p-3 font-bold text-xs uppercase tracking-widest gap-3 text-rose-600"
                                                                        onClick={() => setSuspendDialog(doc)}
                                                                    >
                                                                        <ShieldBan className="h-4 w-4" /> Suspend Account
                                                                    </DropdownMenuItem>
                                                                </DropdownMenuContent>
                                                            </DropdownMenu>
                                                        </td>
                                                    </tr>
                                                )
                                            })
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </CardContent>
                    </Card>
                </div>

                {/* Right Column */}
                <div className="lg:col-span-4 space-y-8">
                    <Card className="rounded-[3rem] border-slate-100 shadow-2xl shadow-slate-200/40 overflow-hidden">
                        <CardHeader className="p-8 bg-slate-50/50 border-b border-dashed">
                            <CardTitle className="text-xl font-black tracking-tight flex items-center gap-3">
                                <PieChart className="h-5 w-5 text-primary" />
                                Distribution
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="p-8 space-y-8">
                            <div className="relative aspect-square flex items-center justify-center">
                                <svg className="w-full h-full -rotate-90" viewBox="0 0 100 100">
                                    <circle cx="50" cy="50" r="40" fill="transparent" stroke="#0F62FE"
                                        strokeWidth="20"
                                        strokeDasharray={`${stats.totalSubscribers ? (stats.active / stats.totalSubscribers) * 251.2 : 0} 251.2`} />
                                    <circle cx="50" cy="50" r="40" fill="transparent" stroke="#F59E0B"
                                        strokeWidth="20"
                                        strokeDasharray={`${stats.totalSubscribers ? (stats.expiringSoon / stats.totalSubscribers) * 251.2 : 0} 251.2`}
                                        strokeDashoffset={`${stats.totalSubscribers ? -(stats.active / stats.totalSubscribers) * 251.2 : 0}`} />
                                    <circle cx="50" cy="50" r="40" fill="transparent" stroke="#EF4444"
                                        strokeWidth="20"
                                        strokeDasharray={`${stats.totalSubscribers ? ((stats.expired + stats.overdue) / stats.totalSubscribers) * 251.2 : 0} 251.2`}
                                        strokeDashoffset={`${stats.totalSubscribers ? -((stats.active + stats.expiringSoon) / stats.totalSubscribers) * 251.2 : 0}`} />
                                </svg>
                                <div className="absolute flex flex-col items-center">
                                    <span className="text-4xl font-black tracking-tighter text-slate-900">{stats.totalSubscribers}</span>
                                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Total</span>
                                </div>
                            </div>

                            <div className="grid gap-4">
                                {[
                                    { label: 'Active', count: stats.active, color: 'bg-primary' },
                                    { label: 'Expiring', count: stats.expiringSoon, color: 'bg-orange-500' },
                                    { label: 'Expired', count: stats.expired, color: 'bg-rose-500' },
                                    { label: 'Suspended', count: stats.overdue, color: 'bg-indigo-400' },
                                ].map((item, i) => (
                                    <div key={i} className="flex items-center justify-between">
                                        <div className="flex items-center gap-3">
                                            <div className={`h-2 w-2 rounded-full ${item.color}`} />
                                            <span className="text-sm font-bold text-slate-600">{item.label}</span>
                                        </div>
                                        <span className="text-sm font-black text-slate-900">
                                            {item.count} ({stats.totalSubscribers ? ((item.count / stats.totalSubscribers) * 100).toFixed(1) : 0}%)
                                        </span>
                                    </div>
                                ))}
                            </div>
                        </CardContent>
                    </Card>

                    <div className="grid gap-4">
                        {[
                            { title: "Overdue Payments", icon: AlertCircle, color: "text-rose-600", bg: "bg-rose-50", route: "/admin/payments" },
                            { title: "Subscription Reports", icon: BarChart3, color: "text-primary", bg: "bg-primary/5", route: "/admin/reports" },
                            { title: "Plan Configuration", icon: LayoutGrid, color: "text-indigo-600", bg: "bg-indigo-50", route: "/admin/settings" },
                            { title: "Payment Logs", icon: List, color: "text-slate-600", bg: "bg-slate-50", route: "/admin/financial" }
                        ].map((action, i) => (
                            <Button
                                key={i}
                                variant="ghost"
                                className="h-20 w-full justify-start rounded-[2rem] bg-white border border-slate-100 hover:border-primary/20 hover:shadow-lg transition-all p-6 group"
                                onClick={() => toast.info(`Navigating to ${action.title}...`)}
                            >
                                <div className={`h-10 w-10 rounded-xl ${action.bg} flex items-center justify-center ${action.color} group-hover:scale-110 transition-transform`}>
                                    <action.icon className="h-5 w-5" />
                                </div>
                                <span className="ml-4 font-black uppercase tracking-widest text-[11px] text-slate-600">{action.title}</span>
                                <ArrowUpRight className="ml-auto h-4 w-4 text-slate-300 group-hover:text-primary transition-colors" />
                            </Button>
                        ))}
                    </div>
                </div>
            </div>

            {/* Send Reminder Dialog */}
            <Dialog open={!!reminderDialog} onOpenChange={(open) => { if (!open) setReminderDialog(null) }}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Send Subscription Reminder</DialogTitle>
                        <DialogDescription>
                            Send a push notification reminding <strong>{reminderDialog?.full_name}</strong> to renew their subscription.
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setReminderDialog(null)}>Cancel</Button>
                        <Button
                            onClick={() => reminderDialog && handleSendReminder(reminderDialog)}
                            disabled={!!processingId}
                        >
                            {processingId ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : <Send className="h-4 w-4 mr-2" />}
                            Send Reminder
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {/* Extend Subscription Dialog */}
            <Dialog open={!!extendDialog} onOpenChange={(open) => { if (!open) setExtendDialog(null) }}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Extend Subscription</DialogTitle>
                        <DialogDescription>
                            Extend <strong>{extendDialog?.full_name}</strong>&apos;s subscription by 30 days from today. This will set their status to active.
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setExtendDialog(null)}>Cancel</Button>
                        <Button
                            onClick={() => extendDialog && handleExtendSubscription(extendDialog)}
                            disabled={!!processingId}
                        >
                            {processingId ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : <Calendar className="h-4 w-4 mr-2" />}
                            Confirm Extension
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {/* Suspend Account Dialog */}
            <Dialog open={!!suspendDialog} onOpenChange={(open) => { if (!open) setSuspendDialog(null) }}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle className="text-rose-600">Suspend Account</DialogTitle>
                        <DialogDescription>
                            Are you sure you want to suspend <strong>{suspendDialog?.full_name}</strong>&apos;s account? This will immediately revoke access and mark their subscription as expired. You can reverse this later.
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setSuspendDialog(null)}>Cancel</Button>
                        <Button
                            variant="destructive"
                            onClick={() => suspendDialog && handleSuspendAccount(suspendDialog)}
                            disabled={!!processingId}
                        >
                            {processingId ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : <ShieldBan className="h-4 w-4 mr-2" />}
                            Suspend Account
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    )
}
