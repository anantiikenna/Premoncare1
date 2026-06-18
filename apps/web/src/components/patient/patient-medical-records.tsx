'use client'

import { useState, useCallback, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { Loader2, Upload, FileText, Lock, LockOpen, Share2, Trash2, Beaker, FileSignature, Stethoscope, ShieldCheck, ShieldAlert, Sparkles, FolderOpen } from 'lucide-react'
import { useDropzone } from 'react-dropzone'
import { MedicalRecord, Profile } from '@/lib/types'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Switch } from '@/components/ui/switch'

export function PatientMedicalRecords({ patientId }: { patientId: string }) {
    const [records, setRecords] = useState<MedicalRecord[]>([])
    const [doctors, setDoctors] = useState<Profile[]>([])
    const [loading, setLoading] = useState(true)
    const [uploading, setUploading] = useState(false)
    const [title, setTitle] = useState('')
    const [recordType, setRecordType] = useState<MedicalRecord['record_type']>('lab_result')
    const [sharingRecordId, setSharingRecordId] = useState<string | null>(null)

    const supabase = createClient()

    const fetchData = useCallback(async () => {
        setLoading(true)
        try {
            const [recordsRes, docsRes] = await Promise.all([
                supabase.from('medical_records').select('*').order('created_at', { ascending: false }),
                supabase.from('profiles').select('*').eq('role', 'doctor').eq('verification_status', 'approved')
            ])

            if (recordsRes.error) throw recordsRes.error
            if (docsRes.error) throw docsRes.error

            setRecords(recordsRes.data as MedicalRecord[])
            setDoctors(docsRes.data as Profile[])
        } catch (error: any) {
            toast.error('Failed to load data')
        } finally {
            setLoading(false)
        }
    }, [supabase])

    useEffect(() => {
        fetchData()
    }, [fetchData])

    const onDrop = useCallback(async (acceptedFiles: File[]) => {
        const file = acceptedFiles[0]
        if (!file || !title) {
            toast.error('Please enter a descriptive title first')
            return
        }

        setUploading(true)
        try {
            const fileExt = file.name.split('.').pop() || 'tmp'
            const filePath = `${patientId}/${Date.now()}.${fileExt}`

            const { error: uploadError } = await supabase.storage
                .from('patient-medical-vault')
                .upload(filePath, file, { upsert: false })

            if (uploadError) throw uploadError

            const { error: dbError } = await supabase
                .from('medical_records')
                .insert({
                    patient_id: patientId,
                    title,
                    record_type: recordType,
                    document_url: filePath,
                    authorized_doctors: []
                })

            if (dbError) throw dbError

            toast.success('Record securely vaulted')
            setTitle('')
            fetchData()
        } catch (error: any) {
            toast.error('Upload failed')
        } finally {
            setUploading(false)
        }
    }, [patientId, title, recordType, supabase, fetchData])

    const { getRootProps, getInputProps, isDragActive } = useDropzone({
        onDrop,
        maxFiles: 1,
        accept: { 'application/pdf': [], 'image/*': [] }
    })

    const viewRecord = async (record: MedicalRecord) => {
        try {
            const { data, error } = await supabase.storage.from('patient-medical-vault').createSignedUrl(record.document_url, 600)
            if (error) throw error
            if (data?.signedUrl) window.open(data.signedUrl, '_blank')
        } catch (error: any) {
            toast.error('Could not decrypt file')
        }
    }

    const togglePermission = async (record: MedicalRecord, doctorId: string) => {
        const hasAccess = record.authorized_doctors?.includes(doctorId)
        const newAuthorized = hasAccess 
            ? record.authorized_doctors.filter(id => id !== doctorId)
            : [...(record.authorized_doctors || []), doctorId]

        try {
            const { error } = await supabase
                .from('medical_records')
                .update({ authorized_doctors: newAuthorized })
                .eq('id', record.id)

            if (error) throw error

            setRecords(prev => prev.map(r => r.id === record.id ? { ...r, authorized_doctors: newAuthorized } : r))
            toast.success(hasAccess ? 'Access revoked securely' : 'Access granted securely')
        } catch (error: any) {
            toast.error('Failed to update permissions')
        }
    }

    const deleteRecord = async (record: MedicalRecord) => {
        if (!confirm('Are you sure you want to permanently delete this record?')) return
        try {
            const { error: storageError } = await supabase.storage.from('patient-medical-vault').remove([record.document_url])
            if (storageError) throw storageError

            const { error: dbError } = await supabase.from('medical_records').delete().eq('id', record.id)
            if (dbError) throw dbError

            toast.success('Record deleted')
            fetchData()
        } catch (error: any) {
            toast.error('Delete failed')
        }
    }

    const getIconForType = (type: string) => {
        switch(type) {
            case 'lab_result': return <Beaker className="h-5 w-5 text-indigo-500" />
            case 'prescription': return <FileSignature className="h-5 w-5 text-amber-500" />
            default: return <Stethoscope className="h-5 w-5 text-emerald-500" />
        }
    }

    if (loading) return (
        <div className="grid lg:grid-cols-3 gap-8">
            <Card className="animate-pulse h-[400px] rounded-[2.5rem] bg-muted/20" />
            <div className="lg:col-span-2 grid sm:grid-cols-2 gap-4">
                {[1, 2, 3, 4].map(i => <Card key={i} className="animate-pulse h-32 rounded-2xl bg-muted/10" />)}
            </div>
        </div>
    )

    return (
        <div className="grid lg:grid-cols-3 gap-10 pb-20">
            <div className="lg:col-span-1 space-y-6">
                <Card className="border-none bg-primary shadow-2xl shadow-primary/20 rounded-[3rem] overflow-hidden text-white relative">
                    <div className="absolute top-0 right-0 p-8 opacity-10">
                        <Lock className="h-24 w-24" />
                    </div>
                    <CardHeader className="p-10 pb-6">
                        <Badge className="w-fit bg-white/20 hover:bg-white/20 text-white border-none font-black text-[9px] uppercase tracking-widest mb-4">
                            <Sparkles className="h-3 w-3 mr-2" />
                            Medical Vault
                        </Badge>
                        <CardTitle className="text-3xl font-black tracking-tighter leading-tight">Secure Document Deposit</CardTitle>
                        <CardDescription className="text-white/60 font-bold uppercase tracking-widest text-[10px]">End-to-end encrypted storage</CardDescription>
                    </CardHeader>
                    <CardContent className="px-10 pb-10 space-y-8 relative z-10">
                        <div className="space-y-4">
                            <div className="space-y-2">
                                <Label className="text-[10px] font-black uppercase tracking-widest text-white/70 ml-1">Record Descriptor</Label>
                                <Input 
                                    placeholder="e.g. 2026 Health Checkup" 
                                    value={title}
                                    onChange={e => setTitle(e.target.value)}
                                    className="h-14 rounded-2xl bg-white/10 border-white/10 text-white placeholder:text-white/30 font-bold focus:ring-white/20"
                                    aria-label="Record Descriptor"
                                    aria-required="true"
                                />
                            </div>
                            <div className="space-y-2">
                                <Label className="text-[10px] font-black uppercase tracking-widest text-white/70 ml-1">Classification</Label>
                                <select 
                                    className="flex h-14 w-full items-center justify-between rounded-2xl border border-white/10 bg-white/10 px-4 py-2 text-sm font-bold ring-offset-background text-white focus:outline-none"
                                    value={recordType}
                                    onChange={e => setRecordType(e.target.value as any)}
                                    aria-label="Medical Record Classification"
                                >
                                    <option value="lab_result" className="bg-slate-900">Lab Result</option>
                                    <option value="prescription" className="bg-slate-900">Prescription</option>
                                    <option value="imaging" className="bg-slate-900">Imaging (X-Ray, MRI)</option>
                                    <option value="immunization" className="bg-slate-900">Immunization</option>
                                    <option value="clinical_note" className="bg-slate-900">Clinical Note</option>
                                    <option value="other" className="bg-slate-900">Other</option>
                                </select>
                            </div>
                        </div>

                        <div {...getRootProps()} className={`border-2 border-dashed rounded-[2rem] p-10 text-center transition-all duration-300 ${!title ? 'opacity-30 cursor-not-allowed' : 'cursor-pointer hover:bg-white/5 border-white/20'} ${isDragActive ? 'border-white bg-white/10 scale-[0.98]' : 'border-white/10'}`}>
                            <input {...getInputProps()} disabled={!title || uploading} />
                            {uploading ? (
                                <Loader2 className="h-12 w-12 animate-spin text-white mx-auto" />
                            ) : (
                                <div className="space-y-3">
                                    <div className="bg-white/20 p-4 rounded-3xl w-fit mx-auto shadow-inner"><Upload className="h-8 w-8 text-white" /></div>
                                    <p className="text-sm font-black tracking-tight">{title ? 'Drop Encrypted File' : 'Identify Record Above'}</p>
                                    <p className="text-[9px] text-white/40 font-black uppercase tracking-widest">PDF or High-Res Image</p>
                                </div>
                            )}
                        </div>
                    </CardContent>
                </Card>

                <div className="p-6 bg-slate-50 rounded-[2.5rem] border border-slate-200 flex items-start gap-4">
                    <ShieldAlert className="h-6 w-6 text-primary mt-1" />
                    <div className="space-y-1">
                        <p className="text-xs font-black text-slate-900 uppercase tracking-widest">Trust & Security</p>
                        <p className="text-[10px] text-slate-500 font-bold leading-relaxed">
                            Premon Care uses Advanced Encryption Standard (AES) to wrap your medical documents before they ever leave your browser.
                        </p>
                    </div>
                </div>
            </div>

            <div className="lg:col-span-2 space-y-8">
                {records.length === 0 ? (
                    <div className="text-center py-32 bg-slate-50 rounded-[4rem] border-4 border-dashed border-slate-100 flex flex-col items-center justify-center animate-in-fade">
                        <div className="relative mb-8">
                            <div className="absolute inset-0 bg-primary/10 blur-2xl rounded-full" />
                            <div className="h-24 w-24 rounded-[2rem] bg-white shadow-xl flex items-center justify-center text-primary/30 relative z-10">
                                <FolderOpen className="h-12 w-12" />
                            </div>
                        </div>
                        <h3 className="text-3xl font-black tracking-tighter text-slate-900">Your Vault is Empty</h3>
                        <p className="text-muted-foreground font-bold text-sm uppercase tracking-[0.2em] mt-3 max-w-xs mx-auto leading-loose">
                            Upload clinical summaries or lab results to start your secure health history.
                        </p>
                    </div>
                ) : (
                    <div className="grid sm:grid-cols-2 gap-6 animate-in-fade">
                        {records.map(record => (
                            <Card key={record.id} className="rounded-[2.5rem] border-none shadow-xl hover:shadow-2xl transition-all duration-300 overflow-hidden group bg-card/50">
                                <CardHeader className="p-6 pb-4 bg-muted/30 flex flex-row items-start justify-between border-b border-dashed">
                                    <div className="flex items-center gap-4">
                                        <div className="bg-white p-3 rounded-2xl shadow-sm group-hover:scale-110 transition-transform">
                                            {getIconForType(record.record_type)}
                                        </div>
                                        <div>
                                            <CardTitle className="text-lg font-black tracking-tight leading-tight">{record.title}</CardTitle>
                                            <p className="text-[9px] uppercase tracking-widest text-primary font-black mt-1">
                                                {record.record_type.replace('_', ' ')}
                                            </p>
                                        </div>
                                    </div>
                                    <Badge variant={(record.authorized_doctors?.length || 0) > 0 ? "default" : "secondary"} className="font-black text-[9px] uppercase tracking-widest rounded-full px-3 py-1">
                                        {(record.authorized_doctors?.length || 0) > 0 ? <LockOpen className="h-3 w-3 mr-1" /> : <Lock className="h-3 w-3 mr-1" />}
                                        {(record.authorized_doctors?.length || 0)} Shared
                                    </Badge>
                                </CardHeader>
                                <CardContent className="p-6 flex items-center justify-between gap-4">
                                    <div className="flex flex-col">
                                        <span className="text-[9px] font-black uppercase tracking-widest text-muted-foreground/50">Deposited on</span>
                                        <span className="text-xs font-black text-slate-700">
                                            {new Date(record.created_at).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' })}
                                        </span>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <Button size="icon" variant="ghost" className="h-11 w-11 rounded-xl bg-slate-100 hover:bg-primary/10 text-primary hover:text-primary transition-colors" onClick={() => viewRecord(record)} title="View File" aria-label={`View medical record file for ${record.title}`}>
                                            <FileText className="h-5 w-5" />
                                        </Button>
                                        <Button size="icon" variant="ghost" className="h-11 w-11 rounded-xl bg-primary/10 hover:bg-primary text-primary hover:text-white transition-all" onClick={() => setSharingRecordId(record.id)} title="Access Management" aria-label={`Manage doctor access permissions for ${record.title}`}>
                                            <Share2 className="h-5 w-5" />
                                        </Button>
                                        <Button size="icon" variant="ghost" className="h-11 w-11 rounded-xl bg-destructive/10 hover:bg-destructive text-destructive hover:text-white transition-all" onClick={() => deleteRecord(record)} title="Permanently Delete" aria-label={`Permanently delete medical record ${record.title}`}>
                                            <Trash2 className="h-5 w-5" />
                                        </Button>
                                    </div>
                                </CardContent>
                            </Card>
                        ))}
                    </div>
                )}
            </div>

            <Dialog open={!!sharingRecordId} onOpenChange={(open) => !open && setSharingRecordId(null)}>
                <DialogContent className="sm:max-w-md rounded-[2.5rem] p-0 overflow-hidden border-none shadow-2xl">
                    <DialogHeader className="p-8 pb-4 bg-primary/5 border-b border-dashed">
                        <DialogTitle className="flex items-center gap-3 text-2xl font-black tracking-tight">
                            <ShieldCheck className="h-8 w-8 text-primary" /> 
                            Access Control
                        </DialogTitle>
                        <DialogDescription className="text-xs font-bold uppercase tracking-widest text-muted-foreground/60 leading-loose pt-2">
                            Toggle which verified practitioners hold <br />decryption keys to this vault asset.
                        </DialogDescription>
                    </DialogHeader>
                    <div className="max-h-[50vh] overflow-y-auto space-y-4 p-8 no-scrollbar">
                        {doctors.map(doc => {
                            const record = records.find(r => r.id === sharingRecordId)
                            const hasAccess = record?.authorized_doctors?.includes(doc.id)
                            return (
                                <div key={doc.id} className="flex items-center justify-between p-4 border rounded-[1.5rem] hover:bg-muted/30 transition-all group">
                                    <div className="flex items-center gap-4">
                                        <Avatar className="h-12 w-12 border-2 border-white shadow-lg">
                                            <AvatarImage src={doc.avatar_url || ''} />
                                            <AvatarFallback className="font-black bg-primary/10 text-primary">{doc.full_name?.charAt(0)}</AvatarFallback>
                                        </Avatar>
                                        <div>
                                            <p className="text-sm font-black text-slate-900 tracking-tight">Dr. {doc.full_name}</p>
                                            <p className="text-[10px] font-black uppercase tracking-widest text-primary/60">{doc.specialty}</p>
                                        </div>
                                    </div>
                                    <Switch 
                                        checked={hasAccess} 
                                        onCheckedChange={() => record && togglePermission(record, doc.id)}
                                        className="data-[state=checked]:bg-green-500"
                                    />
                                </div>
                            )
                        })}
                        {doctors.length === 0 && (
                            <div className="text-center py-10 space-y-4">
                                <ShieldAlert className="h-10 w-10 text-muted-foreground/20 mx-auto" />
                                <p className="text-xs font-bold uppercase tracking-widest text-muted-foreground/60">No verified practitioners <br />found on network.</p>
                            </div>
                        )}
                    </div>
                    <div className="p-6 bg-slate-50 border-t border-dashed flex justify-center">
                        <Button variant="ghost" className="font-black uppercase tracking-widest text-[10px] text-muted-foreground" onClick={() => setSharingRecordId(null)}>
                            Close Permissions
                        </Button>
                    </div>
                </DialogContent>
            </Dialog>
        </div>
    )
}
