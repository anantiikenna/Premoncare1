'use client'

import { Card, CardContent } from '@/components/ui/card'
import { Users, Calendar, MessageSquare, ClipboardList, TrendingUp, ShieldCheck, Clock, ArrowUpRight, ArrowDownRight } from 'lucide-react'

interface Stats {
    totalUsers: number
    totalAppointments: number
    totalPosts: number
    totalRecords: number
    pendingVerifications: number
    expiredSubscriptions: number
    totalRevenue: number
    pendingRevenue: number
}

export function StatsOverview({ stats }: { stats: Stats }) {
    const items = [
        {
            title: 'Gross Revenue',
            value: `₦${(stats.totalRevenue / 1000000).toFixed(1)}M`,
            icon: TrendingUp,
            description: 'Total platform intake',
            color: 'text-emerald-600',
            bg: 'bg-emerald-50',
            trend: `${stats.totalAppointments} appointments`,
            trendPositive: true
        },
        {
            title: 'Pending Payouts',
            value: `₦${(stats.pendingRevenue / 1000).toFixed(0)}K`,
            icon: ShieldCheck,
            description: 'Awaiting verification',
            color: 'text-primary',
            bg: 'bg-primary/5',
            trend: `${stats.pendingRevenue > 0 ? 'Action needed' : 'All clear'}`,
            trendPositive: stats.pendingRevenue === 0
        },
        {
            title: 'Overdue Subs',
            value: stats.expiredSubscriptions,
            icon: Clock,
            description: 'Suspended practitioners',
            color: 'text-rose-600',
            bg: 'bg-rose-50',
            trend: stats.expiredSubscriptions > 0 ? 'Action Required' : 'All active',
            trendPositive: stats.expiredSubscriptions === 0
        },
        {
            title: 'System Users',
            value: stats.totalUsers.toLocaleString(),
            icon: Users,
            description: 'Active profiles',
            color: 'text-blue-600',
            bg: 'bg-blue-50',
            trend: `${stats.pendingVerifications} pending verify`,
            trendPositive: stats.pendingVerifications === 0
        }
    ]

    return (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
            {items.map((item) => (
                <Card key={item.title} className="rounded-[2.5rem] border-slate-100 shadow-sm hover:shadow-xl transition-all group overflow-hidden bg-white/50 backdrop-blur-xl">
                    <CardContent className="p-8 space-y-4">
                        <div className="flex items-center justify-between">
                            <div className={`${item.bg} ${item.color} p-4 rounded-2xl group-hover:scale-110 transition-transform`}>
                                <item.icon className="h-6 w-6" />
                            </div>
                            <div className={`flex items-center gap-1 text-[10px] font-black uppercase tracking-widest ${item.trendPositive ? 'text-emerald-600' : 'text-rose-600'}`}>
                                {item.trendPositive ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownRight className="h-3 w-3" />}
                                {item.trend}
                            </div>
                        </div>
                        <div className="space-y-1">
                            <h3 className="text-3xl font-black tracking-tighter text-slate-900">{item.value}</h3>
                            <p className="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">{item.title}</p>
                        </div>
                        <p className="text-xs font-bold text-slate-500/60 border-t border-slate-50 pt-4">
                            {item.description}
                        </p>
                    </CardContent>
                </Card>
            ))}
        </div>
    )
}
