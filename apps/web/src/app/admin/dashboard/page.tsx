import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase-server'
import { getProfile, getAdminStats, getAllProfiles } from '@/lib/queries'
import { StatsOverview } from '@/components/admin/stats-overview'
import { AdminDashboardCharts } from '@/components/admin/admin-dashboard-charts'
import { UserTable } from '@/components/admin/user-table'
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card'
import { 
    ShieldAlert, TrendingUp, UserPlus, 
    LayoutDashboard, Activity, Bell,
    ArrowUpRight, BarChart3, Users
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import Link from 'next/link'
import { AdminDashboardActions } from '@/components/admin/admin-dashboard-actions'
import { Badge } from '@/components/ui/badge'
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"

export default async function AdminDashboard() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) redirect('/login')

    const { data: profile } = await getProfile(user.id)
    if (profile?.role !== 'admin') redirect('/patient/dashboard')

    const stats = await getAdminStats()
    const { data: profiles } = await getAllProfiles()

    return (
        <div className="space-y-10 pb-20 animate-in-fade">
            {/* Header Section */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div className="space-y-1">
                    <div className="flex items-center gap-3">
                        <h1 className="text-4xl font-black tracking-tighter text-foreground">
                            Command Center
                        </h1>
                        <Badge className="bg-primary/10 text-primary border-none rounded-full px-3 py-1 text-[10px] font-black tracking-widest uppercase animate-pulse">Live</Badge>
                    </div>
                    <p className="text-muted-foreground font-medium">Comprehensive system intelligence and operational oversight.</p>
                </div>
                <div className="flex items-center gap-3">
                    <div className="hidden sm:flex items-center gap-3 pr-6 border-r border-border">
                        <div className="text-right">
                            <p className="text-xs font-black tracking-tight text-foreground">System Administrator</p>
                            <p className="text-[10px] font-bold text-emerald-500 uppercase tracking-widest flex items-center gap-1 justify-end">
                                <Activity className="h-2 w-2" />
                                Stable
                            </p>
                        </div>
                        <Avatar className="h-10 w-10 ring-2 ring-primary/10 ring-offset-2">
                            <AvatarImage src={profile?.avatar_url} />
                            <AvatarFallback>{profile?.full_name?.charAt(0) || 'A'}</AvatarFallback>
                        </Avatar>
                    </div>
                    <AdminDashboardActions />
                </div>
            </div>

            {/* Metrics Grid */}
            <StatsOverview stats={stats} />

            {/* Real-Time Charts */}
            <AdminDashboardCharts />

            <div className="grid gap-8 lg:grid-cols-12">
                {/* User Management Section */}
                <div className="lg:col-span-8 space-y-6">
                    <div className="flex items-center justify-between">
                        <h3 className="text-xl font-black tracking-tight text-foreground flex items-center gap-3">
                            User Directory
                            <span className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest bg-muted px-3 py-1 rounded-full">{profiles?.length || 0} Total</span>
                        </h3>
                        <Link href="/admin/doctors" className="text-[10px] font-black text-primary uppercase tracking-widest hover:underline">Manage All Specialists</Link>
                    </div>
                    
                    <Card className="rounded-[3rem] border-border shadow-2xl overflow-hidden bg-card/50 backdrop-blur-xl">
                        <CardContent className="p-0">
                            <UserTable profiles={profiles || []} />
                        </CardContent>
                    </Card>
                </div>

                {/* System Health & Quick Actions */}
                <div className="lg:col-span-4 space-y-8">
                    {/* Critical Alerts */}
                    <Card className="rounded-[3rem] border-border shadow-2xl overflow-hidden">
                        <CardHeader className="bg-muted/50 border-b border-dashed p-8">
                            <CardTitle className="text-xl font-black tracking-tight flex items-center gap-3">
                                <ShieldAlert className="h-5 w-5 text-rose-500" />
                                Priority Alerts
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="p-8 space-y-6">
                            {stats.pendingVerifications > 0 && (
                                <div className="group relative flex items-start gap-4 p-4 rounded-2xl bg-rose-50/50 border border-rose-100 hover:bg-rose-50 transition-all">
                                    <div className="h-10 w-10 rounded-xl bg-rose-500 flex items-center justify-center text-white shrink-0 shadow-lg shadow-rose-500/20">
                                        <Users className="h-5 w-5" />
                                    </div>
                                    <div className="space-y-1 flex-1">
                                        <p className="text-sm font-black text-rose-900">Verification Backlog</p>
                                        <p className="text-xs font-bold text-rose-700/70">{stats.pendingVerifications} specialists awaiting review.</p>
                                        <Link href="/admin/doctors" className="flex items-center gap-1 text-[10px] font-black text-rose-600 uppercase tracking-widest mt-2 hover:gap-2 transition-all">
                                            Process Now <ArrowUpRight className="h-3 w-3" />
                                        </Link>
                                    </div>
                                </div>
                            )}

                            {stats.expiredSubscriptions > 0 && (
                                <div className="group relative flex items-start gap-4 p-4 rounded-2xl bg-orange-50/50 border border-orange-100 hover:bg-orange-50 transition-all">
                                    <div className="h-10 w-10 rounded-xl bg-orange-500 flex items-center justify-center text-white shrink-0 shadow-lg shadow-orange-500/20">
                                        <TrendingUp className="h-5 w-5" />
                                    </div>
                                    <div className="space-y-1 flex-1">
                                        <p className="text-sm font-black text-orange-900">Payment Overdue</p>
                                        <p className="text-xs font-bold text-orange-700/70">{stats.expiredSubscriptions} accounts are suspended.</p>
                                        <Link href="/admin/subscriptions" className="flex items-center gap-1 text-[10px] font-black text-orange-600 uppercase tracking-widest mt-2 hover:gap-2 transition-all">
                                            View Accounts <ArrowUpRight className="h-3 w-3" />
                                        </Link>
                                    </div>
                                </div>
                            )}

                            {stats.pendingVerifications === 0 && stats.expiredSubscriptions === 0 && (
                                <div className="text-center py-10">
                                    <div className="h-16 w-16 bg-emerald-50 rounded-full flex items-center justify-center mx-auto mb-4 border border-emerald-100">
                                        <Activity className="h-8 w-8 text-emerald-500" />
                                    </div>
                                    <p className="text-sm font-black text-foreground">System Nominal</p>
                                    <p className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest mt-1">No urgent alerts found.</p>
                                </div>
                            )}
                        </CardContent>
                    </Card>

                    {/* Operational Actions */}
                    <div className="grid gap-4">
                        <h4 className="text-[10px] font-black text-muted-foreground uppercase tracking-[0.3em] px-4">Operations Hub</h4>
                        {[
                            { title: "Financial Moderation", icon: TrendingUp, href: "/admin/payments", color: "text-emerald-600", bg: "bg-emerald-50" },
                            { title: "Broadcast Systems", icon: Bell, href: "/admin/notifications", color: "text-blue-600", bg: "bg-blue-50" },
                            { title: "Subscription Controls", icon: BarChart3, href: "/admin/subscriptions", color: "text-indigo-600", bg: "bg-indigo-50" },
                            { title: "Platform Reporting", icon: Activity, href: "/admin/reports", color: "text-muted-foreground", bg: "bg-muted" }
                        ].map((action, i) => (
                            <Link key={i} href={action.href}>
                                <Button variant="ghost" className="h-20 w-full justify-start rounded-[2rem] bg-card border border-border hover:border-primary/20 hover:shadow-xl transition-all p-6 group">
                                    <div className={`h-10 w-10 rounded-xl ${action.bg} flex items-center justify-center ${action.color} group-hover:scale-110 transition-transform`}>
                                        <action.icon className="h-5 w-5" />
                                    </div>
                                    <span className="ml-4 font-black uppercase tracking-widest text-[11px] text-muted-foreground">{action.title}</span>
                                    <ArrowUpRight className="ml-auto h-4 w-4 text-muted-foreground/50 group-hover:text-primary transition-colors" />
                                </Button>
                            </Link>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    )
}
