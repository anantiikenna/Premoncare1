'use client'

import { useState, useEffect, useCallback } from 'react'
import { createClient } from '@/lib/supabase'
import { toast } from 'sonner'
import {
    Search, Filter, AlertTriangle, Clock, CheckCircle, Flag,
    Wallet, Video, RefreshCcw, MessageSquare, ChevronRight,
    FilePlus, Upload, Settings, ShieldAlert, ShieldCheck, ChevronDown,
    Loader2, XCircle, Eye
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogDescription,
    DialogFooter,
    DialogTrigger,
} from '@/components/ui/dialog'

const FILTERS = ['All', 'Payment', 'Consultation', 'Refund', 'Fraud', 'Resolved']

interface DisputeRecord {
    id: string
    created_at: string
    transaction_id: string
    user_id: string
    patient_id: string | null
    doctor_id: string | null
    amount: number | null
    risk_level: 'low' | 'medium' | 'high'
    category: 'payment' | 'consultation' | 'refund' | 'fraud' | 'behavior' | 'other'
    title: string
    description: string | null
    status: 'open' | 'under_review' | 'resolved' | 'dismissed'
    resolution_notes: string | null
    resolved_at: string | null
    resolved_by: string | null
    patient?: { full_name: string | null; avatar_url: string | null } | null
    doctor?: { full_name: string | null; avatar_url: string | null } | null
}

function categoryToFilter(category: string): string {
    if (category === 'behavior') return 'Consultation'
    if (category === 'other') return 'Consultation'
    return category.charAt(0).toUpperCase() + category.slice(1)
}

function timeAgo(dateStr: string): string {
    const now = Date.now()
    const then = new Date(dateStr).getTime()
    const diffSec = Math.floor((now - then) / 1000)
    if (diffSec < 60) return 'just now'
    const diffMin = Math.floor(diffSec / 60)
    if (diffMin < 60) return `${diffMin}m ago`
    const diffHr = Math.floor(diffMin / 60)
    if (diffHr < 24) return `${diffHr}h ago`
    const diffDay = Math.floor(diffHr / 24)
    if (diffDay === 1) return '1 day ago'
    return `${diffDay} days ago`
}

function formatAmount(amount: number | null): string {
    if (amount === null) return ''
    return `₦${Number(amount).toLocaleString()}`
}

export function DisputeResolutionCenter() {
    const [selectedFilter, setSelectedFilter] = useState('All')
    const [searchQuery, setSearchQuery] = useState('')
    const [disputes, setDisputes] = useState<DisputeRecord[]>([])
    const [loading, setLoading] = useState(true)
    const [actionLoading, setActionLoading] = useState<string | null>(null)
    const [adminId, setAdminId] = useState<string | null>(null)

    // New Dispute dialog state
    const [newDisputeOpen, setNewDisputeOpen] = useState(false)
    const [newDispute, setNewDispute] = useState({
        title: '',
        description: '',
        category: 'payment' as DisputeRecord['category'],
        amount: '',
        risk_level: 'low' as DisputeRecord['risk_level'],
        patient_id: '',
        doctor_id: '',
        transaction_id: '',
    })

    // Evidence dialog state
    const [evidenceDispute, setEvidenceDispute] = useState<DisputeRecord | null>(null)

    // Resolve dialog state
    const [resolveDispute, setResolveDispute] = useState<DisputeRecord | null>(null)
    const [resolveNotes, setResolveNotes] = useState('')
    const [resolveAction, setResolveAction] = useState<'resolved' | 'dismissed'>('resolved')

    const supabase = createClient()

    const fetchDisputes = useCallback(async () => {
        const { data, error } = await supabase
            .from('disputes')
            .select(`
                *,
                patient:profiles!disputes_patient_id_fkey(full_name, avatar_url),
                doctor:profiles!disputes_doctor_id_fkey(full_name, avatar_url)
            `)
            .order('created_at', { ascending: false })

        if (error) {
            toast.error('Failed to load disputes')
            return
        }
        setDisputes(data || [])
    }, [supabase])

    useEffect(() => {
        const init = async () => {
            const { data: { user } } = await supabase.auth.getUser()
            if (user) setAdminId(user.id)
            await fetchDisputes()
            setLoading(false)
        }
        init()
    }, [fetchDisputes, supabase])

    const filteredDisputes = disputes.filter(d => {
        if (selectedFilter === 'Resolved') {
            if (d.status !== 'resolved' && d.status !== 'dismissed') return false
        } else if (selectedFilter !== 'All') {
            if (categoryToFilter(d.category) !== selectedFilter) return false
        }
        if (searchQuery) {
            const q = searchQuery.toLowerCase()
            return (
                d.title.toLowerCase().includes(q) ||
                d.description?.toLowerCase().includes(q) ||
                d.transaction_id.toLowerCase().includes(q) ||
                d.patient?.full_name?.toLowerCase().includes(q) ||
                d.doctor?.full_name?.toLowerCase().includes(q)
            )
        }
        return true
    })

    const stats = {
        open: disputes.filter(d => d.status === 'open').length,
        underReview: disputes.filter(d => d.status === 'under_review').length,
        resolved: disputes.filter(d => d.status === 'resolved' || d.status === 'dismissed').length,
        highRisk: disputes.filter(d => d.risk_level === 'high' && d.status !== 'resolved' && d.status !== 'dismissed').length,
    }

    const handleResolve = async () => {
        if (!resolveDispute) return
        setActionLoading(resolveDispute.id)
        try {
            const { error } = await supabase
                .from('disputes')
                .update({
                    status: resolveAction,
                    resolution_notes: resolveNotes || null,
                    resolved_at: new Date().toISOString(),
                    resolved_by: adminId,
                })
                .eq('id', resolveDispute.id)

            if (error) throw error
            toast.success(resolveAction === 'resolved' ? 'Dispute resolved' : 'Dispute dismissed')
            setResolveDispute(null)
            setResolveNotes('')
            await fetchDisputes()
        } catch (err: unknown) {
            toast.error('Failed: ' + (err instanceof Error ? err.message : String(err)))
        } finally {
            setActionLoading(null)
        }
    }

    const handleEscalate = async (dispute: DisputeRecord) => {
        setActionLoading(dispute.id)
        try {
            const newRisk = dispute.risk_level === 'high' ? 'high' : dispute.risk_level === 'medium' ? 'high' : 'medium'
            const newStatus = dispute.status === 'open' ? 'under_review' : dispute.status
            const { error } = await supabase
                .from('disputes')
                .update({ risk_level: newRisk, status: newStatus })
                .eq('id', dispute.id)

            if (error) throw error
            toast.success(`Escalated to ${newRisk} risk`)
            await fetchDisputes()
        } catch (err: unknown) {
            toast.error('Failed: ' + (err instanceof Error ? err.message : String(err)))
        } finally {
            setActionLoading(null)
        }
    }

    const handleCreateDispute = async () => {
        if (!newDispute.title.trim()) {
            toast.error('Title is required')
            return
        }
        setActionLoading('new')
        try {
            const insertData: Record<string, unknown> = {
                title: newDispute.title.trim(),
                description: newDispute.description.trim() || null,
                category: newDispute.category,
                risk_level: newDispute.risk_level,
                transaction_id: newDispute.transaction_id.trim() || `DSP-${Date.now()}`,
                user_id: adminId,
                patient_id: newDispute.patient_id.trim() || null,
                doctor_id: newDispute.doctor_id.trim() || null,
                amount: newDispute.amount ? Number(newDispute.amount) : null,
            }
            const { error } = await supabase.from('disputes').insert(insertData)
            if (error) throw error
            toast.success('Dispute created')
            setNewDisputeOpen(false)
            setNewDispute({ title: '', description: '', category: 'payment', amount: '', risk_level: 'low', patient_id: '', doctor_id: '', transaction_id: '' })
            await fetchDisputes()
        } catch (err: unknown) {
            toast.error('Failed: ' + (err instanceof Error ? err.message : String(err)))
        } finally {
            setActionLoading(null)
        }
    }

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-[60vh]">
                <Loader2 className="h-8 w-8 animate-spin text-indigo-600" />
            </div>
        )
    }

    return (
        <div className="max-w-7xl mx-auto p-4 md:p-8 space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
            {/* Header */}
            <div className="flex flex-col md:flex-row md:items-start justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-black text-slate-900 tracking-tight">Dispute Resolution Center</h1>
                    <p className="text-slate-500 mt-1">Manage, review and resolve disputes fairly and efficiently.</p>
                </div>
                <div className="flex items-center gap-3">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                        <input
                            type="text"
                            placeholder="Search disputes..."
                            value={searchQuery}
                            onChange={e => setSearchQuery(e.target.value)}
                            className="pl-9 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors shadow-sm text-sm font-medium text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-400 w-64"
                        />
                    </div>
                    <Dialog open={newDisputeOpen} onOpenChange={setNewDisputeOpen}>
                        <DialogTrigger render={
                            <Button className="flex items-center gap-2 px-4 py-2.5 rounded-xl shadow-sm font-semibold">
                                <FilePlus className="w-4 h-4" />
                                <span>New Dispute</span>
                            </Button>
                        } />
                        <DialogContent className="sm:max-w-md">
                            <DialogHeader>
                                <DialogTitle>Create New Dispute</DialogTitle>
                                <DialogDescription>Log a new dispute for investigation.</DialogDescription>
                            </DialogHeader>
                            <div className="space-y-4">
                                <Input
                                    placeholder="Dispute title"
                                    value={newDispute.title}
                                    onChange={e => setNewDispute(p => ({ ...p, title: e.target.value }))}
                                />
                                <Textarea
                                    placeholder="Description..."
                                    value={newDispute.description}
                                    onChange={e => setNewDispute(p => ({ ...p, description: e.target.value }))}
                                    rows={3}
                                />
                                <div className="grid grid-cols-2 gap-3">
                                    <select
                                        value={newDispute.category}
                                        onChange={e => setNewDispute(p => ({ ...p, category: e.target.value as DisputeRecord['category'] }))}
                                        className="col-span-1 border border-slate-200 rounded-lg px-3 py-2 text-sm bg-white"
                                    >
                                        <option value="payment">Payment</option>
                                        <option value="consultation">Consultation</option>
                                        <option value="refund">Refund</option>
                                        <option value="fraud">Fraud</option>
                                        <option value="behavior">Behavior</option>
                                        <option value="other">Other</option>
                                    </select>
                                    <select
                                        value={newDispute.risk_level}
                                        onChange={e => setNewDispute(p => ({ ...p, risk_level: e.target.value as DisputeRecord['risk_level'] }))}
                                        className="col-span-1 border border-slate-200 rounded-lg px-3 py-2 text-sm bg-white"
                                    >
                                        <option value="low">Low Risk</option>
                                        <option value="medium">Medium Risk</option>
                                        <option value="high">High Risk</option>
                                    </select>
                                </div>
                                <Input
                                    placeholder="Amount (₦)"
                                    type="number"
                                    value={newDispute.amount}
                                    onChange={e => setNewDispute(p => ({ ...p, amount: e.target.value }))}
                                />
                                <Input
                                    placeholder="Patient ID (optional)"
                                    value={newDispute.patient_id}
                                    onChange={e => setNewDispute(p => ({ ...p, patient_id: e.target.value }))}
                                />
                                <Input
                                    placeholder="Doctor ID (optional)"
                                    value={newDispute.doctor_id}
                                    onChange={e => setNewDispute(p => ({ ...p, doctor_id: e.target.value }))}
                                />
                                <Input
                                    placeholder="Transaction ID (optional)"
                                    value={newDispute.transaction_id}
                                    onChange={e => setNewDispute(p => ({ ...p, transaction_id: e.target.value }))}
                                />
                            </div>
                            <DialogFooter>
                                <Button variant="outline" onClick={() => setNewDisputeOpen(false)}>Cancel</Button>
                                <Button onClick={handleCreateDispute} disabled={actionLoading === 'new'}>
                                    {actionLoading === 'new' && <Loader2 className="h-4 w-4 animate-spin mr-2" />}
                                    Create Dispute
                                </Button>
                            </DialogFooter>
                        </DialogContent>
                    </Dialog>
                </div>
            </div>

            {/* Stat Cards */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <StatCard title="Open Disputes" value={stats.open} icon={AlertTriangle} color="orange" />
                <StatCard title="Pending Review" value={stats.underReview} icon={Clock} color="amber" />
                <StatCard title="Resolved Cases" value={stats.resolved} icon={CheckCircle} color="emerald" />
                <StatCard title="High Risk" value={stats.highRisk} icon={Flag} color="red" />
            </div>

            {/* Filters */}
            <div className="flex overflow-x-auto pb-2 scrollbar-hide gap-2">
                {FILTERS.map(f => (
                    <button
                        key={f}
                        onClick={() => setSelectedFilter(f)}
                        className={`whitespace-nowrap px-5 py-2 rounded-full font-semibold text-sm transition-all ${
                            selectedFilter === f
                                ? 'bg-indigo-600 text-white shadow-md'
                                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                        }`}
                    >
                        {f}
                        {f === 'Resolved' && (
                            <span className="ml-1.5 inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 rounded-full bg-white/20 text-[10px]">
                                {stats.resolved}
                            </span>
                        )}
                    </button>
                ))}
            </div>

            {/* Main Content Layout */}
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                {/* Left Column - Disputes List */}
                <div className="lg:col-span-8 space-y-4">
                    {filteredDisputes.length === 0 ? (
                        <div className="bg-white p-12 rounded-2xl border border-slate-200 shadow-sm text-center">
                            <CheckCircle className="w-12 h-12 text-slate-300 mx-auto mb-4" />
                            <p className="text-lg font-semibold text-slate-900">No disputes found</p>
                            <p className="text-sm text-slate-500 mt-1">
                                {selectedFilter === 'All'
                                    ? 'All clear — no disputes to review right now.'
                                    : `No ${selectedFilter.toLowerCase()} disputes to review.`}
                            </p>
                        </div>
                    ) : (
                        filteredDisputes.map(dispute => (
                            <DisputeCard
                                key={dispute.id}
                                dispute={dispute}
                                actionLoading={actionLoading}
                                onResolve={() => setResolveDispute(dispute)}
                                onEscalate={() => handleEscalate(dispute)}
                                onViewEvidence={() => setEvidenceDispute(dispute)}
                            />
                        ))
                    )}
                </div>

                {/* Right Column - Quick Actions & Insights */}
                <div className="lg:col-span-4 space-y-8">
                    {/* Quick Actions */}
                    <div>
                        <h3 className="text-lg font-bold text-slate-900 mb-4">Quick Actions</h3>
                        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                            <QuickActionItem
                                icon={FilePlus} color="emerald" title="New Dispute" sub="Create new dispute"
                                onClick={() => setNewDisputeOpen(true)}
                            />
                            <QuickActionItem
                                icon={AlertTriangle} color="orange" title="Escalated Cases" sub={`${stats.highRisk} high risk active`}
                                onClick={() => setSelectedFilter('All')}
                            />
                            <QuickActionItem
                                icon={ShieldAlert} color="red" title="Fraud Monitoring" sub="High risk activities"
                                onClick={() => setSelectedFilter('Fraud')}
                                isLast
                            />
                        </div>
                    </div>

                    {/* Insights */}
                    <div>
                        <div className="flex items-center justify-between mb-4">
                            <h3 className="text-lg font-bold text-slate-900">Dispute Insights</h3>
                        </div>
                        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
                            {/* Donut Chart */}
                            <div className="relative w-40 h-40 mx-auto mb-8">
                                <div
                                    className="absolute inset-0 rounded-full"
                                    style={{
                                        background: (() => {
                                            const total = disputes.length || 1
                                            const openPct = (stats.open / total) * 100
                                            const reviewPct = (stats.underReview / total) * 100
                                            const resolvedPct = (stats.resolved / total) * 100
                                            const riskPct = 100 - openPct - reviewPct - resolvedPct
                                            return `conic-gradient(#10b981 0% ${resolvedPct}%, #f97316 ${resolvedPct}% ${resolvedPct + openPct}%, #f59e0b ${resolvedPct + openPct}% ${resolvedPct + openPct + reviewPct}%, #ef4444 ${resolvedPct + openPct + reviewPct}% 100%)`
                                        })()
                                    }}
                                />
                                <div className="absolute inset-4 bg-white rounded-full flex flex-col items-center justify-center">
                                    <span className="text-3xl font-black text-slate-900">{disputes.length}</span>
                                    <span className="text-xs font-semibold text-slate-500">Total</span>
                                </div>
                            </div>
                            <div className="space-y-3">
                                <InsightLegend color="bg-orange-500" label="Open" value={`${stats.open} (${disputes.length ? Math.round((stats.open / disputes.length) * 100) : 0}%)`} />
                                <InsightLegend color="bg-amber-500" label="Pending" value={`${stats.underReview} (${disputes.length ? Math.round((stats.underReview / disputes.length) * 100) : 0}%)`} />
                                <InsightLegend color="bg-emerald-500" label="Resolved" value={`${stats.resolved} (${disputes.length ? Math.round((stats.resolved / disputes.length) * 100) : 0}%)`} />
                                <InsightLegend color="bg-red-500" label="Escalated" value={`${stats.highRisk} (${disputes.length ? Math.round((stats.highRisk / disputes.length) * 100) : 0}%)`} />
                            </div>
                        </div>
                    </div>

                    {/* Security Banner */}
                    <div className="bg-indigo-50 p-6 rounded-2xl border border-indigo-100">
                        <div className="w-10 h-10 bg-white rounded-xl flex items-center justify-center shadow-sm mb-4">
                            <ShieldCheck className="w-5 h-5 text-indigo-600" />
                        </div>
                        <p className="font-bold text-slate-900 leading-snug mb-4">
                            We ensure fair, secure and transparent resolution for all parties involved.
                        </p>
                        <button className="text-indigo-600 font-bold flex items-center gap-1 hover:text-indigo-700">
                            Learn more <ChevronRight className="w-4 h-4" />
                        </button>
                    </div>
                </div>
            </div>

            {/* Resolve Dialog */}
            <Dialog open={!!resolveDispute} onOpenChange={(open) => { if (!open) { setResolveDispute(null); setResolveNotes('') } }}>
                <DialogContent className="sm:max-w-md">
                    <DialogHeader>
                        <DialogTitle>{resolveAction === 'resolved' ? 'Resolve Dispute' : 'Dismiss Dispute'}</DialogTitle>
                        <DialogDescription>
                            {resolveAction === 'resolved'
                                ? 'Mark this dispute as resolved. The parties will be notified.'
                                : 'Dismiss this dispute. It will be archived.'}
                        </DialogDescription>
                    </DialogHeader>
                    {resolveDispute && (
                        <div className="space-y-3 text-sm">
                            <p className="font-semibold text-slate-900">{resolveDispute.title}</p>
                            {resolveDispute.amount && <p className="text-slate-600">Amount: {formatAmount(resolveDispute.amount)}</p>}
                            <div className="flex gap-2">
                                <Button
                                    size="sm"
                                    variant={resolveAction === 'resolved' ? 'default' : 'outline'}
                                    onClick={() => setResolveAction('resolved')}
                                >
                                    <CheckCircle className="w-4 h-4 mr-1" /> Resolve
                                </Button>
                                <Button
                                    size="sm"
                                    variant={resolveAction === 'dismissed' ? 'destructive' : 'outline'}
                                    onClick={() => setResolveAction('dismissed')}
                                >
                                    <XCircle className="w-4 h-4 mr-1" /> Dismiss
                                </Button>
                            </div>
                            <Textarea
                                placeholder="Resolution notes (optional)..."
                                value={resolveNotes}
                                onChange={e => setResolveNotes(e.target.value)}
                                rows={3}
                            />
                        </div>
                    )}
                    <DialogFooter>
                        <Button variant="outline" onClick={() => { setResolveDispute(null); setResolveNotes('') }}>Cancel</Button>
                        <Button
                            variant={resolveAction === 'resolved' ? 'default' : 'destructive'}
                            onClick={handleResolve}
                            disabled={!!actionLoading}
                        >
                            {actionLoading && <Loader2 className="h-4 w-4 animate-spin mr-2" />}
                            {resolveAction === 'resolved' ? 'Confirm Resolve' : 'Confirm Dismiss'}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {/* Evidence Dialog */}
            <Dialog open={!!evidenceDispute} onOpenChange={(open) => { if (!open) setEvidenceDispute(null) }}>
                <DialogContent className="sm:max-w-md">
                    <DialogHeader>
                        <DialogTitle>Dispute Details</DialogTitle>
                        <DialogDescription>Evidence and transaction info for this dispute.</DialogDescription>
                    </DialogHeader>
                    {evidenceDispute && (
                        <div className="space-y-4 text-sm">
                            <div className="bg-slate-50 p-4 rounded-xl space-y-2">
                                <p className="font-bold text-slate-900">{evidenceDispute.title}</p>
                                {evidenceDispute.description && <p className="text-slate-600">{evidenceDispute.description}</p>}
                            </div>
                            <div className="grid grid-cols-2 gap-3">
                                <div className="bg-slate-50 p-3 rounded-xl">
                                    <p className="text-xs font-semibold text-slate-500 mb-1">Transaction ID</p>
                                    <p className="font-mono text-xs text-slate-900">{evidenceDispute.transaction_id}</p>
                                </div>
                                <div className="bg-slate-50 p-3 rounded-xl">
                                    <p className="text-xs font-semibold text-slate-500 mb-1">Amount</p>
                                    <p className="font-semibold text-slate-900">{formatAmount(evidenceDispute.amount) || 'N/A'}</p>
                                </div>
                                <div className="bg-slate-50 p-3 rounded-xl">
                                    <p className="text-xs font-semibold text-slate-500 mb-1">Patient</p>
                                    <p className="font-semibold text-slate-900">{evidenceDispute.patient?.full_name || 'Unknown'}</p>
                                </div>
                                <div className="bg-slate-50 p-3 rounded-xl">
                                    <p className="text-xs font-semibold text-slate-500 mb-1">Doctor</p>
                                    <p className="font-semibold text-slate-900">{evidenceDispute.doctor?.full_name || 'Unknown'}</p>
                                </div>
                            </div>
                            {evidenceDispute.resolution_notes && (
                                <div className="bg-emerald-50 p-3 rounded-xl border border-emerald-100">
                                    <p className="text-xs font-semibold text-emerald-700 mb-1">Resolution Notes</p>
                                    <p className="text-sm text-emerald-900">{evidenceDispute.resolution_notes}</p>
                                </div>
                            )}
                        </div>
                    )}
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setEvidenceDispute(null)}>Close</Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    )
}

function StatCard({ title, value, icon: Icon, color }: { title: string; value: number; icon: any; color: string }) {
    const colorStyles: Record<string, string> = {
        orange: 'bg-orange-50 text-orange-600 border-orange-100',
        amber: 'bg-amber-50 text-amber-600 border-amber-100',
        emerald: 'bg-emerald-50 text-emerald-600 border-emerald-100',
        red: 'bg-red-50 text-red-600 border-red-100',
    }

    return (
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col justify-between">
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center mb-4 ${colorStyles[color]}`}>
                <Icon className="w-5 h-5" />
            </div>
            <div>
                <h3 className="text-3xl font-black text-slate-900">{value}</h3>
                <p className="text-sm font-semibold text-slate-500 mt-1">{title}</p>
            </div>
        </div>
    )
}

function DisputeCard({
    dispute,
    actionLoading,
    onResolve,
    onEscalate,
    onViewEvidence,
}: {
    dispute: DisputeRecord
    actionLoading: string | null
    onResolve: () => void
    onEscalate: () => void
    onViewEvidence: () => void
}) {
    const categoryIcons: Record<string, any> = {
        payment: Wallet,
        consultation: Video,
        refund: RefreshCcw,
        fraud: Flag,
        behavior: MessageSquare,
        other: AlertTriangle,
    }
    const categoryColors: Record<string, string> = {
        payment: 'bg-orange-50 text-orange-600',
        consultation: 'bg-blue-50 text-blue-600',
        refund: 'bg-emerald-50 text-emerald-600',
        fraud: 'bg-red-50 text-red-600',
        behavior: 'bg-purple-50 text-purple-600',
        other: 'bg-slate-50 text-slate-600',
    }
    const statusBadge: Record<string, { label: string; className: string }> = {
        open: { label: 'Open', className: 'bg-orange-50 text-orange-700 border-orange-100' },
        under_review: { label: 'Under Review', className: 'bg-amber-50 text-amber-700 border-amber-100' },
        resolved: { label: 'Resolved', className: 'bg-emerald-50 text-emerald-700 border-emerald-100' },
        dismissed: { label: 'Dismissed', className: 'bg-slate-50 text-slate-600 border-slate-100' },
    }

    const Icon = categoryIcons[dispute.category] || AlertTriangle
    const badge = statusBadge[dispute.status] || statusBadge.open
    const isHighRisk = dispute.risk_level === 'high'
    const isActive = dispute.status === 'open' || dispute.status === 'under_review'

    return (
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition-shadow cursor-pointer group">
            <div className="flex items-start gap-4">
                <div className={`shrink-0 w-12 h-12 rounded-xl flex items-center justify-center ${categoryColors[dispute.category]}`}>
                    <Icon className="w-6 h-6" />
                </div>
                <div className="flex-1 min-w-0">
                    <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-2 mb-2">
                        <h4 className="text-base font-bold text-slate-900 truncate pr-4">{dispute.title}</h4>
                        <div className="flex items-center gap-2 shrink-0">
                            {isHighRisk && isActive && (
                                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full border text-[10px] font-bold uppercase tracking-wider bg-red-50 text-red-700 border-red-100">
                                    <AlertTriangle className="w-3 h-3" />
                                    High Risk
                                </span>
                            )}
                            <span className={`inline-flex items-center px-2.5 py-1 rounded-full border text-[10px] font-bold uppercase tracking-wider ${badge.className}`}>
                                {badge.label}
                            </span>
                        </div>
                    </div>
                    {dispute.description && (
                        <p className="text-sm text-slate-600 leading-relaxed mb-4 line-clamp-2">{dispute.description}</p>
                    )}
                </div>
            </div>

            {/* Parties */}
            <div className="flex items-center gap-3 bg-slate-50 p-3 rounded-xl mb-4">
                <img
                    src={dispute.patient?.avatar_url || `https://i.pravatar.cc/100?u=${dispute.patient_id || 'p'}`}
                    className="w-8 h-8 rounded-full shadow-sm"
                    alt="Patient"
                />
                <span className="text-sm font-semibold text-slate-900">{dispute.patient?.full_name || 'Unknown Patient'}</span>
                <span className="text-xs font-bold text-slate-400 uppercase">vs</span>
                <img
                    src={dispute.doctor?.avatar_url || `https://i.pravatar.cc/100?u=${dispute.doctor_id || 'd'}`}
                    className="w-8 h-8 rounded-full shadow-sm"
                    alt="Doctor"
                />
                <span className="text-sm font-semibold text-slate-900">{dispute.doctor?.full_name || 'Unknown Doctor'}</span>
                <div className="ml-auto opacity-0 group-hover:opacity-100 transition-opacity">
                    <ChevronRight className="w-5 h-5 text-slate-400" />
                </div>
            </div>

            {/* Meta + Actions */}
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-3 text-xs font-semibold text-slate-500">
                    <span className="text-slate-700 font-mono">#{dispute.transaction_id.slice(0, 12)}</span>
                    <span className="w-1 h-1 rounded-full bg-slate-300" />
                    <span>{timeAgo(dispute.created_at)}</span>
                    {dispute.amount !== null && (
                        <>
                            <span className="w-1 h-1 rounded-full bg-slate-300" />
                            <span className="text-slate-700">{formatAmount(dispute.amount)}</span>
                        </>
                    )}
                    <span className="px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 text-[10px] font-bold uppercase">
                        {dispute.category}
                    </span>
                </div>
                {isActive && (
                    <div className="flex items-center gap-1.5">
                        <Button
                            size="sm"
                            variant="outline"
                            onClick={onViewEvidence}
                            className="h-7 text-xs"
                        >
                            <Eye className="w-3 h-3 mr-1" /> Evidence
                        </Button>
                        <Button
                            size="sm"
                            variant="ghost"
                            onClick={onEscalate}
                            disabled={actionLoading === dispute.id}
                            className="h-7 text-xs text-amber-600 hover:bg-amber-50"
                        >
                            {actionLoading === dispute.id ? <Loader2 className="w-3 h-3 animate-spin" /> : <Flag className="w-3 h-3 mr-1" />}
                            Escalate
                        </Button>
                        <Button
                            size="sm"
                            onClick={onResolve}
                            className="h-7 text-xs"
                        >
                            <CheckCircle className="w-3 h-3 mr-1" /> Resolve
                        </Button>
                    </div>
                )}
            </div>
        </div>
    )
}

function QuickActionItem({ icon: Icon, color, title, sub, onClick, isLast }: { icon: any; color: string; title: string; sub: string; onClick?: () => void; isLast?: boolean }) {
    const colorStyles: Record<string, string> = {
        emerald: 'bg-emerald-50 text-emerald-600',
        indigo: 'bg-indigo-50 text-indigo-600',
        orange: 'bg-orange-50 text-orange-600',
        red: 'bg-red-50 text-red-600',
    }

    return (
        <button
            onClick={onClick}
            className={`w-full flex items-center gap-4 p-4 hover:bg-slate-50 cursor-pointer transition-colors text-left ${!isLast ? 'border-b border-slate-100' : ''}`}
        >
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${colorStyles[color]}`}>
                <Icon className="w-5 h-5" />
            </div>
            <div className="flex-1">
                <h4 className="text-sm font-bold text-slate-900">{title}</h4>
                <p className="text-xs text-slate-500 font-medium">{sub}</p>
            </div>
            <ChevronRight className="w-4 h-4 text-slate-400" />
        </button>
    )
}

function InsightLegend({ color, label, value }: { color: string; label: string; value: string }) {
    return (
        <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
                <div className={`w-2 h-2 rounded-full ${color}`} />
                <span className="text-sm font-semibold text-slate-700">{label}</span>
            </div>
            <span className="text-sm font-medium text-slate-500">{value}</span>
        </div>
    )
}
