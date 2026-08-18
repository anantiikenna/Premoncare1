'use client'

import { useState, useEffect, useCallback } from 'react'
import { getAuditTimeline } from '@/lib/queries-client'
import type { AuditEvent } from '@/lib/queries-base'

import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogDescription,
    DialogFooter,
} from '@/components/ui/dialog'
import {
    ShieldCheck,
    CreditCard,
    MessageSquare,
    Calendar,
    AlertTriangle,
    Activity,
    Clock,
    RefreshCw,
    Eye,
    Filter,
    ArrowUpDown,
    FileText,
    Bell,
} from 'lucide-react'

const FILTERS = ['All', 'Verification', 'Payments', 'Forum', 'Appointments', 'Notifications', 'System', 'Alerts'] as const
type FilterType = (typeof FILTERS)[number]

const TYPE_CONFIG: Record<AuditEvent['type'], { icon: typeof ShieldCheck; color: string; bg: string; label: string }> = {
    verification: { icon: ShieldCheck, color: 'text-emerald-500', bg: 'bg-emerald-500/10', label: 'Verification' },
    payment: { icon: CreditCard, color: 'text-blue-500', bg: 'bg-blue-500/10', label: 'Payment' },
    forum: { icon: MessageSquare, color: 'text-violet-500', bg: 'bg-violet-500/10', label: 'Forum' },
    appointment: { icon: Calendar, color: 'text-amber-500', bg: 'bg-amber-500/10', label: 'Appointment' },
    system: { icon: Activity, color: 'text-slate-500', bg: 'bg-muted', label: 'System' },
    notification: { icon: Bell, color: 'text-cyan-500', bg: 'bg-cyan-500/10', label: 'Notification' },
}

const SEVERITY_CONFIG: Record<AuditEvent['severity'], { badge: string; dot: string }> = {
    success: { badge: 'bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950 dark:text-emerald-400 dark:border-emerald-800', dot: 'bg-emerald-500' },
    info: { badge: 'bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-950 dark:text-blue-400 dark:border-blue-800', dot: 'bg-blue-500' },
    warning: { badge: 'bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950 dark:text-amber-400 dark:border-amber-800', dot: 'bg-amber-500' },
    danger: { badge: 'bg-rose-50 text-rose-700 border-rose-200 dark:bg-rose-950 dark:text-rose-400 dark:border-rose-800', dot: 'bg-rose-500' },
}

function formatRelativeTime(timestamp: string) {
    const diff = Date.now() - new Date(timestamp).getTime()
    const mins = Math.floor(diff / 60000)
    if (mins < 1) return 'Just now'
    if (mins < 60) return `${mins}m ago`
    const hours = Math.floor(mins / 60)
    if (hours < 24) return `${hours}h ago`
    const days = Math.floor(hours / 24)
    if (days < 7) return `${days}d ago`
    return new Date(timestamp).toLocaleDateString('en-NG', { month: 'short', day: 'numeric' })
}

function formatTimestamp(timestamp: string) {
    return new Date(timestamp).toLocaleString('en-NG', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    })
}

function groupEventsByDate(events: AuditEvent[]) {
    const groups = new Map<string, AuditEvent[]>()
    for (const event of events) {
        const date = new Date(event.timestamp).toLocaleDateString('en-NG', {
            weekday: 'long',
            month: 'long',
            day: 'numeric',
            year: 'numeric',
        })
        if (!groups.has(date)) groups.set(date, [])
        groups.get(date)!.push(event)
    }
    return groups
}

export default function AdminAuditTimelinePage() {
    const [events, setEvents] = useState<AuditEvent[]>([])
    const [stats, setStats] = useState({ totalActions: 0, securityAlerts: 0, recentChanges: 0 })
    const [loading, setLoading] = useState(true)
    const [activeFilter, setActiveFilter] = useState<FilterType>('All')
    const [sortAsc, setSortAsc] = useState(false)
    const [selectedEvent, setSelectedEvent] = useState<AuditEvent | null>(null)
    const [page, setPage] = useState(1)
    const [dateRange, setDateRange] = useState<{ from: string; to: string }>({ from: '', to: '' })
    const PAGE_SIZE = 25

    const fetchAuditData = useCallback(async () => {
        setLoading(true)
        try {
            const result = await getAuditTimeline(500)
            setEvents(result.events)
            setStats(result.stats)
        } catch (err) {
            console.error('Failed to fetch audit timeline:', err)
        } finally {
            setLoading(false)
        }
    }, [])

    useEffect(() => {
        fetchAuditData()
    }, [fetchAuditData])

    const filteredEvents = events.filter((e) => {
        if (activeFilter !== 'All') {
            if (activeFilter === 'Alerts') {
                if (e.severity !== 'danger' && e.severity !== 'warning') return false
            } else if (activeFilter === 'Notifications') {
                if (e.type !== 'notification') return false
            } else if (activeFilter === 'System') {
                if (e.type !== 'system') return false
            } else if (e.type !== activeFilter.toLowerCase()) {
                return false
            }
        }
        if (dateRange.from) {
            const eventDate = new Date(e.timestamp)
            const fromDate = new Date(dateRange.from)
            if (eventDate < fromDate) return false
        }
        if (dateRange.to) {
            const eventDate = new Date(e.timestamp)
            const toDate = new Date(dateRange.to)
            toDate.setHours(23, 59, 59, 999)
            if (eventDate > toDate) return false
        }
        return true
    })

    const sortedEvents = [...filteredEvents].sort((a, b) =>
        sortAsc
            ? new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
            : new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
    )

    const groupedEvents = groupEventsByDate(sortedEvents)
    const totalPages = Math.ceil(sortedEvents.length / PAGE_SIZE)
    const paginatedGroups = groupEventsByDate(sortedEvents.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE))

    const handleExportCSV = () => {
        const headers = ['Timestamp', 'Type', 'Severity', 'Title', 'Actor', 'Target', 'Metadata']
        const rows = sortedEvents.map(e => [
            formatTimestamp(e.timestamp),
            e.type,
            e.severity,
            e.title,
            e.actor || '',
            e.target || '',
            Object.keys(e.meta).length > 0 ? JSON.stringify(e.meta) : ''
        ])
        const csv = [headers, ...rows].map(r => r.map(c => `"${String(c).replace(/"/g, '""')}"`).join(',')).join('\n')
        const blob = new Blob([csv], { type: 'text/csv' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `audit-log-${new Date().toISOString().slice(0, 10)}.csv`
        a.click()
        URL.revokeObjectURL(url)
    }

    return (
        <div className="min-h-screen bg-background p-6 md:p-12">
            <div className="max-w-6xl mx-auto space-y-8">
                {/* Header */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                    <div className="space-y-2">
                        <div className="flex items-center gap-2 text-violet-600 font-black uppercase tracking-widest text-xs">
                            <FileText className="h-4 w-4" />
                            Platform Administration
                        </div>
                        <h1 className="text-3xl font-black text-foreground tracking-tight">Audit Timeline</h1>
                        <p className="text-sm font-semibold text-muted-foreground">
                            Track and review all system activities across the platform.
                        </p>
                    </div>
                    <div className="flex items-center gap-3">
                        <div className="flex items-center gap-2 px-3 py-1.5 bg-emerald-50 border border-emerald-500/20 rounded-full">
                            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                            <span className="text-xs font-black text-emerald-600 tracking-wider">LIVE</span>
                        </div>
                        <Button variant="outline" size="sm" onClick={handleExportCSV} className="rounded-xl cursor-pointer">
                            <FileText className="h-4 w-4 mr-1" />
                            Export CSV
                        </Button>
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={fetchAuditData}
                            disabled={loading}
                            className="rounded-xl"
                        >
                            <RefreshCw className={`h-4 w-4 mr-1 ${loading ? 'animate-spin' : ''}`} />
                            Refresh
                        </Button>
                    </div>
                </div>

                {/* Stats Row */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                    <StatCard
                        value={stats.totalActions.toLocaleString()}
                        title="Total Actions"
                        subtitle="Last 30 days"
                        icon={Activity}
                        color="text-blue-500"
                        bgColor="bg-blue-500/10"
                    />
                    <StatCard
                        value={stats.securityAlerts.toLocaleString()}
                        title="Security Alerts"
                        subtitle="Flagged activities"
                        icon={AlertTriangle}
                        color="text-rose-500"
                        bgColor="bg-rose-500/10"
                    />
                    <StatCard
                        value={stats.recentChanges.toLocaleString()}
                        title="Recent Changes"
                        subtitle="Last 24 hours"
                        icon={Clock}
                        color="text-amber-500"
                        bgColor="bg-amber-500/10"
                    />
                    <StatCard
                        value={events.filter((e) => e.type === 'verification').length.toLocaleString()}
                        title="Verifications"
                        subtitle="Processed actions"
                        icon={ShieldCheck}
                        color="text-emerald-500"
                        bgColor="bg-emerald-500/10"
                    />
                </div>

                {/* Filter Chips */}
                <div className="flex flex-wrap items-center gap-2">
                    <Filter className="h-4 w-4 text-muted-foreground mr-1" />
                    {FILTERS.map((filter) => {
                        const count =
                            filter === 'All'
                                ? events.length
                                : filter === 'Alerts'
                                  ? events.filter((e) => e.severity === 'danger' || e.severity === 'warning').length
                                  : filter === 'Notifications'
                                    ? events.filter((e) => e.type === 'notification').length
                                    : filter === 'System'
                                      ? events.filter((e) => e.type === 'system').length
                                      : events.filter((e) => e.type === filter.toLowerCase()).length
                        return (
                            <button
                                key={filter}
                                onClick={() => { setActiveFilter(filter); setPage(1) }}
                                className={`px-4 py-1.5 rounded-full text-sm font-bold transition-all cursor-pointer ${
                                    activeFilter === filter
                                        ? 'bg-primary text-primary-foreground shadow-lg shadow-primary/30'
                                        : 'bg-card text-muted-foreground border border-border hover:bg-muted'
                                }`}
                            >
                                {filter}
                                <span
                                    className={`ml-1.5 text-[10px] font-black ${
                                        activeFilter === filter ? 'text-primary-foreground/70' : 'text-muted-foreground'
                                    }`}
                                >
                                    {count}
                                </span>
                            </button>
                        )
                    })}
                </div>

                {/* Sort Toggle */}
                {/* Date Range Filter */}
                <div className="flex items-center gap-3">
                    <input
                        type="date"
                        value={dateRange.from}
                        onChange={(e) => { setDateRange(prev => ({ ...prev, from: e.target.value })); setPage(1) }}
                        className="px-3 py-1.5 rounded-xl border border-border bg-card text-sm font-medium text-foreground cursor-pointer"
                    />
                    <span className="text-sm text-muted-foreground">to</span>
                    <input
                        type="date"
                        value={dateRange.to}
                        onChange={(e) => { setDateRange(prev => ({ ...prev, to: e.target.value })); setPage(1) }}
                        className="px-3 py-1.5 rounded-xl border border-border bg-card text-sm font-medium text-foreground cursor-pointer"
                    />
                    {(dateRange.from || dateRange.to) && (
                        <Button variant="ghost" size="sm" onClick={() => { setDateRange({ from: '', to: '' }); setPage(1) }} className="text-xs cursor-pointer">
                            Clear
                        </Button>
                    )}
                </div>

                <div className="flex items-center justify-between border-b border-border pb-4">
                    <div className="flex items-center gap-3">
                        <span className="text-sm font-black text-foreground">{sortedEvents.length} Events</span>
                        <span className="w-1.5 h-1.5 rounded-full bg-muted-foreground/40" />
                        <span className="text-sm font-semibold text-muted-foreground">
                            {activeFilter === 'All' ? 'All Categories' : activeFilter}
                        </span>
                    </div>
                    <button
                        onClick={() => setSortAsc(!sortAsc)}
                        className="flex items-center gap-1 text-sm font-bold text-primary hover:text-primary/80 cursor-pointer"
                    >
                        {sortAsc ? 'Oldest First' : 'Newest First'}
                        <ArrowUpDown className="w-4 h-4" />
                    </button>
                </div>

                {/* Timeline */}
                {loading ? (
                    <div className="flex flex-col items-center justify-center py-20">
                        <RefreshCw className="h-8 w-8 text-muted-foreground/30 animate-spin mb-4" />
                        <p className="text-sm font-bold text-muted-foreground">Loading audit events...</p>
                    </div>
                ) : sortedEvents.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-20">
                        <div className="h-16 w-16 bg-muted rounded-full flex items-center justify-center mb-4">
                            <Activity className="h-8 w-8 text-muted-foreground/30" />
                        </div>
                        <p className="text-sm font-black text-foreground">No Events Found</p>
                        <p className="text-xs font-semibold text-muted-foreground mt-1">
                            {activeFilter !== 'All'
                                ? 'Try adjusting your filters to see more activity.'
                                : 'No audit events have been recorded yet.'}
                        </p>
                    </div>
                ) : (
                    <div className="space-y-8">
                        {Array.from(paginatedGroups.entries()).map(([date, dateEvents]) => (
                            <div key={date}>
                                <div className="flex items-center gap-3 mb-4">
                                    <span className="text-sm font-black text-foreground">{date}</span>
                                    <span className="text-[10px] font-bold text-muted-foreground bg-muted px-2 py-0.5 rounded-full">
                                        {dateEvents.length} events
                                    </span>
                                </div>
                                <div className="space-y-4">
                                    {dateEvents.map((event) => (
                                        <TimelineEvent
                                            key={event.id}
                                            event={event}
                                            onViewDetails={setSelectedEvent}
                                        />
                                    ))}
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Pagination */}
                {totalPages > 1 && (
                    <div className="flex items-center justify-between">
                        <p className="text-sm text-muted-foreground">
                            Page {page} of {totalPages}
                        </p>
                        <div className="flex items-center gap-2">
                            <Button variant="outline" size="sm" onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page <= 1} className="cursor-pointer">
                                Previous
                            </Button>
                            <Button variant="outline" size="sm" onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page >= totalPages} className="cursor-pointer">
                                Next
                            </Button>
                        </div>
                    </div>
                )}

                {/* Footer */}
                <div className="flex items-center justify-between p-4 bg-primary/5 border border-primary/10 rounded-2xl">
                    <div className="flex items-center gap-3">
                        <ShieldCheck className="h-5 w-5 text-primary" />
                        <p className="text-sm font-bold text-primary">
                            All audit activities are securely stored for compliance and investigation purposes.
                        </p>
                    </div>
                </div>
            </div>

            {/* Detail Dialog */}
            <Dialog open={!!selectedEvent} onOpenChange={(open) => !open && setSelectedEvent(null)}>
                <DialogContent className="sm:max-w-lg">
                    {selectedEvent && <EventDetailContent event={selectedEvent} onClose={() => setSelectedEvent(null)} />}
                </DialogContent>
            </Dialog>
        </div>
    )
}

function StatCard({
    value,
    title,
    subtitle,
    icon: Icon,
    color,
    bgColor,
}: {
    value: string
    title: string
    subtitle: string
    icon: typeof Activity
    color: string
    bgColor: string
}) {
    return (
        <div className="bg-card p-5 rounded-2xl border border-border shadow-sm hover:shadow-md transition-shadow">
            <div className={`w-10 h-10 rounded-full flex items-center justify-center ${bgColor} mb-4`}>
                <Icon className={`h-5 w-5 ${color}`} />
            </div>
            <h3 className="text-2xl font-black text-foreground tracking-tight">{value}</h3>
            <p className="text-sm font-bold text-foreground">{title}</p>
            <p className="text-xs font-semibold text-muted-foreground mt-1">{subtitle}</p>
        </div>
    )
}

function TimelineEvent({
    event,
    onViewDetails,
}: {
    event: AuditEvent
    onViewDetails: (event: AuditEvent) => void
}) {
    const config = TYPE_CONFIG[event.type]
    const severity = SEVERITY_CONFIG[event.severity]
    const Icon = config.icon

    return (
        <div className="flex gap-4 group">
            <div className="w-20 shrink-0 pt-2 text-right">
                <div className="text-sm font-bold text-foreground">
                    {new Date(event.timestamp).toLocaleTimeString('en-NG', { hour: '2-digit', minute: '2-digit' })}
                </div>
                <div className="text-xs font-semibold text-muted-foreground">{formatRelativeTime(event.timestamp)}</div>
            </div>
            <div className="flex flex-col items-center">
                <div className={`w-3 h-3 rounded-full mt-3 relative z-10 shadow-sm ${severity.dot}`} />
                <div className="w-0.5 h-full bg-border -mt-2 -mb-2 group-last:hidden" />
            </div>
            <div className="flex-1 pb-4">
                <Card className="rounded-2xl border-border shadow-sm hover:shadow-md transition-shadow overflow-hidden">
                    <CardContent className="p-5">
                        <div className="flex items-start gap-4">
                            <div className={`p-3 rounded-xl ${config.bg}`}>
                                <Icon className={`h-6 w-6 ${config.color}`} />
                            </div>
                            <div className="flex-1 min-w-0">
                                <div className="flex items-start justify-between gap-2">
                                    <h4 className="font-black text-foreground text-base leading-tight">{event.title}</h4>
                                    <Badge variant="outline" className={`shrink-0 text-[10px] font-bold ${severity.badge}`}>
                                        {event.severity === 'danger' ? 'Alert' : event.severity === 'warning' ? 'Pending' : event.severity === 'success' ? 'Success' : 'Info'}
                                    </Badge>
                                </div>
                                <p className="text-sm font-semibold text-muted-foreground mt-1">{event.description}</p>

                                <div className="flex flex-wrap items-center gap-x-4 gap-y-1 mt-3 text-xs">
                                    {Object.entries(event.meta).slice(0, 3).map(([key, val]) => (
                                        <div key={key} className="flex items-center gap-1.5">
                                            <span className="font-semibold text-muted-foreground">{key}:</span>
                                            <span className="font-bold text-foreground">{val}</span>
                                        </div>
                                    ))}
                                </div>

                                <div className="flex gap-2 mt-4">
                                    <Button
                                        variant="ghost"
                                        size="sm"
                                        onClick={() => onViewDetails(event)}
                                        className="h-8 px-3 text-xs font-bold rounded-lg"
                                    >
                                        <Eye className="h-3.5 w-3.5 mr-1" />
                                        View Details
                                    </Button>
                                </div>
                            </div>
                        </div>
                    </CardContent>
                </Card>
            </div>
        </div>
    )
}

function EventDetailContent({ event, onClose }: { event: AuditEvent; onClose: () => void }) {
    const config = TYPE_CONFIG[event.type]
    const severity = SEVERITY_CONFIG[event.severity]
    const Icon = config.icon

    return (
        <>
            <DialogHeader>
                <div className="flex items-center gap-3 mb-2">
                    <div className={`p-2 rounded-xl ${config.bg}`}>
                        <Icon className={`h-5 w-5 ${config.color}`} />
                    </div>
                    <div>
                        <DialogTitle className="text-lg">{event.title}</DialogTitle>
                        <DialogDescription>{formatTimestamp(event.timestamp)}</DialogDescription>
                    </div>
                </div>
            </DialogHeader>

            <div className="space-y-4 py-2">
                <div>
                    <p className="text-xs font-bold text-muted-foreground uppercase tracking-wider mb-1">Description</p>
                    <p className="text-sm font-semibold text-foreground">{event.description}</p>
                </div>

                <div className="grid grid-cols-2 gap-3">
                    <div className="bg-muted rounded-xl p-3">
                        <p className="text-[10px] font-black text-muted-foreground uppercase tracking-widest">Type</p>
                        <p className="text-sm font-bold text-foreground mt-0.5">{config.label}</p>
                    </div>
                    <div className="bg-muted rounded-xl p-3">
                        <p className="text-[10px] font-black text-muted-foreground uppercase tracking-widest">Severity</p>
                        <div className="flex items-center gap-2 mt-0.5">
                            <span className={`w-2 h-2 rounded-full ${severity.dot}`} />
                            <p className="text-sm font-bold text-foreground capitalize">{event.severity}</p>
                        </div>
                    </div>
                    {event.actor && (
                        <div className="bg-muted rounded-xl p-3">
                            <p className="text-[10px] font-black text-muted-foreground uppercase tracking-widest">Actor</p>
                            <p className="text-sm font-bold text-foreground mt-0.5">{event.actor}</p>
                        </div>
                    )}
                    {event.target && (
                        <div className="bg-muted rounded-xl p-3">
                            <p className="text-[10px] font-black text-muted-foreground uppercase tracking-widest">Target</p>
                            <p className="text-sm font-bold text-foreground mt-0.5">{event.target}</p>
                        </div>
                    )}
                </div>

                {Object.keys(event.meta).length > 0 && (
                    <div>
                        <p className="text-xs font-bold text-muted-foreground uppercase tracking-wider mb-2">Metadata</p>
                        <div className="bg-muted rounded-xl p-4 space-y-2">
                            {Object.entries(event.meta).map(([key, val]) => (
                                <div key={key} className="flex items-center justify-between">
                                    <span className="text-xs font-semibold text-muted-foreground">{key}</span>
                                    <span className="text-xs font-bold text-foreground">{val}</span>
                                </div>
                            ))}
                        </div>
                    </div>
                )}
            </div>

            <DialogFooter>
                <Button variant="outline" onClick={onClose} className="rounded-xl">
                    Close
                </Button>
            </DialogFooter>
        </>
    )
}
