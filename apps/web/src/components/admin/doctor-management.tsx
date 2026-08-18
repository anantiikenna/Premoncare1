'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { getUserFacingError } from '@/lib/user-facing-errors'
import { Loader2, ShieldCheck, UserX, MessageSquare, ShieldAlert, FileText, Search, Banknote, ScanFace, Send, X, AlertTriangle, ZoomIn } from 'lucide-react'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Profile, FeeNegotiationMessage } from '@/lib/types'
import { createNotification } from '@/lib/queries-client'
import { useCallback, useRef } from 'react'
import { ScrollArea } from '@/components/ui/scroll-area'

export function DoctorManagement() {
    const [loading, setLoading] = useState(true)
    const [doctors, setDoctors] = useState<Profile[]>([])
    const [searchTerm, setSearchTerm] = useState('')
    const [processingId, setProcessingId] = useState<string | null>(null)
    const [editingFee, setEditingFee] = useState<{ id: string, fee: string } | null>(null)
    const [adminId, setAdminId] = useState<string | undefined>(undefined)
    const [chatDoctorId, setChatDoctorId] = useState<string | null>(null)
    const [confirmAction, setConfirmAction] = useState<{ doctorId: string; doctorName: string; action: 'approved' | 'rejected' } | null>(null)
    const [docViewer, setDocViewer] = useState<{ url: string; label: string; type: 'image' | 'pdf' } | null>(null)
    const supabase = createClient()

    const fetchDoctors = useCallback(async () => {
        setLoading(true)
        try {
            const { data } = await supabase
                .from('profiles')
                .select('*, auditor:profiles!verified_by(full_name)')
                .or('role.eq.doctor,requested_role.eq.doctor')
                .order('verification_status', { ascending: true }) // Show pending first
            setDoctors((data as unknown as Profile[]) || [])
        } catch (error) {
            console.error('Error fetching doctors:', error)
        } finally {
            setLoading(false)
        }
    }, [supabase])

    useEffect(() => {
        const getAdmin = async () => {
            const { data: { user } } = await supabase.auth.getUser()
            if (user) setAdminId(user.id)
        }
        getAdmin()
        fetchDoctors()
    }, [supabase.auth, fetchDoctors])

    const handleVerify = async (doctorId: string, status: 'approved' | 'rejected') => {
        setProcessingId(doctorId)
        try {
            const doctor = doctors.find(d => d.id === doctorId)
            const updates: Partial<Profile> = { 
                verification_status: status,
                verified_by: adminId
            }

            if (status === 'approved' && doctor && doctor.role !== 'doctor') {
                updates.role = 'doctor'
            }

            const { error } = await supabase
                .from('profiles')
                .update(updates)
                .eq('id', doctorId)

            if (error) throw error

            await createNotification({
                user_id: doctorId,
                title: `Account ${status === 'approved' ? 'Verified' : 'Verification Rejected'}`,
                message: status === 'approved' 
                    ? 'Congratulations! Your professional account has been verified. You now have access to the Doctor Dashboard. Please negotiate your platform fee with the admin to unlock full features.' 
                    : 'Your professional verification was not successful. Please contact support for details.',
                type: 'system',
                link: '/doctor/dashboard'
            })

            toast.success(`Doctor ${status} successfully${updates.role ? ' and promoted to Practitioner role' : ''}`)
            fetchDoctors()
        } catch (error: unknown) {
            console.error('Doctor verification update failed', error)
            toast.error(getUserFacingError(error, 'We could not update this doctor verification. Please try again.'))
        } finally {
            setProcessingId(null)
        }
    }

    const updateFee = async (doctorId: string) => {
        if (!editingFee || !editingFee.fee) return
        setProcessingId(doctorId)
        try {
            const feeValue = parseFloat(editingFee.fee)
            if (isNaN(feeValue) || feeValue < 1000) {
                toast.error('Fee must be at least ₦1,000')
                setProcessingId(null)
                return
            }
            if (feeValue > 1000000) {
                toast.error('Fee cannot exceed ₦1,000,000')
                setProcessingId(null)
                return
            }
            const { error } = await supabase
                .from('profiles')
                .update({ 
                    negotiated_fee: feeValue,
                    fee_status: 'awaiting_doctor_approval',
                    verified_by: adminId // Also record who updated the fee
                })
                .eq('id', doctorId)

            if (error) throw error

            await createNotification({
                user_id: doctorId,
                title: 'Professional Fee Proposal',
                message: `Admin has proposed a monthly subscription fee of ₦${feeValue}. Please review and accept this agreement within your dashboard to unlock practitioner tools.`,
                type: 'payment',
                link: '/doctor/dashboard'
            })

            toast.success('Fee updated and doctor notified')
            setEditingFee(null)
            fetchDoctors()
        } catch (error: unknown) {
            console.error('Doctor fee update failed', error)
            toast.error(getUserFacingError(error, 'We could not update this fee proposal. Please try again.'))
        } finally {
            setProcessingId(null)
        }
    }

    const filteredDoctors = doctors.filter(doc => 
        doc.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        doc.specialty?.toLowerCase().includes(searchTerm.toLowerCase())
    )

    if (loading) return <div className="flex justify-center p-12"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>

    return (
        <div className="space-y-6">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div className="relative flex-1 max-w-md">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input 
                        placeholder="Search doctors by name or specialty..." 
                        className="pl-10 h-11"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
            </div>

            <div className="grid gap-6">
                {filteredDoctors.length === 0 ? (
                    <div className="text-center py-20 bg-muted/20 rounded-2xl border-2 border-dashed">
                        <p className="text-muted-foreground">No doctors found matching your search.</p>
                    </div>
                ) : (
                    filteredDoctors.map((doc) => (
                        <Card key={doc.id} className="overflow-hidden border-primary/10">
                            <CardHeader className="bg-muted/30 pb-4">
                                <div className="flex flex-col md:flex-row justify-between md:items-center gap-4">
                                    <div className="flex items-center gap-4">
                                        <Avatar className="h-12 w-12 border-2 border-background">
                                            <AvatarImage src={doc.avatar_url} />
                                            <AvatarFallback>{doc.full_name?.charAt(0)}</AvatarFallback>
                                        </Avatar>
                                        <div>
                                            <CardTitle className="text-lg">
                                                {doc.verification_status === 'approved' ? 'Dr. ' : ''}{doc.full_name}
                                            </CardTitle>
                                            <CardDescription>{doc.specialty || 'General Practitioner'}</CardDescription>
                                            <div className="flex flex-col gap-0.5 mt-1">
                                                {doc.medical_license_number && (
                                                    <span className="text-[10px] text-muted-foreground uppercase tracking-wider font-bold">
                                                        License No: <span className="text-primary">{doc.medical_license_number}</span>
                                                    </span>
                                                )}
                                                {doc.languages_spoken && (
                                                    <span className="text-[10px] text-muted-foreground uppercase tracking-wider font-bold">
                                                        Languages: <span className="text-foreground">{doc.languages_spoken}</span>
                                                    </span>
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                    <div className="flex flex-wrap gap-2">
                                         <Badge variant={doc.verification_status === 'approved' ? 'default' : 'secondary'} className={doc.verification_status === 'approved' ? 'bg-green-600' : 'bg-amber-50 text-amber-700 border-amber-200'}>
                                             {doc.verification_status === 'pending' ? 'Review Required' : `Verified: ${doc.verification_status}`}
                                         </Badge>
                                         <Badge 
                                            variant={doc.subscription_status === 'active' ? 'default' : 'outline'} 
                                            className={doc.subscription_status === 'active' ? 'bg-indigo-600' : 'text-slate-500 border-slate-200'}
                                         >
                                             {doc.subscription_status === 'active' ? 'Paid / Active' : 'Unpaid / Locked'}
                                         </Badge>
                                         <Badge variant={doc.role === 'doctor' ? 'outline' : 'secondary'} className={doc.role === 'doctor' ? 'border-primary text-primary' : 'bg-blue-50 text-blue-700 border-blue-200'}>
                                             {doc.role === 'doctor' ? 'Practitioner' : 'Induction Candidate'}
                                         </Badge>
                                         <Badge variant="outline" className="font-mono">
                                             Fee: {doc.negotiated_fee ? `₦${doc.negotiated_fee}/mo` : 'Negotiating...'}
                                         </Badge>
                                         <div className="flex gap-1" title="Wizard Step Completion">
                                             <div className={`h-2 w-2 rounded-full ${doc.specialty ? 'bg-green-500' : 'bg-slate-200'}`} />
                                             <div className={`h-2 w-2 rounded-full ${doc.verification_document_url ? 'bg-green-500' : 'bg-slate-200'}`} />
                                             <div className={`h-2 w-2 rounded-full ${doc.identity_document_url ? 'bg-green-500' : 'bg-slate-200'}`} />
                                             <div className={`h-2 w-2 rounded-full ${doc.address_document_url ? 'bg-green-500' : 'bg-slate-200'}`} />
                                             <div className={`h-2 w-2 rounded-full ${doc.live_selfie_url ? 'bg-green-500' : 'bg-slate-200'}`} />
                                         </div>
                                     </div>
                                </div>
                            </CardHeader>
                            <CardContent className="pt-6 grid md:grid-cols-2 gap-8">
                                <div className="space-y-4">
                                    <h4 className="text-sm font-bold uppercase tracking-wider text-muted-foreground">Verification Actions</h4>
                                     <div className="flex flex-col gap-3">
                                         <div className="flex gap-2">
                                            <Button 
                                                size="sm" 
                                                variant="outline"
                                                className="flex-1 hover:bg-green-50 hover:text-green-700 hover:border-green-200"
                                                onClick={() => setConfirmAction({ doctorId: doc.id, doctorName: doc.full_name, action: 'approved' })}
                                                disabled={processingId === doc.id || doc.verification_status === 'approved'}
                                            >
                                                <ShieldCheck className="h-4 w-4 mr-2" />
                                                Approve Docs
                                            </Button>
                                            <Button 
                                                size="sm" 
                                                variant="ghost"
                                                className="flex-1 text-red-600 hover:bg-red-50"
                                                onClick={() => setConfirmAction({ doctorId: doc.id, doctorName: doc.full_name, action: 'rejected' })}
                                                disabled={processingId === doc.id || doc.verification_status === 'rejected'}
                                            >
                                                <UserX className="h-4 w-4 mr-2" />
                                                Reject
                                            </Button>
                                        </div>
                                        
                                         <div className="grid grid-cols-3 gap-2">
                                            {doc.verification_document_url && (
                                                <Button 
                                                    variant="secondary" 
                                                    size="sm" 
                                                    className="w-full text-[10px] h-8 px-1"
                                                    onClick={async () => {
                                                        if (!doc.verification_document_url) return
                                                        const { data } = await supabase.storage.from('doctor-verifications').createSignedUrl(doc.verification_document_url, 600)
                                                        if (data?.signedUrl) {
                                                            const isImage = /\.(jpg|jpeg|png|gif|webp)$/i.test(doc.verification_document_url)
                                                            setDocViewer({ url: data.signedUrl, label: 'Medical License', type: isImage ? 'image' : 'pdf' })
                                                        }
                                                    }}
                                                >
                                                    <FileText className="h-3 w-3 mr-1" />
                                                    License
                                                </Button>
                                            )}
                                            {doc.identity_document_url && (
                                                <Button 
                                                    variant="secondary" 
                                                    size="sm" 
                                                    className="w-full text-[10px] h-8 px-1"
                                                    onClick={async () => {
                                                        if (!doc.identity_document_url) return
                                                        const { data } = await supabase.storage.from('doctor-identities').createSignedUrl(doc.identity_document_url, 600)
                                                        if (data?.signedUrl) {
                                                            const isImage = /\.(jpg|jpeg|png|gif|webp)$/i.test(doc.identity_document_url)
                                                            setDocViewer({ url: data.signedUrl, label: 'Government ID', type: isImage ? 'image' : 'pdf' })
                                                        }
                                                    }}
                                                >
                                                    <ShieldCheck className="h-3 w-3 mr-1" />
                                                    Govt ID
                                                </Button>
                                            )}
                                            {doc.address_document_url && (
                                                <Button 
                                                    variant="secondary" 
                                                    size="sm" 
                                                    className="w-full text-[10px] h-8 px-1"
                                                    onClick={async () => {
                                                        if (!doc.address_document_url) return
                                                        const { data } = await supabase.storage.from('doctor-identities').createSignedUrl(doc.address_document_url, 600)
                                                        if (data?.signedUrl) {
                                                            const isImage = /\.(jpg|jpeg|png|gif|webp)$/i.test(doc.address_document_url)
                                                            setDocViewer({ url: data.signedUrl, label: 'Utility Bill', type: isImage ? 'image' : 'pdf' })
                                                        }
                                                    }}
                                                >
                                                    <FileText className="h-3 w-3 mr-1" />
                                                    Utility Bill
                                                </Button>
                                            )}
                                         </div>

                                         {doc.live_selfie_url && doc.identity_document_url && (
                                             <div className="p-3 bg-primary/5 rounded-xl border border-primary/10 space-y-3">
                                                 <p className="text-[10px] font-black uppercase text-primary flex items-center gap-1">
                                                     <ScanFace className="h-3 w-3" /> Identity Comparison
                                                 </p>
                                                 <div className="grid grid-cols-2 gap-2">
                                                     <IdentityImage bucket="doctor-identities" path={doc.identity_document_url} label="Govt ID" />
                                                     <IdentityImage bucket="doctor-identities" path={doc.live_selfie_url} label="Live Capture" />
                                                 </div>
                                             </div>
                                         )}
                                    </div>
                                    {doc.auditor && (
                                        <div className="pt-2">
                                            <span className="text-[10px] uppercase font-bold text-muted-foreground tracking-tight">Last Auditor</span>
                                            <p className="text-xs font-semibold text-primary">{doc.auditor.full_name}</p>
                                        </div>
                                    )}
                                </div>

                                <div className="space-y-4">
                                    <h4 className="text-sm font-bold uppercase tracking-wider text-muted-foreground">Fee Negotiation</h4>
                                    {editingFee?.id === doc.id ? (
                                        <div className="flex items-end gap-2 p-3 bg-primary/5 rounded-xl border border-primary/20">
                                            <div className="flex-1 space-y-2">
                                                <Label htmlFor={`fee-${doc.id}`} className="text-xs">Set Monthly Fee (₦)</Label>
                                                <Input 
                                                    id={`fee-${doc.id}`}
                                                    type="number" 
                                                    value={editingFee?.fee || ''}
                                                    onChange={(e) => editingFee && setEditingFee({ ...editingFee, fee: e.target.value })}
                                                    className="bg-background h-9"
                                                />
                                            </div>
                                            <Button size="sm" onClick={() => updateFee(doc.id)} disabled={processingId === doc.id}>
                                                Update
                                            </Button>
                                            <Button size="sm" variant="ghost" onClick={() => setEditingFee(null)}>
                                                Cancel
                                            </Button>
                                        </div>
                                    ) : (
                                        <div className="flex items-center justify-between p-3 bg-muted/50 rounded-xl">
                                            <div>
                                                <p className="text-xs text-muted-foreground">Current Negotiated Fee</p>
                                                <p className="font-bold text-lg">{doc.negotiated_fee ? `₦${doc.negotiated_fee}` : '—'}<span className="text-sm font-normal text-muted-foreground ml-1">/ month</span></p>
                                            </div>
                                            <Button size="sm" variant="secondary" onClick={() => setEditingFee({ id: doc.id as string, fee: doc.negotiated_fee?.toString() || '' })}>
                                                <Banknote className="h-4 w-4 mr-1" />
                                                Edit Fee
                                            </Button>
                                        </div>
                                    )}
                                </div>
                            </CardContent>
                            <CardFooter className="bg-muted/10 border-t py-3 flex justify-between">
                                <span className="text-xs text-muted-foreground italic">Member since: {new Date(doc.created_at).toLocaleDateString()}</span>
                                <Button 
                                    variant="link" 
                                    size="sm" 
                                    className="h-auto p-0 flex items-center gap-1 text-primary/60 hover:text-primary"
                                    onClick={() => setChatDoctorId(doc.id)}
                                >
                                    <MessageSquare className="h-3 w-3" />
                                    Negotiation Chat
                                </Button>
                            </CardFooter>
                        </Card>
                    ))
                )}
            </div>
            
            {chatDoctorId && adminId && (
                <AdminChatPanel 
                    doctorId={chatDoctorId} 
                    adminId={adminId} 
                    doctorName={doctors.find(d => d.id === chatDoctorId)?.full_name || 'Practitioner'}
                    onClose={() => setChatDoctorId(null)} 
                />
            )}

            {/* Confirmation Dialog */}
            <Dialog open={!!confirmAction} onOpenChange={() => setConfirmAction(null)}>
                <DialogContent className="sm:max-w-md rounded-2xl">
                    <DialogHeader>
                        <DialogTitle className="flex items-center gap-2">
                            {confirmAction?.action === 'approved' ? (
                                <ShieldCheck className="h-5 w-5 text-green-600" />
                            ) : (
                                <AlertTriangle className="h-5 w-5 text-red-600" />
                            )}
                            {confirmAction?.action === 'approved' ? 'Approve Verification' : 'Reject Verification'}
                        </DialogTitle>
                        <DialogDescription>
                            {confirmAction?.action === 'approved'
                                ? `Are you sure you want to approve Dr. ${confirmAction?.doctorName}'s verification? This will promote them to Practitioner role and grant access to the Doctor Dashboard.`
                                : `Are you sure you want to reject ${confirmAction?.doctorName}'s verification? They will be notified and may reapply.`}
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter className="gap-2 sm:gap-0">
                        <Button variant="outline" onClick={() => setConfirmAction(null)}>Cancel</Button>
                        <Button
                            variant={confirmAction?.action === 'approved' ? 'default' : 'destructive'}
                            className={confirmAction?.action === 'approved' ? 'bg-green-600 hover:bg-green-700' : ''}
                            disabled={processingId === confirmAction?.doctorId}
                            onClick={async () => {
                                if (!confirmAction) return
                                await handleVerify(confirmAction.doctorId, confirmAction.action)
                                setConfirmAction(null)
                            }}
                        >
                            {processingId === confirmAction?.doctorId ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : null}
                            {confirmAction?.action === 'approved' ? 'Approve' : 'Reject'}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {/* Document Viewer Modal */}
            <Dialog open={!!docViewer} onOpenChange={() => setDocViewer(null)}>
                <DialogContent className="sm:max-w-3xl max-h-[90vh] p-0 overflow-hidden rounded-2xl">
                    <DialogHeader className="p-6 pb-2">
                        <DialogTitle className="flex items-center gap-2">
                            <ZoomIn className="h-5 w-5 text-primary" />
                            {docViewer?.label}
                        </DialogTitle>
                        <DialogDescription>Verification document submitted by the practitioner</DialogDescription>
                    </DialogHeader>
                    <div className="px-6 pb-6">
                        {docViewer?.type === 'image' ? (
                            <img 
                                src={docViewer.url} 
                                alt={docViewer.label} 
                                className="w-full rounded-xl border object-contain max-h-[60vh]"
                            />
                        ) : (
                            <iframe 
                                src={docViewer?.url} 
                                className="w-full h-[60vh] rounded-xl border"
                                title={docViewer?.label}
                            />
                        )}
                    </div>
                    <div className="px-6 pb-4 flex justify-end">
                        <Button variant="outline" onClick={() => setDocViewer(null)}>Close</Button>
                    </div>
                </DialogContent>
            </Dialog>
        </div>
    )
}

function IdentityImage({ bucket, path, label }: { bucket: string, path: string | null | undefined, label: string }) {
    const [url, setUrl] = useState<string | null>(null)
    const [loading, setLoading] = useState(true)
    const supabase = createClient()

    useEffect(() => {
        async function getUrl() {
            if (!path) {
                setLoading(false)
                return
            }
            const { data } = await supabase.storage.from(bucket).createSignedUrl(path, 600)
            if (data?.signedUrl) setUrl(data.signedUrl)
            setLoading(false)
        }
        getUrl()
    }, [path, bucket, supabase.storage])

    if (loading) return <div className="aspect-square bg-muted animate-pulse rounded-lg flex items-center justify-center"><Loader2 className="h-4 w-4 animate-spin" /></div>
    
    return (
        <div className="space-y-1">
            <div 
                className="aspect-square rounded-lg bg-cover bg-center border border-white/20 shadow-inner group-hover:scale-105 transition-transform cursor-zoom-in" 
                style={{ backgroundImage: `url(${url})` }}
                onClick={() => url && window.open(url, '_blank')}
            />
            <span className="text-[9px] font-bold text-muted-foreground block text-center truncate">{label}</span>
        </div>
    )
}

function AdminChatPanel({ doctorId, adminId, doctorName, onClose }: { doctorId: string, adminId: string, doctorName: string, onClose: () => void }) {
    const [messages, setMessages] = useState<FeeNegotiationMessage[]>([])
    const [newMessage, setNewMessage] = useState('')
    const [sending, setSending] = useState(false)
    const scrollRef = useRef<HTMLDivElement>(null)
    const supabase = createClient()

    useEffect(() => {
        const fetchMessages = async () => {
            const { data } = await supabase
                .from('fee_negotiation_messages')
                .select('*')
                .eq('doctor_id', doctorId)
                .order('created_at', { ascending: true })
            if (data) setMessages(data)
        }
        fetchMessages()

        const channel = supabase.channel('admin:fee:chat', {
                config: { private: true },
            })
            .on(
                'postgres_changes',
                { event: 'INSERT', schema: 'public', table: 'fee_negotiation_messages', filter: `doctor_id=eq.${doctorId}` },
                (payload) => setMessages(cur => [...cur, payload.new as FeeNegotiationMessage])
            )
            .subscribe()

        return () => { supabase.removeChannel(channel) }
    }, [doctorId, supabase])

    useEffect(() => {
        if (scrollRef.current) scrollRef.current.scrollIntoView({ behavior: 'smooth' })
    }, [messages])

    const handleSend = async (e: React.FormEvent) => {
        e.preventDefault()
        if (!newMessage.trim()) return
        setSending(true)
        const content = newMessage.trim()
        setNewMessage('')
        try {
            const { error } = await supabase.from('fee_negotiation_messages').insert({
                doctor_id: doctorId,
                sender_id: adminId,
                sender_role: 'admin',
                message: content
            })
            if (error) throw error
        } catch (error: unknown) {
            console.error('Admin fee negotiation message failed', error)
            toast.error(getUserFacingError(error, 'We could not send this message. Please try again.'))
            setNewMessage(content)
        } finally {
            setSending(false)
        }
    }

    return (
        <div className="fixed bottom-6 right-6 w-96 max-w-[calc(100vw-32px)] bg-background border border-border shadow-2xl rounded-2xl overflow-hidden z-50 animate-in slide-in-from-bottom-10 fade-in flex flex-col h-[500px] max-h-[80vh]">
            <div className="bg-slate-900 text-white p-4 flex items-center justify-between">
                <div>
                    <h4 className="font-bold">Chat: {doctorName}</h4>
                    <p className="text-[10px] text-slate-400 uppercase tracking-widest">Platform Fee Negotiation</p>
                </div>
                <Button variant="ghost" size="icon" className="text-white hover:bg-white/20 h-8 w-8 rounded-full" onClick={onClose}>
                    <X className="h-4 w-4" />
                </Button>
            </div>
            
            <ScrollArea className="flex-1 bg-slate-50">
                <div className="p-4 space-y-4">
                    {messages.length === 0 ? (
                        <p className="text-center text-xs text-muted-foreground mt-10">No messages found. Start the negotiation!</p>
                    ) : (
                        messages.map(msg => {
                            const isAdmin = msg.sender_role === 'admin'
                            return (
                                <div key={msg.id} className={`flex flex-col gap-1 ${isAdmin ? 'items-end' : 'items-start'}`}>
                                    <span className="text-[9px] font-bold text-muted-foreground/60 uppercase">{isAdmin ? 'You (Admin)' : doctorName}</span>
                                    <div className={`px-3 py-2 rounded-2xl text-sm max-w-[85%] ${isAdmin ? 'bg-primary text-white rounded-br-none shadow-sm' : 'bg-white border rounded-bl-none shadow-sm'}`}>
                                        {msg.message}
                                    </div>
                                </div>
                            )
                        })
                    )}
                    <div ref={scrollRef} />
                </div>
            </ScrollArea>

            <form onSubmit={handleSend} className="p-3 bg-white border-t flex gap-2">
                <Input 
                    value={newMessage} 
                    onChange={e => setNewMessage(e.target.value)} 
                    placeholder="Type response..." 
                    className="flex-1"
                    disabled={sending}
                />
                <Button type="submit" disabled={!newMessage.trim() || sending} size="icon" className="shrink-0 rounded-full h-10 w-10">
                    {sending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
                </Button>
            </form>
        </div>
    )
}
