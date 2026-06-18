'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { createNotification } from '@/lib/queries-client'
import { Loader2, CheckCircle, XCircle, ExternalLink, Receipt, Clock } from 'lucide-react'
import { Badge } from '@/components/ui/badge'

export function PaymentVerification({ doctorId }: { doctorId: string }) {
    const [loading, setLoading] = useState(true)
    const [actionLoading, setActionLoading] = useState<string | null>(null)
    const [payments, setPayments] = useState<any[]>([])
    const supabase = createClient()

    useEffect(() => {
        fetchPendingPayments()
    }, [doctorId])

    const fetchPendingPayments = async () => {
        setLoading(true)
        const { data, error } = await supabase
            .from('payments')
            .select('*, profiles!payments_user_id_fkey(full_name, email)')
            .eq('recipient_id', doctorId)
            .eq('status', 'pending')
            .order('created_at', { ascending: false })

        if (!error) setPayments(data || [])
        setLoading(false)
    }

    const handleVerify = async (paymentId: string, status: 'approved' | 'rejected') => {
        setActionLoading(paymentId)
        try {
            const { error } = await supabase
                .from('payments')
                .update({ 
                    status,
                    updated_at: new Date().toISOString()
                })
                .eq('id', paymentId)

            if (error) throw error

            // Create notification for patient
            const payment = payments.find(p => p.id === paymentId)
            if (payment) {
                await createNotification({
                    user_id: payment.user_id,
                    title: status === 'approved' ? 'Payment Approved' : 'Payment Rejected',
                    message: status === 'approved' 
                        ? `Your payment of ₦${payment.amount} has been verified by the doctor.` 
                        : `Your payment of ₦${payment.amount} was rejected. Please contact the doctor.`,
                    type: 'payment',
                    link: '/patient/dashboard'
                })
            }

            toast.success(`Payment ${status} successfully`)
            fetchPendingPayments()
        } catch (err: any) {
            toast.error('Action failed: ' + err.message)
        } finally {
            setActionLoading(null)
        }
    }

    if (loading) return <div className="flex justify-center p-8"><Loader2 className="h-8 w-8 animate-spin" /></div>

    return (
        <Card className="border-primary/10 shadow-2xl rounded-[2.5rem] overflow-hidden glass-panel">
            <CardHeader className="bg-primary/5 pb-8 border-b border-primary/10">
                <div className="flex items-center gap-4">
                    <div className="p-3 bg-primary/10 rounded-2xl">
                        <Receipt className="h-6 w-6 text-primary" />
                    </div>
                    <div>
                        <CardTitle className="text-2xl font-black tracking-tight">Payment Verification</CardTitle>
                        <CardDescription className="font-bold">Approve or reject patient consultation receipts.</CardDescription>
                    </div>
                </div>
            </CardHeader>
            <CardContent className="pt-8">
                {payments.length === 0 ? (
                    <div className="text-center py-20 opacity-50 space-y-4">
                        <CheckCircle className="h-16 w-16 mx-auto text-muted-foreground/30" />
                        <div className="space-y-1">
                            <p className="font-black text-lg tracking-tight">All Clear!</p>
                            <p className="font-bold uppercase tracking-widest text-[10px]">No pending receipts to verify</p>
                        </div>
                    </div>
                ) : (
                    <div className="space-y-6">
                        {payments.map((payment) => (
                            <div key={payment.id} className="group p-6 bg-muted/30 rounded-[2rem] border border-border/50 hover:border-primary/30 transition-all space-y-6">
                                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                                    <div className="flex items-center gap-4">
                                        <div className="h-12 w-12 rounded-2xl bg-background border flex items-center justify-center font-black text-primary">
                                            ₦
                                        </div>
                                        <div>
                                            <p className="font-black text-lg tracking-tight">₦{Number(payment.amount).toFixed(2)}</p>
                                            <p className="text-xs font-bold text-muted-foreground truncate max-w-[200px]">
                                                {payment.profiles?.full_name || 'Anonymous Patient'}
                                            </p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest text-muted-foreground bg-background/50 px-4 py-2 rounded-full border">
                                        <Clock className="h-3 w-3" />
                                        {new Date(payment.created_at).toLocaleString()}
                                    </div>
                                </div>

                                <div className="grid md:grid-cols-2 gap-6 items-center">
                                    <div className="relative group/receipt aspect-video rounded-2xl overflow-hidden border bg-background flex items-center justify-center group-hover:border-primary/50 transition-colors">
                                        {payment.proof_url ? (
                                            <>
                                                <img 
                                                    src={payment.proof_url} 
                                                    alt="Payment Receipt" 
                                                    className="w-full h-full object-contain"
                                                />
                                                <a 
                                                    href={payment.proof_url} 
                                                    target="_blank" 
                                                    rel="noopener noreferrer"
                                                    className="absolute inset-0 bg-black/60 opacity-0 group-hover/receipt:opacity-100 flex flex-col items-center justify-center transition-all gap-2 text-white"
                                                >
                                                    <ExternalLink className="h-8 w-8" />
                                                    <span className="font-black text-[10px] uppercase tracking-[0.2em]">View Full Receipt</span>
                                                </a>
                                            </>
                                        ) : (
                                            <p className="text-[10px] font-black uppercase tracking-widest opacity-30">No attachment</p>
                                        )}
                                    </div>

                                    <div className="flex flex-col gap-3">
                                        <Button 
                                            onClick={() => handleVerify(payment.id, 'approved')}
                                            disabled={!!actionLoading}
                                            className="h-14 rounded-2xl bg-green-600 hover:bg-green-700 font-black uppercase tracking-widest text-xs shadow-xl shadow-green-500/20"
                                        >
                                            {actionLoading === payment.id ? <Loader2 className="h-5 w-5 animate-spin" /> : <CheckCircle className="h-5 w-5 mr-2" />}
                                            Verify & Approve
                                        </Button>
                                        <Button 
                                            variant="outline"
                                            onClick={() => handleVerify(payment.id, 'rejected')}
                                            disabled={!!actionLoading}
                                            className="h-14 rounded-2xl border-destructive/20 hover:bg-destructive/10 text-destructive font-black uppercase tracking-widest text-xs"
                                        >
                                            <XCircle className="h-5 w-5 mr-2" />
                                            Reject Receipt
                                        </Button>
                                    </div>
                                </div>
                                
                                <div className="pt-2 flex items-center gap-2">
                                    <Badge variant="outline" className="rounded-full px-4 py-1.5 font-bold text-[9px] uppercase tracking-widest bg-blue-500/5 text-blue-600 border-blue-500/20">
                                        {payment.duration_minutes}m Session
                                    </Badge>
                                    <Badge variant="outline" className="rounded-full px-4 py-1.5 font-bold text-[9px] uppercase tracking-widest bg-primary/5 text-primary border-primary/20">
                                        Manual Transfer
                                    </Badge>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </CardContent>
        </Card>
    )
}
