'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { toast } from 'sonner'
import { getPayments, approvePayment, rejectPayment } from '@/lib/queries-client'
import { createClient } from '@/lib/supabase'
import { Loader2, CheckCircle, XCircle, FileText, Wallet } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
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

export function DoctorPaymentReview({ doctorId }: { doctorId: string }) {
    const [loading, setLoading] = useState(true)
    const [payments, setPayments] = useState<any[]>([])
    const [processingId, setProcessingId] = useState<string | null>(null)
    const [rejectDialogId, setRejectDialogId] = useState<string | null>(null)
    const [rejectReason, setRejectReason] = useState('')
    const supabase = createClient()

    useEffect(() => {
        fetchPayments()
    }, [doctorId])

    const fetchPayments = async () => {
        // Fetch payments where recipient_id is this doctor
        const { data, error } = await getPayments(undefined, doctorId)
        if (!error) setPayments(data || [])
        setLoading(false)
    }

    const handleApprove = async (id: string) => {
        setProcessingId(id)
        try {
            const { error } = await approvePayment(id, doctorId)
            if (error) throw error
            toast.success('Payment approved! Patient balance credited.')
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
            const { error } = await rejectPayment(rejectDialogId, rejectReason, doctorId)
            if (error) throw error
            toast.success('Payment rejected')
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
    const totalEarnings = payments.filter(p => p.status === 'approved').reduce((s, p) => s + Number(p.amount), 0)

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Patient Payments</h1>
                    <p className="text-muted-foreground">Verify consultation fees sent directly to you.</p>
                </div>
                <div className="p-3 bg-primary/10 rounded-xl border border-primary/20 flex items-center gap-3">
                    <Wallet className="h-5 w-5 text-primary" />
                    <div>
                        <p className="text-[10px] uppercase font-bold text-muted-foreground leading-none mb-1">Total Revenue</p>
                        <p className="text-lg font-bold leading-none">₦{totalEarnings.toFixed(2)}</p>
                    </div>
                </div>
            </div>

            <div className="grid gap-4 md:grid-cols-3 md:gap-6">
                <Card className="glass-panel border-amber-500/20 bg-amber-500/5 shadow-xl rounded-[2rem] overflow-hidden">
                    <CardHeader className="pb-2">
                        <CardTitle className="text-sm font-medium">Pending Verification</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold text-amber-600">{pendingPayments.length}</div>
                    </CardContent>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <CardTitle className="text-sm font-medium">Approved Payments</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold text-green-600">
                            {payments.filter(p => p.status === 'approved').length}
                        </div>
                    </CardContent>
                </Card>
                <Card>
                    <CardHeader className="pb-2">
                        <CardTitle className="text-sm font-medium">Total Sessions</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold">{payments.length}</div>
                    </CardContent>
                </Card>
            </div>

            <Card className="glass-panel border-none shadow-2xl rounded-[2.5rem] overflow-hidden">
                <CardHeader>
                    <CardTitle>Received Fees & Receipts</CardTitle>
                    <CardDescription>
                        Review proof of payment before crediting the patient's consultation balance.
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>Patient</TableHead>
                                <TableHead>Amount</TableHead>
                                <TableHead>Expected Duration</TableHead>
                                <TableHead>Proof</TableHead>
                                <TableHead>Status</TableHead>
                                <TableHead className="text-right">Actions</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {payments.length === 0 ? (
                                <TableRow>
                                    <TableCell colSpan={6} className="text-center py-8 text-muted-foreground">
                                        No patient payments found
                                    </TableCell>
                                </TableRow>
                            ) : (
                                payments.map((p) => (
                                    <TableRow key={p.id}>
                                        <TableCell>
                                            <div className="font-medium">{p.user?.full_name}</div>
                                            <div className="text-xs text-muted-foreground">{new Date(p.created_at).toLocaleDateString()}</div>
                                        </TableCell>
                                        <TableCell className="font-bold">₦{Number(p.amount).toFixed(2)}</TableCell>
                                        <TableCell>
                                            <Badge variant="outline">{p.duration_minutes || '--'} Minutes</Badge>
                                        </TableCell>
                                        <TableCell>
                                            {p.receipt_url ? (
                                                <button
                                                    onClick={async () => {
                                                        try {
                                                            const { data, error } = await supabase.storage
                                                                .from('payment-receipts')
                                                                .createSignedUrl(p.receipt_url, 60)
                                                            if (error) throw error
                                                            if (data?.signedUrl) window.open(data.signedUrl, '_blank')
                                                        } catch (err: unknown) {
                                                            toast.error('Failed to open receipt: ' + (err instanceof Error ? err.message : String(err)))
                                                        }
                                                    }}
                                                    className="flex items-center gap-1 text-primary hover:underline text-sm bg-transparent border-0 p-0 cursor-pointer"
                                                >
                                                    <FileText className="h-4 w-4" /> View Receipt
                                                </button>
                                            ) : (
                                                <span className="text-xs text-muted-foreground">No Attachment</span>
                                            )}
                                        </TableCell>
                                        <TableCell>
                                            <Badge variant={p.status === 'approved' ? 'default' : p.status === 'pending' ? 'secondary' : 'destructive'}>
                                                {p.status}
                                            </Badge>
                                        </TableCell>
                                        <TableCell className="text-right">
                                            {p.status === 'pending' && (
                                                <div className="flex justify-end gap-2">
                                                    <Dialog
                                                        open={rejectDialogId === p.id}
                                                        onOpenChange={(open) => {
                                                            if (!open) { setRejectDialogId(null); setRejectReason('') }
                                                            else setRejectDialogId(p.id)
                                                        }}
                                                    >
                                                        <DialogTrigger
                                                            render={
                                                                <Button
                                                                    size="sm"
                                                                    variant="ghost"
                                                                    className="text-destructive hover:bg-destructive/10 rounded-xl"
                                                                >
                                                                    <XCircle className="h-4 w-4" />
                                                                </Button>
                                                            }
                                                        />
                                                        <DialogContent>
                                                            <DialogHeader>
                                                                <DialogTitle>Reject Payment</DialogTitle>
                                                                <DialogDescription>
                                                                    Explain why the payment proof is invalid.
                                                                </DialogDescription>
                                                            </DialogHeader>
                                                            <Textarea
                                                                placeholder="e.g. Invalid receipt image..."
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
                                                        className="rounded-xl shadow-lg shadow-primary/20"
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
