'use client'

import { useState, useEffect, useCallback } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { createClient } from '@/lib/supabase'
import { AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts'
import { BarChart3, PieChart as PieChartIcon, TrendingUp } from 'lucide-react'

interface DayData {
    date: string
    completed: number
    cancelled: number
}

interface RevenueData {
    date: string
    amount: number
}

interface StatusData {
    name: string
    value: number
    color: string
}

const STATUS_COLORS: Record<string, string> = {
    completed: '#10b981',
    pending: '#f59e0b',
    cancelled: '#ef4444',
    ongoing: '#0F62FE',
    emergency_request: '#8b5cf6',
}

function formatDate(d: Date) {
    return d.toISOString().slice(0, 10)
}

function formatCurrency(amount: number) {
    return new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN', minimumFractionDigits: 0 }).format(amount)
}

export function AdminDashboardCharts({ className }: { className?: string }) {
    const [appointmentData, setAppointmentData] = useState<DayData[]>([])
    const [revenueData, setRevenueData] = useState<RevenueData[]>([])
    const [statusData, setStatusData] = useState<StatusData[]>([])
    const [totalAppointments, setTotalAppointments] = useState(0)
    const [loading, setLoading] = useState(true)
    const supabase = createClient()

    const fetchData = useCallback(async () => {
        const now = new Date()
        const thirtyDaysAgo = new Date(now)
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
        const since = thirtyDaysAgo.toISOString()

        const [{ data: appointments }, { data: payments }] = await Promise.all([
            supabase.from('appointments').select('id, status, created_at').gte('created_at', since),
            supabase.from('payments').select('amount, created_at').eq('status', 'approved').gte('created_at', since),
        ])

        const dayMap = new Map<string, { completed: number; cancelled: number }>()
        const statusCount = new Map<string, number>()
        for (let i = 29; i >= 0; i--) {
            const d = new Date(now)
            d.setDate(d.getDate() - i)
            dayMap.set(formatDate(d), { completed: 0, cancelled: 0 })
        }

        let total = 0
        for (const apt of appointments || []) {
            total++
            const day = apt.created_at.slice(0, 10)
            const entry = dayMap.get(day) || { completed: 0, cancelled: 0 }
            if (apt.status === 'completed') entry.completed++
            if (apt.status === 'cancelled') entry.cancelled++
            dayMap.set(day, entry)
            statusCount.set(apt.status, (statusCount.get(apt.status) || 0) + 1)
        }

        setAppointmentData(
            Array.from(dayMap.entries()).map(([date, v]) => ({
                date: date.slice(5),
                completed: v.completed,
                cancelled: v.cancelled,
            }))
        )
        setTotalAppointments(total)

        const revMap = new Map<string, number>()
        for (let i = 29; i >= 0; i--) {
            const d = new Date(now)
            d.setDate(d.getDate() - i)
            revMap.set(formatDate(d), 0)
        }
        for (const pay of payments || []) {
            const day = pay.created_at.slice(0, 10)
            revMap.set(day, (revMap.get(day) || 0) + (pay.amount || 0))
        }
        setRevenueData(
            Array.from(revMap.entries()).map(([date, amount]) => ({
                date: date.slice(5),
                amount,
            }))
        )

        setStatusData(
            Array.from(statusCount.entries()).map(([name, value]) => ({
                name: name.replace(/_/g, ' '),
                value,
                color: STATUS_COLORS[name] || '#94a3b8',
            }))
        )
        setLoading(false)
    }, [supabase])

    useEffect(() => {
        fetchData()
        const channel = supabase
            .channel('admin-charts')
            .on('postgres_changes', { event: '*', schema: 'public', table: 'appointments' }, fetchData)
            .on('postgres_changes', { event: '*', schema: 'public', table: 'payments' }, fetchData)
            .subscribe()
        return () => { supabase.removeChannel(channel) }
    }, [fetchData, supabase])

    const CustomTooltip = ({ active, payload, label }: any) => {
        if (!active || !payload?.length) return null
        return (
            <div className="rounded-xl border border-slate-100 bg-white/80 backdrop-blur-xl px-4 py-3 shadow-lg">
                <p className="text-xs font-bold text-slate-500 mb-1">{label}</p>
                {payload.map((entry: any) => (
                    <p key={entry.name} className="text-sm font-bold" style={{ color: entry.color }}>
                        {entry.name}: {entry.name === 'amount' ? formatCurrency(entry.value) : entry.value}
                    </p>
                ))}
            </div>
        )
    }

    if (loading) {
        return (
            <div className={`grid gap-6 md:grid-cols-2 lg:grid-cols-3 ${className || ''}`}>
                {[1, 2, 3].map((i) => (
                    <Card key={i} className="rounded-[2rem] border-slate-100 shadow-sm bg-white/50 backdrop-blur-xl">
                        <CardContent className="p-8">
                            <div className="h-80 animate-pulse bg-slate-100 rounded-2xl" />
                        </CardContent>
                    </Card>
                ))}
            </div>
        )
    }

    return (
        <div className={`grid gap-6 md:grid-cols-2 lg:grid-cols-3 ${className || ''}`}>
            <Card className="rounded-[2rem] border-slate-100 shadow-sm bg-white/50 backdrop-blur-xl overflow-hidden">
                <CardHeader className="pb-2 px-8 pt-8">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <div className="bg-blue-50 p-3 rounded-2xl">
                                <TrendingUp className="h-5 w-5 text-blue-600" />
                            </div>
                            <CardTitle className="text-sm font-black text-slate-900 tracking-tight">Appointments</CardTitle>
                        </div>
                        <Badge variant="secondary" className="rounded-full bg-blue-50 text-blue-700 border-0 text-xs font-bold">
                            {totalAppointments} total
                        </Badge>
                    </div>
                </CardHeader>
                <CardContent className="px-6 pb-8">
                    <ResponsiveContainer width="100%" height={280}>
                        <AreaChart data={appointmentData}>
                            <defs>
                                <linearGradient id="completedGrad" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="#0F62FE" stopOpacity={0.3} />
                                    <stop offset="95%" stopColor="#0F62FE" stopOpacity={0} />
                                </linearGradient>
                                <linearGradient id="cancelledGrad" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="#ef4444" stopOpacity={0.3} />
                                    <stop offset="95%" stopColor="#ef4444" stopOpacity={0} />
                                </linearGradient>
                            </defs>
                            <XAxis dataKey="date" tick={{ fontSize: 10, fill: '#94a3b8' }} tickLine={false} axisLine={false} />
                            <YAxis tick={{ fontSize: 10, fill: '#94a3b8' }} tickLine={false} axisLine={false} allowDecimals={false} />
                            <Tooltip content={<CustomTooltip />} />
                            <Area type="monotone" dataKey="completed" stroke="#0F62FE" fill="url(#completedGrad)" strokeWidth={2} name="Completed" />
                            <Area type="monotone" dataKey="cancelled" stroke="#ef4444" fill="url(#cancelledGrad)" strokeWidth={2} name="Cancelled" />
                        </AreaChart>
                    </ResponsiveContainer>
                </CardContent>
            </Card>

            <Card className="rounded-[2rem] border-slate-100 shadow-sm bg-white/50 backdrop-blur-xl overflow-hidden">
                <CardHeader className="pb-2 px-8 pt-8">
                    <div className="flex items-center gap-3">
                        <div className="bg-indigo-50 p-3 rounded-2xl">
                            <BarChart3 className="h-5 w-5 text-[#0F62FE]" />
                        </div>
                        <CardTitle className="text-sm font-black text-slate-900 tracking-tight">Revenue (30d)</CardTitle>
                    </div>
                </CardHeader>
                <CardContent className="px-6 pb-8">
                    <ResponsiveContainer width="100%" height={280}>
                        <BarChart data={revenueData}>
                            <XAxis dataKey="date" tick={{ fontSize: 10, fill: '#94a3b8' }} tickLine={false} axisLine={false} />
                            <YAxis tick={{ fontSize: 10, fill: '#94a3b8' }} tickLine={false} axisLine={false} tickFormatter={(v) => `${(v / 1000).toFixed(0)}k`} />
                            <Tooltip content={<CustomTooltip />} />
                            <Bar dataKey="amount" fill="#0F62FE" radius={[4, 4, 0, 0]} name="Revenue" />
                        </BarChart>
                    </ResponsiveContainer>
                </CardContent>
            </Card>

            <Card className="rounded-[2rem] border-slate-100 shadow-sm bg-white/50 backdrop-blur-xl overflow-hidden md:col-span-2 lg:col-span-1">
                <CardHeader className="pb-2 px-8 pt-8">
                    <div className="flex items-center gap-3">
                        <div className="bg-purple-50 p-3 rounded-2xl">
                            <PieChartIcon className="h-5 w-5 text-purple-600" />
                        </div>
                        <CardTitle className="text-sm font-black text-slate-900 tracking-tight">Status Breakdown</CardTitle>
                    </div>
                </CardHeader>
                <CardContent className="px-6 pb-8">
                    <ResponsiveContainer width="100%" height={240}>
                        <PieChart>
                            <Pie
                                data={statusData}
                                cx="50%"
                                cy="50%"
                                innerRadius={55}
                                outerRadius={90}
                                paddingAngle={3}
                                dataKey="value"
                            >
                                {statusData.map((entry, i) => (
                                    <Cell key={i} fill={entry.color} stroke="none" />
                                ))}
                            </Pie>
                            <Tooltip content={<CustomTooltip />} />
                        </PieChart>
                    </ResponsiveContainer>
                    <div className="flex flex-wrap gap-3 mt-2 justify-center">
                        {statusData.map((s) => (
                            <div key={s.name} className="flex items-center gap-2 text-xs font-bold text-slate-600">
                                <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: s.color }} />
                                <span className="capitalize">{s.name}</span>
                                <span className="text-slate-400">{s.value}</span>
                            </div>
                        ))}
                    </div>
                </CardContent>
            </Card>
        </div>
    )
}
