'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { Loader2, CreditCard, Clock, FileUp, CheckCircle2, History, Banknote } from 'lucide-react'

interface PaymentDashboardProps {
    userId: string
}

export function PaymentDashboard({ userId }: PaymentDashboardProps) {
    const [loading, setLoading] = useState(true)
    const [doctors, setDoctors] = useState<any[]>([])
    const [selectedDoctor, setSelectedDoctor] = useState<any>(null)
    const [payments, setPayments] = useState<any[]>([])
    const [amount, setAmount] = useState('')
    const [uploading, setUploading] = useState(false)
    const supabase = createClient()

    useEffect(() => {
        loadData()
    }, [userId])

    const loadData = async () => {
        setLoading(true)
        // Load Doctors
        const { data: doctorsData } = await supabase
            .from('profiles')
            .select('id, full_name, consultation_fee, negotiated_fee, payment_instructions')
            .eq('role', 'doctor')
            .eq('verification_status', 'approved')
        
        if (doctorsData) setDoctors(doctorsData)

        // Load Past Payments
        const { data: paymentsData } = await supabase
            .from('payments')
            .select(`
                id, amount, status, created_at, receipt_url,
                recipient:recipient_id ( full_name )
            `)
            .eq('user_id', userId)
            .order('created_at', { ascending: false })

        if (paymentsData) setPayments(paymentsData)
        setLoading(false)
    }

    const handleUploadReceipt = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]
        if (!file || !selectedDoctor || !amount) {
            toast.error('Please select a doctor and enter an amount first.')
            return
        }
        
        setUploading(true)
        try {
            const fileExt = file.name.split('.').pop()
            const fileName = `${userId}/${Date.now()}.${fileExt}`
            
            const { error: uploadError } = await supabase.storage
                .from('payment-receipts')
                .upload(fileName, file)
                
            if (uploadError) throw uploadError

            const { data: { publicUrl } } = supabase.storage.from('payment-receipts').getPublicUrl(fileName)

            const { error: insertError } = await supabase.from('payments').insert({
                user_id: userId,
                recipient_id: selectedDoctor.id,
                amount: parseFloat(amount),
                method: 'manual',
                receipt_url: publicUrl,
                status: 'pending'
            })

            if (insertError) throw insertError

            toast.success('Payment receipt submitted successfully!')
            setAmount('')
            setSelectedDoctor(null)
            loadData()
        } catch (error: any) {
            toast.error('Upload failed: ' + error.message)
        } finally {
            setUploading(false)
        }
    }

    if (loading) {
        return <div className="flex justify-center p-12"><Loader2 className="h-8 w-8 animate-spin" /></div>
    }

    return (
        <div className="space-y-6">
            <div className="grid md:grid-cols-2 gap-6">
                <Card className="border-primary/10 shadow-sm rounded-3xl">
                    <CardHeader className="bg-primary/5 rounded-t-3xl border-b border-primary/10">
                        <CardTitle className="flex items-center gap-2">
                            <Banknote className="h-5 w-5 text-primary" />
                            Submit Doctor Payment
                        </CardTitle>
                        <CardDescription>Select a doctor to view their payment instructions and submit a receipt.</CardDescription>
                    </CardHeader>
                    <CardContent className="pt-6 space-y-4">
                        <div className="space-y-2">
                            <Label>Select Doctor</Label>
                            <select 
                                className="w-full h-12 rounded-xl border px-3"
                                value={selectedDoctor?.id || ''}
                                onChange={(e) => {
                                    const dr = doctors.find(d => d.id === e.target.value)
                                    setSelectedDoctor(dr || null)
                                }}
                            >
                                <option value="">-- Choose a Practitioner --</option>
                                {doctors.map(dr => (
                                    <option key={dr.id} value={dr.id}>Dr. {dr.full_name}</option>
                                ))}
                            </select>
                        </div>

                        {selectedDoctor && (
                            <div className="p-4 bg-muted/30 rounded-2xl border border-dashed space-y-2 mt-4 animate-in fade-in">
                                <Label className="text-xs text-muted-foreground uppercase font-bold tracking-wider">Payment Instructions</Label>
                                <p className="text-sm font-medium leading-relaxed">
                                    {selectedDoctor.payment_instructions || 'No manual instructions provided. Please contact the doctor via messages.'}
                                </p>
                                <div className="pt-2 border-t border-dashed mt-2 flex justify-between items-center text-sm">
                                    <span className="text-muted-foreground">Standard Fee:</span>
                                    <span className="font-bold">₦{selectedDoctor.consultation_fee || 0}</span>
                                </div>
                            </div>
                        )}

                        <div className="space-y-2 pt-2">
                            <Label>Amount Paid</Label>
                            <Input 
                                type="number" 
                                placeholder="Enter amount" 
                                className="h-12 rounded-xl"
                                value={amount}
                                onChange={(e) => setAmount(e.target.value)}
                            />
                        </div>

                        <div className="pt-4 border-t border-dashed mt-4 space-y-4 text-center">
                            <input 
                                type="file" 
                                id="receipt-upload" 
                                className="hidden" 
                                accept="image/*,.pdf"
                                onChange={handleUploadReceipt}
                            />
                            <Button 
                                disabled={uploading || !selectedDoctor || !amount}
                                onClick={() => document.getElementById('receipt-upload')?.click()}
                                className="w-full h-14 rounded-2xl font-bold bg-primary hover:bg-primary/90"
                            >
                                {uploading ? <Loader2 className="h-5 w-5 animate-spin mr-2" /> : <FileUp className="h-5 w-5 mr-2" />}
                                Upload Payment Receipt
                            </Button>
                        </div>
                    </CardContent>
                </Card>

                <Card className="border-primary/10 shadow-sm rounded-3xl overflow-hidden">
                    <CardHeader className="bg-slate-50 border-b">
                        <CardTitle className="flex items-center gap-2">
                            <History className="h-5 w-5 text-slate-500" />
                            Payment History
                        </CardTitle>
                        <CardDescription>Track the status of your manual payments.</CardDescription>
                    </CardHeader>
                    <CardContent className="p-0">
                        {payments.length === 0 ? (
                            <div className="p-8 text-center text-muted-foreground text-sm">
                                No payments recorded yet.
                            </div>
                        ) : (
                            <div className="divide-y">
                                {payments.map((payment) => (
                                    <div key={payment.id} className="p-4 flex items-center justify-between hover:bg-slate-50 transition-colors">
                                        <div>
                                            <p className="font-bold text-sm">Dr. {payment.recipient?.full_name}</p>
                                            <p className="text-xs text-muted-foreground">{new Date(payment.created_at).toLocaleDateString()}</p>
                                            {payment.receipt_url && (
                                                <a href={payment.receipt_url} target="_blank" rel="noreferrer" className="text-[10px] text-primary hover:underline mt-1 inline-block font-medium">View Receipt</a>
                                            )}
                                        </div>
                                        <div className="text-right flex flex-col items-end gap-1">
                                            <span className="font-black">₦{payment.amount}</span>
                                            <span className={`text-[10px] px-2 py-0.5 rounded-full font-bold uppercase ${
                                                payment.status === 'approved' ? 'bg-green-100 text-green-700' :
                                                payment.status === 'rejected' ? 'bg-red-100 text-red-700' :
                                                'bg-amber-100 text-amber-700'
                                            }`}>
                                                {payment.status}
                                            </span>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </CardContent>
                </Card>
            </div>
        </div>
    )
}