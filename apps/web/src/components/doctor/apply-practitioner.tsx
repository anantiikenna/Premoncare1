'use client'

import { useState, useCallback, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Checkbox } from '@/components/ui/checkbox'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { Loader2, ShieldCheck, FileText, Send, CheckCircle2, UserRound, ScanFace, Upload, ArrowRight, ArrowLeft, XCircle, AlertCircle, ShieldAlert } from 'lucide-react'
import { useRouter } from 'next/navigation'
import { useDropzone } from 'react-dropzone'
import { FaceCapture } from '@/components/shared/face-capture'
import { Badge } from '@/components/ui/badge'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

interface ApplyPractitionerProps {
    profile: any
}

type Step = 'professional' | 'identity' | 'facial' | 'review'

export function ApplyPractitioner({ profile }: ApplyPractitionerProps) {
    const [step, setStep] = useState<Step>('professional')
    const [loading, setLoading] = useState(false)
    const [uploading, setUploading] = useState(false)
    
    // Form Data
    const [specialty, setSpecialty] = useState(profile?.specialty || '')
    const [experience, setExperience] = useState(profile?.experience_years?.toString() || '')
    const [licenseUrl, setLicenseUrl] = useState(profile?.verification_document_url || '')
    const [idFrontUrl, setIdFrontUrl] = useState(profile?.identity_document_front_url || '')
    const [idBackUrl, setIdBackUrl] = useState(profile?.identity_document_back_url || '')
    const [idType, setIdType] = useState(profile?.identity_type || 'passport')
    const [selfieUrl, setSelfieUrl] = useState(profile?.live_selfie_url || '')
    const [licenseNumber, setLicenseNumber] = useState(profile?.medical_license_number || '')
    const [languages, setLanguages] = useState(profile?.languages_spoken || '')
    const [consultationModes, setConsultationModes] = useState<string[]>(profile?.preferred_consultation_types || [])
    const [agreed, setAgreed] = useState(false)
    
    const [submitted, setSubmitted] = useState(profile?.verification_status === 'pending')
    const isRejected = profile?.verification_status === 'rejected'
    
    const supabase = createClient()
    const router = useRouter()

    const onDropLicense = useCallback(async (acceptedFiles: File[]) => {
        const file = acceptedFiles[0]
        if (!file) return
        setUploading(true)
        try {
            const fileExt = file.name.split('.').pop() || 'tmp'
            const filePath = `${profile.id}/license.${fileExt}`
            const { error: uploadError } = await supabase.storage
                .from('doctor-verifications')
                .upload(filePath, file, { upsert: true })

            if (uploadError) throw uploadError
            setLicenseUrl(filePath)
            toast.success('Professional license uploaded')
        } catch (error: unknown) {
            toast.error('License upload failed')
        } finally {
            setUploading(false)
        }
    }, [profile.id])

    const onDropIdFront = useCallback(async (acceptedFiles: File[]) => {
        const file = acceptedFiles[0]
        if (!file) return
        setUploading(true)
        try {
            const fileExt = file.name.split('.').pop() || 'tmp'
            const filePath = `${profile.id}/id_front.${fileExt}`
            const { error: uploadError } = await supabase.storage
                .from('doctor-identities')
                .upload(filePath, file, { upsert: true })

            if (uploadError) throw uploadError
            setIdFrontUrl(filePath)
            toast.success('ID Front uploaded')
        } catch (error: unknown) {
            toast.error('Upload failed')
        } finally {
            setUploading(false)
        }
    }, [profile.id])

    const onDropIdBack = useCallback(async (acceptedFiles: File[]) => {
        const file = acceptedFiles[0]
        if (!file) return
        setUploading(true)
        try {
            const fileExt = file.name.split('.').pop() || 'tmp'
            const filePath = `${profile.id}/id_back.${fileExt}`
            const { error: uploadError } = await supabase.storage
                .from('doctor-identities')
                .upload(filePath, file, { upsert: true })

            if (uploadError) throw uploadError
            setIdBackUrl(filePath)
            toast.success('ID Back uploaded')
        } catch (error: unknown) {
            toast.error('Upload failed')
        } finally {
            setUploading(false)
        }
    }, [profile.id])

    const handleFaceCapture = async (blob: Blob) => {
        setUploading(true)
        try {
            const filePath = `${profile.id}/live_selfie.jpg`
            const { error: uploadError } = await supabase.storage
                .from('doctor-identities')
                .upload(filePath, blob, { upsert: true, contentType: 'image/jpeg' })

            if (uploadError) throw uploadError
            setSelfieUrl(filePath)
            toast.success('Biometric capture saved')
        } catch (error: unknown) {
            toast.error('Face capture failed')
        } finally {
            setUploading(false)
        }
    }

    const { getRootProps: getLicenseProps, getInputProps: getLicenseInput, isDragActive: isLicenseActive } = useDropzone({ 
        onDrop: onDropLicense, 
        maxFiles: 1,
        accept: { 'application/pdf': [], 'image/*': [] }
    })

    const { getRootProps: getIdFrontProps, getInputProps: getIdFrontInput, isDragActive: isIdFrontActive } = useDropzone({ 
        onDrop: onDropIdFront, 
        maxFiles: 1,
        accept: { 'image/*': [] }
    })

    const { getRootProps: getIdBackProps, getInputProps: getIdBackInput, isDragActive: isIdBackActive } = useDropzone({ 
        onDrop: onDropIdBack, 
        maxFiles: 1,
        accept: { 'image/*': [] }
    })

    const handleSubmit = async () => {
        setLoading(true)
        try {
            const { error } = await supabase
                .from('profiles')
                .update({ 
                    specialty,
                    experience_years: parseInt(experience) || 0,
                    verification_document_url: licenseUrl,
                    identity_document_front_url: idFrontUrl,
                    identity_document_back_url: idBackUrl,
                    identity_type: idType,
                    live_selfie_url: selfieUrl,
                    medical_license_number: licenseNumber,
                    languages_spoken: languages,
                    preferred_consultation_types: consultationModes,
                    requested_role: 'doctor' as any,
                    verification_status: 'pending',
                    rejection_reason: null // Clear previous rejection reason
                })
                .eq('id', profile.id)

            if (error) throw error

            setSubmitted(true)
            toast.success('Application submitted for biometric review!')
            router.refresh()
        } catch (error: unknown) {
            toast.error('Submission failed')
        } finally {
            setLoading(false)
        }
    }

    if (profile?.role === 'doctor') {
        return (
            <Card className="border-green-100 bg-green-50/30 rounded-3xl overflow-hidden animate-in-fade">
                <CardContent className="pt-10 pb-10 flex flex-col items-center text-center gap-6">
                    <div className="bg-green-100 p-6 rounded-[2rem] text-green-600 ring-8 ring-green-50">
                        <CheckCircle2 className="h-12 w-12" />
                    </div>
                    <div className="space-y-2">
                        <h3 className="text-3xl font-black text-green-900 tracking-tighter">Verified Practitioner</h3>
                        <p className="text-sm text-green-700 max-w-sm mx-auto leading-relaxed">
                            Congratulations! Your identity and medical credentials have been successfully verified. 
                            You now have full access to the Doctor Command Center.
                        </p>
                    </div>
                    <div className="flex flex-col sm:flex-row gap-4 w-full max-w-md">
                        <Button onClick={() => router.push('/doctor/dashboard')} className="flex-1 rounded-2xl bg-green-600 hover:bg-green-700 h-14 font-black shadow-xl shadow-green-600/20 uppercase tracking-widest text-xs">
                            Access Dashboard
                        </Button>
                        <Button variant="outline" onClick={() => router.push('/patient/dashboard')} className="flex-1 rounded-2xl border-green-200 text-green-700 hover:bg-green-100 h-14 font-black uppercase tracking-widest text-xs">
                            Switch to Patient
                        </Button>
                    </div>
                </CardContent>
            </Card>
        )
    }

    if (submitted) {
        return (
            <Card className="border-primary/10 shadow-2xl shadow-primary/5 overflow-hidden rounded-[2.5rem] animate-in-fade">
                <CardHeader className="bg-primary/5 p-10 border-b">
                    <div className="flex items-center justify-between mb-4">
                        <Badge className="bg-amber-500 hover:bg-amber-500 font-black uppercase tracking-widest text-[9px] px-3 py-1">Pending Audit</Badge>
                        <ShieldCheck className="h-10 w-10 text-primary opacity-20" />
                    </div>
                    <CardTitle className="text-4xl font-black tracking-tighter">Verification Active</CardTitle>
                    <CardDescription className="text-md font-bold text-muted-foreground/60 uppercase tracking-widest leading-loose">
                        Our medical board is auditing your credentials
                    </CardDescription>
                </CardHeader>
                <CardContent className="p-10 space-y-8">
                    <div className="grid grid-cols-3 gap-4">
                        <div className="bg-green-50 p-5 rounded-3xl border border-green-100 flex flex-col items-center gap-2">
                           <CheckCircle2 className="h-6 w-6 text-green-600" />
                           <span className="text-[10px] font-black text-green-700 uppercase tracking-widest">Submitted</span>
                        </div>
                        <div className="bg-blue-50 p-5 rounded-3xl border border-blue-100 flex flex-col items-center gap-2 animate-pulse">
                           <Loader2 className="h-6 w-6 text-blue-600 animate-spin" />
                           <span className="text-[10px] font-black text-blue-700 uppercase tracking-widest">Auditing</span>
                        </div>
                        <div className="bg-slate-50 p-5 rounded-3xl border border-slate-100 flex flex-col items-center gap-2 opacity-50">
                           <ShieldCheck className="h-6 w-6 text-slate-400" />
                           <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Promote</span>
                        </div>
                    </div>

                    <div className="p-8 bg-muted/30 rounded-[2rem] space-y-6 border border-dashed border-muted-foreground/20">
                        <div className="flex items-center gap-3 border-b border-muted-foreground/10 pb-4">
                            <AlertCircle className="h-5 w-5 text-primary" />
                            <p className="text-xs font-black uppercase tracking-widest text-slate-900">Platform Security Checklist</p>
                        </div>
                        <ul className="space-y-4">
                            <li className="flex items-start gap-4">
                                <div className="h-6 w-6 rounded-full bg-green-500/10 text-green-600 flex items-center justify-center shrink-0 font-black text-xs">01</div>
                                <span className="text-xs font-bold text-muted-foreground/80 leading-relaxed">Cross-referencing Government ID with Medical License.</span>
                            </li>
                            <li className="flex items-start gap-4">
                                <div className="h-6 w-6 rounded-full bg-blue-500/10 text-blue-600 flex items-center justify-center shrink-0 font-black text-xs animate-pulse">02</div>
                                <span className="text-xs font-bold text-muted-foreground/80 leading-relaxed">Analyzing Live Biometrics against static identity photos.</span>
                            </li>
                            <li className="flex items-start gap-4 opacity-40">
                                <div className="h-6 w-6 rounded-full bg-slate-200 text-slate-500 flex items-center justify-center shrink-0 font-black text-xs">03</div>
                                <span className="text-xs font-bold text-muted-foreground/80 leading-relaxed">Final manual confirmation by Chief Medical Officer.</span>
                            </li>
                        </ul>
                    </div>
                </CardContent>
            </Card>
        )
    }

    return (
        <Card className="border-primary/20 shadow-2xl shadow-primary/5 overflow-hidden rounded-[2.5rem] animate-in-fade">
            <CardHeader className="bg-slate-50 dark:bg-slate-900 p-10 border-b relative">
                {isRejected && (
                    <div className="mb-6 p-5 bg-destructive/5 border border-destructive/20 rounded-2xl flex items-start gap-4 animate-shake">
                        <XCircle className="h-6 w-6 text-destructive mt-0.5" />
                        <div>
                            <p className="text-sm font-black text-destructive uppercase tracking-widest mb-1">Application Rejected</p>
                            <p className="text-xs font-bold text-destructive/80 leading-relaxed italic">
                                "{profile?.rejection_reason || 'Information provided could not be verified. Please review and resubmit.'}"
                            </p>
                        </div>
                    </div>
                )}
                
                <div className="flex items-center justify-between mb-6">
                    <div className="flex gap-2">
                        {(['professional', 'identity', 'facial', 'review'] as Step[]).map((s, idx) => (
                            <div key={s} className={`h-2 rounded-full transition-all duration-500 ${
                                step === s ? 'w-10 bg-primary' : idx < (['professional', 'identity', 'facial', 'review'] as Step[]).indexOf(step) ? 'w-4 bg-green-500' : 'w-4 bg-slate-200'
                            }`} />
                        ))}
                    </div>
                    <Badge variant="outline" className="uppercase text-[9px] font-black tracking-widest px-4 py-1 rounded-full border-primary/20">
                        Induction Phase
                    </Badge>
                </div>
                <CardTitle className="text-5xl font-black tracking-tighter flex items-center gap-4 text-gradient pb-2">
                    {step === 'professional' && <UserRound className="h-10 w-10 text-primary" />}
                    {step === 'identity' && <ShieldCheck className="h-10 w-10 text-primary" />}
                    {step === 'facial' && <ScanFace className="h-10 w-10 text-primary" />}
                    {step === 'review' && <CheckCircle2 className="h-10 w-10 text-green-500" />}
                    
                    {step === 'professional' && 'Professional Profile'}
                    {step === 'identity' && 'Identity Assets'}
                    {step === 'facial' && 'Live Biometrics'}
                    {step === 'review' && 'Final Review'}
                </CardTitle>
                <CardDescription className="text-slate-500 text-lg font-medium">
                    {step === 'professional' && 'Define your medical area of expertise and clinical history.'}
                    {step === 'identity' && 'Provide secure government identity for platform auditing.'}
                    {step === 'facial' && 'Complete the 3D-biometric scan to finalize your identity link.'}
                    {step === 'review' && 'Audit your application data before secure submission.'}
                </CardDescription>
            </CardHeader>
            
            <CardContent className="p-10">
                {step === 'professional' && (
                    <div className="space-y-8 animate-in fade-in slide-in-from-right-8 duration-500">
                        <div className="grid sm:grid-cols-2 gap-8">
                            <div className="space-y-3">
                                <Label className="text-xs font-black uppercase tracking-widest ml-1 text-slate-500">Clinical Specialty</Label>
                                <Input 
                                    className="h-14 rounded-2xl bg-slate-50 border-slate-200 font-bold focus:ring-primary/20"
                                    placeholder="e.g. Cardiologist" 
                                    value={specialty}
                                    onChange={(e) => setSpecialty(e.target.value)}
                                />
                            </div>
                            <div className="space-y-3">
                                <Label className="text-xs font-black uppercase tracking-widest ml-1 text-slate-500">Years of Practice</Label>
                                <Input 
                                    className="h-14 rounded-2xl bg-slate-50 border-slate-200 font-bold focus:ring-primary/20"
                                    type="number" 
                                    placeholder="e.g. 15" 
                                    value={experience}
                                    onChange={(e) => setExperience(e.target.value)}
                                />
                            </div>
                            <div className="space-y-3">
                                <Label className="text-xs font-black uppercase tracking-widest ml-1 text-slate-500">Medical License ID</Label>
                                <Input 
                                    className="h-14 rounded-2xl bg-slate-50 border-slate-200 font-bold focus:ring-primary/20"
                                    placeholder="Official board identification" 
                                    value={licenseNumber}
                                    onChange={(e) => setLicenseNumber(e.target.value)}
                                />
                            </div>
                            <div className="space-y-3">
                                <Label className="text-xs font-black uppercase tracking-widest ml-1 text-slate-500">Polyglot Capabilities</Label>
                                <Input 
                                    className="h-14 rounded-2xl bg-slate-50 border-slate-200 font-bold focus:ring-primary/20"
                                    placeholder="English, French, etc." 
                                    value={languages}
                                    onChange={(e) => setLanguages(e.target.value)}
                                />
                            </div>
                        </div>

                        <div className="space-y-4 pt-4">
                            <Label className="text-xs font-black uppercase tracking-widest ml-1 text-slate-500">Medical License (High Resolution Upload)</Label>
                            <div {...getLicenseProps()} className={`border-2 border-dashed rounded-[2rem] p-10 text-center transition-all cursor-pointer ${
                                isLicenseActive ? 'border-primary bg-primary/5' : licenseUrl ? 'border-green-500 bg-green-50' : 'border-slate-200 hover:border-primary/50 hover:bg-slate-50'
                            }`}>
                                <input {...getLicenseInput()} />
                                {uploading ? <Loader2 className="h-10 w-10 animate-spin mx-auto text-primary" /> : licenseUrl ? (
                                    <div className="flex flex-col items-center gap-3">
                                        <div className="bg-green-500 text-white p-3 rounded-full shadow-lg"><CheckCircle2 className="h-8 w-8" /></div>
                                        <span className="text-sm font-black text-green-700 uppercase tracking-widest">Document Secured Successfully</span>
                                    </div>
                                ) : (
                                    <div className="space-y-3">
                                        <div className="bg-primary/10 p-4 rounded-3xl w-fit mx-auto mb-2"><Upload className="h-8 w-8 text-primary" /></div>
                                        <p className="text-md font-black tracking-tight">Drop your license here</p>
                                        <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest">PDF, JPG or PNG (MAX 5MB)</p>
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                )}

                {step === 'identity' && (
                    <div className="space-y-8 animate-in fade-in slide-in-from-right-8 duration-500">
                        <div className="space-y-3">
                            <Label className="text-xs font-black uppercase tracking-widest ml-1 text-slate-500">Identity Document Type</Label>
                            <Select value={idType} onValueChange={setIdType}>
                                <SelectTrigger className="h-14 rounded-2xl bg-slate-50 border-slate-200 font-bold">
                                    <SelectValue placeholder="Select document type" />
                                </SelectTrigger>
                                <SelectContent className="rounded-2xl">
                                    <SelectItem value="passport">International Passport</SelectItem>
                                    <SelectItem value="national_id">National ID Card</SelectItem>
                                    <SelectItem value="drivers_license">Driver's License</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>
                        
                        <div className="grid sm:grid-cols-2 gap-8">
                            <div className="space-y-4">
                                <Label className="text-xs font-black uppercase tracking-widest ml-1 text-slate-500">ID Front View</Label>
                                <div {...getIdFrontProps()} className={`border-2 border-dashed rounded-[2rem] p-8 text-center transition-all cursor-pointer h-48 flex flex-col items-center justify-center ${
                                    isIdFrontActive ? 'border-primary bg-primary/5' : idFrontUrl ? 'border-green-500 bg-green-50' : 'border-slate-200 hover:border-primary/50 hover:bg-slate-50'
                                }`}>
                                    <input {...getIdFrontInput()} />
                                    {uploading ? <Loader2 className="h-8 w-8 animate-spin text-primary" /> : idFrontUrl ? (
                                        <div className="flex flex-col items-center gap-2">
                                            <div className="bg-green-500 text-white p-2 rounded-full"><CheckCircle2 className="h-6 w-6" /></div>
                                            <span className="text-[10px] font-black text-green-700 uppercase tracking-widest">Front Secured</span>
                                        </div>
                                    ) : (
                                        <div className="space-y-2">
                                            <Upload className="h-6 w-6 mx-auto text-slate-400" />
                                            <p className="text-xs font-black uppercase tracking-widest">Front Photo</p>
                                        </div>
                                    )}
                                </div>
                            </div>
                            
                            <div className="space-y-4">
                                <Label className="text-xs font-black uppercase tracking-widest ml-1 text-slate-500">ID Back View</Label>
                                <div {...getIdBackProps()} className={`border-2 border-dashed rounded-[2rem] p-8 text-center transition-all cursor-pointer h-48 flex flex-col items-center justify-center ${
                                    isIdBackActive ? 'border-primary bg-primary/5' : idBackUrl ? 'border-green-500 bg-green-50' : 'border-slate-200 hover:border-primary/50 hover:bg-slate-50'
                                }`}>
                                    <input {...getIdBackInput()} />
                                    {uploading ? <Loader2 className="h-8 w-8 animate-spin text-primary" /> : idBackUrl ? (
                                        <div className="flex flex-col items-center gap-2">
                                            <div className="bg-green-500 text-white p-2 rounded-full"><CheckCircle2 className="h-6 w-6" /></div>
                                            <span className="text-[10px] font-black text-green-700 uppercase tracking-widest">Back Secured</span>
                                        </div>
                                    ) : (
                                        <div className="space-y-2">
                                            <Upload className="h-6 w-6 mx-auto text-slate-400" />
                                            <p className="text-xs font-black uppercase tracking-widest">Back Photo</p>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>

                        <div className="p-6 bg-blue-50 rounded-3xl border border-blue-100 flex items-start gap-4">
                            <ShieldAlert className="h-6 w-6 text-blue-600 mt-1" />
                            <div className="space-y-1">
                                <p className="text-xs font-black text-blue-900 uppercase tracking-widest">Privacy Assurance</p>
                                <p className="text-[10px] text-blue-700/80 leading-relaxed font-bold">
                                    Your identity assets are encrypted in a zero-knowledge private vault. Only authorized Premon Care compliance officers can access these during the audit phase.
                                </p>
                            </div>
                        </div>
                    </div>
                )}

                {step === 'facial' && (
                    <div className="animate-in fade-in slide-in-from-right-8 duration-500 py-4">
                        <FaceCapture 
                            onCapture={handleFaceCapture}
                            isProcessing={uploading}
                        />
                        <div className="mt-8 p-6 bg-slate-50 rounded-[2rem] border border-slate-200 flex items-center justify-center gap-4">
                            <div className="bg-primary/10 p-2 rounded-full"><ShieldCheck className="h-5 w-5 text-primary" /></div>
                            <p className="text-[11px] font-black uppercase tracking-widest text-slate-500">Encrypted 3D-Biometric Analysis Active</p>
                        </div>
                    </div>
                )}

                {step === 'review' && (
                    <div className="space-y-8 animate-in fade-in slide-in-from-right-8 duration-500">
                        <div className="grid grid-cols-2 gap-6">
                            <div className="p-6 bg-slate-50 rounded-3xl border border-slate-200 space-y-2">
                                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Clinical Specialty</span>
                                <p className="text-lg font-black text-slate-900 tracking-tight">{specialty}</p>
                            </div>
                            <div className="p-6 bg-slate-50 rounded-3xl border border-slate-200 space-y-2">
                                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Practice Experience</span>
                                <p className="text-lg font-black text-slate-900 tracking-tight">{experience} Years</p>
                            </div>
                        </div>

                        <div className="space-y-4">
                            {[
                                { icon: FileText, label: 'Medical Credentials', status: licenseUrl ? 'Attached' : 'Missing' },
                                { icon: ShieldCheck, label: 'Identity Documents', status: (idFrontUrl && idBackUrl) ? 'Attached' : 'Partial' },
                                { icon: ScanFace, label: 'Biometric Analysis', status: selfieUrl ? 'Captured' : 'Pending' }
                            ].map((item, idx) => (
                                <div key={idx} className="flex items-center justify-between p-5 bg-green-50/50 rounded-2xl border border-green-100/50">
                                    <div className="flex items-center gap-4">
                                        <div className="bg-white p-2 rounded-xl shadow-sm"><item.icon className="h-5 w-5 text-green-600" /></div>
                                        <span className="text-sm font-black text-slate-900 uppercase tracking-widest">{item.label}</span>
                                    </div>
                                    <Badge className="bg-green-600 font-black text-[9px] uppercase tracking-widest">{item.status}</Badge>
                                </div>
                            ))}
                        </div>

                        <div className="p-8 bg-primary/5 rounded-[2.5rem] border border-primary/10 space-y-6">
                            <div className="flex items-start gap-4">
                                <ShieldCheck className="h-5 w-5 text-primary mt-1" />
                                <div className="space-y-1">
                                    <p className="text-xs font-black text-slate-900 uppercase tracking-widest">HIPAA & GDPR Ethics Agreement</p>
                                    <p className="text-[11px] text-slate-500 leading-relaxed font-bold">
                                        I certify that all medical credentials and identity assets provided are authentic. I agree to uphold the highest standards of patient privacy and ethical practice on the Premon Care platform.
                                    </p>
                                </div>
                            </div>
                            <div className="flex items-center space-x-4 bg-white p-5 rounded-2xl border border-primary/10 shadow-sm">
                                <Checkbox 
                                    id="terms" 
                                    checked={agreed} 
                                    onCheckedChange={(c) => setAgreed(c === true)} 
                                    className="h-6 w-6 rounded-lg data-[state=checked]:bg-primary"
                                />
                                <label
                                    htmlFor="terms"
                                    className="text-sm font-black tracking-tight cursor-pointer leading-tight"
                                    >
                                    I accept the Practitioner Terms of Service and certify data authenticity.
                                </label>
                            </div>
                        </div>
                    </div>
                )}
            </CardContent>

            <CardFooter className="p-10 pt-0 flex flex-col sm:flex-row gap-4 justify-between items-center w-full">
                {step !== 'professional' && (
                    <Button 
                        variant="ghost" 
                        onClick={() => {
                            if (step === 'identity') setStep('professional')
                            if (step === 'facial') setStep('identity')
                            if (step === 'review') setStep('facial')
                        }}
                        className="w-full sm:w-auto rounded-2xl h-14 px-8 font-black uppercase tracking-widest text-xs text-muted-foreground hover:bg-primary/5 hover:text-primary"
                    >
                        <ArrowLeft className="mr-3 h-4 w-4" />
                        Previous Step
                    </Button>
                )}

                {step !== 'review' ? (
                    <Button 
                        onClick={() => {
                            if (step === 'professional') {
                                if (!specialty || !experience || !licenseUrl) toast.error('Complete all professional details')
                                else setStep('identity')
                            } else if (step === 'identity') {
                                if (!idFrontUrl || !idBackUrl) toast.error('Both Front and Back identity assets are required')
                                else setStep('facial')
                            } else if (step === 'facial') {
                                if (!selfieUrl) toast.error('Biometric analysis capture required')
                                else setStep('review')
                            }
                        }}
                        className="w-full sm:w-auto sm:ml-auto rounded-2xl h-14 px-12 font-black bg-primary hover:bg-primary/90 shadow-xl shadow-primary/30 uppercase tracking-widest text-xs group"
                    >
                        Next Step
                        <ArrowRight className="ml-3 h-5 w-5 transition-transform group-hover:translate-x-1" />
                    </Button>
                ) : (
                    <Button 
                        onClick={() => {
                            if (!agreed) {
                                toast.error('You must accept the HIPAA/GDPR Ethics Agreement.')
                                return
                            }
                            handleSubmit()
                        }} 
                        disabled={loading} 
                        className="w-full sm:w-auto sm:ml-auto rounded-2xl h-14 px-12 font-black bg-green-600 hover:bg-green-700 shadow-xl shadow-green-600/30 uppercase tracking-widest text-xs"
                    >
                        {loading ? (
                            <>
                                <Loader2 className="mr-3 h-5 w-5 animate-spin" />
                                Submitting Application...
                            </>
                        ) : (
                            <>
                                Finalize & Apply
                                <Send className="ml-3 h-5 w-5" />
                            </>
                        )}
                    </Button>
                )}
            </CardFooter>
        </Card>
    )
}
