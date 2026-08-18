'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { toast } from 'sonner'
import { getPayments, approvePayment, rejectPayment } from '@/lib/queries-client'
import { createClient } from '@/lib/supabase'
import { Loader2, CheckCircle, XCircle, ExternalLink, FileText } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { AdminPayment } from '@/lib/types'
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogDescription,
    DialogFooter,
    DialogTrigger,
} from '@/components/ui/dialog'
import { Textarea } from '@/components/ui/textarea'

export function AdminPaymentReview() {
    const [loading, setLoading] = useState(true)
    const [payments, setPayments] = useState<AdminPayment[]>([])
    const [processingId, setProcessingId] = useState<string | null>(null)
    const [rejectDialogId, setRejectDialogId] = useState<string | null>(null)
    const [rejectReason, setRejectReason] = useState('')
    const [adminId, setAdminId] = useState<string | null>(null)
    const supabase = createClient()

    useEffect(() => {
        const getAdmin = async () => {
            const { data: { user } } = await supabase.auth.getUser()
            if (user) setAdminId(user.id)
        }
        getAdmin()
        fetchPayments()
    }, [])

    const fetchPayments = async () => {
        const { data, error } = await getPayments()
        if (!error) setPayments(data || [])
        setLoading(false)
    }

    const handleApprove = async (id: string) => {
        setProcessingId(id)
        try {
            const result: any = await approvePayment(id, adminId || undefined)
            if (result?.error) throw new Error(result.error.message || 'Failed to approve')
            toast.success('Payment approved successfully')
            fetchPayments()
        } catch (error: unknown) {
            toast.error('Failed to approve: ' + (error instanceof Error ? error.message : String(error)))
        } finally {
            setProcessingId(null)
        }
    }

    const handleReject = async () => {
        if (!rejectDialogId) return
        setProcessingId(rejectDialogId)
        try {
            const { error } = await rejectPayment(rejectDialogId, rejectReason, adminId || undefined)
            if (error) throw error
            toast.success('Payment rejected and patient notified')
            setRejectDialogId(null)
            setRejectReason('')
            fetchPayments()
        } catch (error: unknown) {
            toast.error('Failed to reject: ' + (error instanceof Error ? error.message : String(error)))
        } finally {
            setProcessingId(null)
        }
    }

    if (loading) return <div className="flex justify-center p-8"><Loader2 className="h-8 w-8 animate-spin" /></div>

    const pendingPayments = payments.filter(p => p.status === 'pending')
    const totalApproved = payments.filter(p => p.status === 'approved').reduce((s, p) => s + Number(p.amount), 0)

    return (
        <div className="space-y-6">
            <h1 className="text-3xl font-bold tracking-tight">Payment Verification</h1>

            <div className="grid gap-4 md:grid-cols-3">
                <Card>
                    <CardHeader className="pb-2">
                        <CardTitle className="text-sm font-medium">Pending Review</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold text-amber-600">{pendingPayments.length}</div>
                    </CardContent>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <CardTitle className="text-sm font-medium">Total Approved</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold text-green-600">₦{totalApproved.toFixed(2)}</div>
                    </CardContent>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <CardTitle className="text-sm font-medium">Total Records</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold">{payments.length}</div>
                    </CardContent>
                </Card>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Manual Receipts &amp; Digital Payments</CardTitle>
                    <CardDescription>Review and approve patient payments to enable appointment bookings.</CardDescription>
                </CardHeader>
                <CardContent>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>User / Role</TableHead>
                                <TableHead>Amount</TableHead>
                                <TableHead>Category</TableHead>
                                <TableHead>Method</TableHead>
                                <TableHead>Proof</TableHead>
                                <TableHead>Status</TableHead>
                                <TableHead className="text-right">Actions</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {payments.length === 0 ? (
                                <TableRow>
                                    <TableCell colSpan={7} className="text-center py-8 text-muted-foreground">
                                        No payment records found
                                    </TableCell>
                                </TableRow>
                            ) : (
                                payments.map((p) => (
                                    <TableRow key={p.id}>
                                        <TableCell>
                                            <div className="font-medium text-slate-900">{p.user?.full_name}</div>
                                            <div className="flex items-center gap-2 mt-1">
                                                <Badge variant="outline" className="text-[9px] h-4 uppercase font-bold bg-slate-50 text-slate-500">
                                                    {p.user?.role}
                                                </Badge>
                                                <span className="text-[10px] text-muted-foreground">{new Date(p.created_at).toLocaleDateString()}</span>
                                            </div>
                                        </TableCell>
                                        <TableCell className="font-bold text-slate-900">₦{Number(p.amount).toFixed(2)}</TableCell>
                                        <TableCell>
                                            {p.recipient_id ? (
                                                <div className="flex flex-col">
                                                    <Badge variant="outline" className="w-fit bg-blue-50 text-blue-700 border-blue-200 text-[10px] h-5">Consultation</Badge>
                                                    <span className="text-[9px] text-muted-foreground mt-0.5">To: {p.recipient?.full_name}</span>
                                                </div>
                                            ) : (
                                                <Badge variant="outline" className="bg-purple-50 text-purple-700 border-purple-200 text-[10px] h-5">Platform Sub</Badge>
                                            )}
                                        </TableCell>
                                        <TableCell>
                                            <Badge variant="secondary" className="capitalize text-[10px] h-5">{p.method}</Badge>
                                        </TableCell>
                                        <TableCell>
                                            {p.receipt_url ? (
                                                <button
                                                    onClick={async () => {
                                                        try {
                                                            const url = p.receipt_url!
                                                            const { data, error } = await supabase.storage
                                                                .from('payment-receipts')
                                                                .createSignedUrl(url, 60)
                                                            if (error) throw error
                                                            if (data?.signedUrl) window.open(data.signedUrl, '_blank')
                                                        } catch (err: unknown) {
                                                            toast.error('Failed to open receipt: ' + (err instanceof Error ? err.message : String(err)))
                                                        }
                                                    }}
                                                    className="flex items-center gap-1.5 text-primary hover:text-primary/80 transition-colors text-xs font-semibold bg-primary/5 px-2 py-1 rounded-md border border-primary/10 cursor-pointer"
                                                >
                                                    <FileText className="h-3.5 w-3.5" /> Receipt
                                                </button>
                                            ) : (
                                                <span className="text-xs text-muted-foreground font-mono">{p.transaction_id || 'N/A'}</span>
                                            )}
                                        </TableCell>
                                        <TableCell>
                                            <div className="flex flex-col gap-1">
                                                <Badge variant={p.status === 'approved' ? 'default' : p.status === 'pending' ? 'secondary' : 'destructive'} className="text-[10px] h-5 w-fit">
                                                    {p.status}
                                                </Badge>
                                                {p.auditor && (
                                                    <span className="text-[9px] text-muted-foreground">By: {p.auditor.full_name}</span>
                                                )}
                                            </div>
                                        </TableCell>
                                        <TableCell className="text-right">
                                            {p.status === 'pending' && (
                                                <div className="flex justify-end gap-2">
                                                    {/* Reject with reason dialog */}
                                                    <Dialog
                                                        open={rejectDialogId === p.id}
                                                        onOpenChange={(open) => {
                                                            if (!open) { setRejectDialogId(null); setRejectReason('') }
                                                            else setRejectDialogId(p.id)
                                                        }}
                                                    >
                                                        <DialogTrigger render={
                                                            <Button
                                                                size="sm"
                                                                variant="ghost"
                                                                className="text-destructive hover:bg-destructive/10"
                                                            >
                                                                <XCircle className="h-4 w-4" />
                                                            </Button>
                                                        } />
                                                        <DialogContent>
                                                            <DialogHeader>
                                                                <DialogTitle>Reject Payment</DialogTitle>
                                                                <DialogDescription>
                                                                    Provide a reason for rejection. The patient will be notified.
                                                                </DialogDescription>
                                                            </DialogHeader>
                                                            <Textarea
                                                                placeholder="e.g. Receipt is unclear, please resubmit..."
                                                                value={rejectReason}
                                                                onChange={e => setRejectReason(e.target.value)}
                                                                rows={3}
                                                            />
                                                            <DialogFooter>
                                                                <Button variant="outline" onClick={() => setRejectDialogId(null)}>Cancel</Button>
                                                                <Button
                                                                    variant="destructive"
                                                                    onClick={handleReject}
                                                                    disabled={processingId === p.id}
                                                                >
                                                                    {processingId === p.id ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : null}
                                                                    Confirm Rejection
                                                                </Button>
                                                            </DialogFooter>
                                                        </DialogContent>
                                                    </Dialog>

                                                    <Button
                                                        size="sm"
                                                        variant="default"
                                                        disabled={processingId === p.id}
                                                        onClick={() => handleApprove(p.id)}
                                                    >
                                                        {processingId === p.id ? <Loader2 className="h-3 w-3 animate-spin" /> : <CheckCircle className="h-4 w-4" />}
                                                    </Button>
                                                </div>
                                            )}
                                        </TableCell>
                                    </TableRow>
                                ))
                            )}
                        </TableBody>
                    </Table>
                </CardContent>
            </Card>
        </div>
    )
}
