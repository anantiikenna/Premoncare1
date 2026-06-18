'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { updateProfile, getProfile } from '@/lib/queries-client'
import { Loader2, User, Bell, Camera, ShieldCheck } from 'lucide-react'
import { Switch } from '@/components/ui/switch'
import { AvatarUpload } from '@/components/ui/avatar-upload'
import { Textarea } from '@/components/ui/textarea'

export function DoctorProfileSettings({ doctorId }: { doctorId: string }) {
    const [loading, setLoading] = useState(true)
    const [saving, setSaving] = useState(false)
    const [profile, setProfile] = useState({
        full_name: '',
        avatar_url: '',
        specialty: '',
        experience_years: '',
        clinic_address: '',
        consultation_fee: '0',
        payment_instructions: '',
        dob: '',
        gender: '',
        bank_name: '',
        account_name: '',
        account_number: ''
    })
    const [isApproved, setIsApproved] = useState(false)
    const [allowCustomPricing, setAllowCustomPricing] = useState(false)

    // Security States
    const [newEmail, setNewEmail] = useState('')
    const [newPassword, setNewPassword] = useState('')
    const [securityLoading, setSecurityLoading] = useState(false)
    
    const supabase = createClient()

    useEffect(() => {
        const fetchInitialData = async () => {
            const [settingsRes, profileRes] = await Promise.all([
                supabase.from('system_settings').select('allow_doctor_pricing').eq('id', 'default').single(),
                supabase.from('profiles').select('*').eq('id', doctorId).single()
            ])

            if (settingsRes.data) {
                setAllowCustomPricing(true)
            }

            if (profileRes.data) {
                const data = profileRes.data as any
                setIsApproved(data.verification_status === 'approved')
                setProfile({
                    full_name: data.full_name || '',
                    avatar_url: data.avatar_url || '',
                    specialty: data.specialty || '',
                    experience_years: data.experience_years ? data.experience_years.toString() : '',
                    clinic_address: data.clinic_address || '',
                    consultation_fee: data.consultation_fee ? data.consultation_fee.toString() : '0',
                    payment_instructions: data.payment_instructions || '',
                    dob: data.dob || '',
                    gender: data.gender || '',
                    bank_name: data.bank_name || '',
                    account_name: data.account_name || '',
                    account_number: data.account_number || ''
                })
            }
            setLoading(false)
        }
        fetchInitialData()
    }, [doctorId, supabase])

    const handleSave = async (e: React.FormEvent) => {
        e.preventDefault()
        setSaving(true)
        try {
            const updates = {
                full_name: profile.full_name,
                avatar_url: profile.avatar_url,
                specialty: profile.specialty,
                experience_years: profile.experience_years ? parseInt(profile.experience_years) : undefined,
                clinic_address: profile.clinic_address,
                consultation_fee: parseFloat(profile.consultation_fee) || 0,
                payment_instructions: profile.payment_instructions,
                dob: profile.dob,
                gender: profile.gender,
                bank_name: profile.bank_name,
                account_name: profile.account_name,
                account_number: profile.account_number,
                updated_at: new Date().toISOString()
            }
            const { error } = await updateProfile(doctorId, updates)
            if (error) throw error
            toast.success('Professional profile updated successfully')
        } catch (error: unknown) {
            toast.error('Failed to update profile: ' + (error instanceof Error ? error.message : String(error)))
        } finally {
            setSaving(false)
        }
    }

    const handleChangeEmail = async () => {
        if (!newEmail) return
        setSecurityLoading(true)
        try {
            const { error } = await supabase.auth.updateUser({ email: newEmail })
            if (error) throw error
            toast.success('Confirmation link sent to your new email')
            setNewEmail('')
        } catch (err: any) {
            toast.error(err.message)
        } finally {
            setSecurityLoading(false)
        }
    }

    const handleChangePassword = async () => {
        if (!newPassword || newPassword.length < 8) {
            toast.error('Password must be at least 8 characters')
            return
        }
        setSecurityLoading(true)
        try {
            const { error } = await supabase.auth.updateUser({ password: newPassword })
            if (error) throw error
            toast.success('Password updated successfully')
            setNewPassword('')
        } catch (err: any) {
            toast.error(err.message)
        } finally {
            setSecurityLoading(false)
        }
    }

    if (loading) return <div className="flex justify-center p-8"><Loader2 className="h-8 w-8 animate-spin" /></div>

    return (
        <div className="space-y-6">
            <Card className="border-primary/10 shadow-sm overflow-hidden rounded-[2rem]">
                <CardHeader className="bg-muted/30">
                    <CardTitle className="flex items-center gap-2">
                        <User className="h-5 w-5 text-primary" />
                        Professional & Personal Details
                    </CardTitle>
                    <CardDescription>Update your specialization, clinic information, and account details.</CardDescription>
                </CardHeader>
                <CardContent className="pt-6">
                    <form onSubmit={handleSave} className="space-y-8">
                        <div className="flex flex-col items-center sm:flex-row gap-8 pb-8 border-b border-dashed">
                            <div className="space-y-4 text-center sm:text-left">
                                <div className="flex items-center gap-2 mb-1">
                                    <Label className="text-xs font-bold uppercase tracking-widest text-muted-foreground ml-1">Professional Avatar</Label>
                                    {isApproved && <ShieldCheck className="h-4 w-4 text-green-600" />}
                                </div>
                                <AvatarUpload 
                                    userId={doctorId}
                                    currentAvatarUrl={profile.avatar_url}
                                    onUploadSuccess={(url) => setProfile({...profile, avatar_url: url})}
                                />
                            </div>
                            <div className="flex-1 space-y-4 w-full">
                                <div className="space-y-2">
                                    <Label htmlFor="fullName" className="font-bold">Official Practitioner Name</Label>
                                    <Input 
                                        id="fullName" 
                                        placeholder="Dr. John Doe" 
                                        value={profile.full_name} 
                                        onChange={(e) => setProfile({...profile, full_name: e.target.value})} 
                                        className="bg-background h-12 text-lg rounded-xl"
                                        required
                                    />
                                </div>
                            </div>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div className="space-y-2">
                                <Label htmlFor="specialty">Primary Specialty</Label>
                                <Input 
                                    id="specialty" 
                                    placeholder="e.g. Cardiologist, Dermatologist" 
                                    value={profile.specialty} 
                                    onChange={(e) => setProfile({...profile, specialty: e.target.value})} 
                                    className="rounded-xl h-12"
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div className="space-y-2">
                                    <Label htmlFor="experience">Years of Experience</Label>
                                    <Input 
                                        id="experience" 
                                        type="number" 
                                        placeholder="e.g. 10" 
                                        value={profile.experience_years} 
                                        onChange={(e) => setProfile({...profile, experience_years: e.target.value})} 
                                        className="rounded-xl h-12"
                                    />
                                </div>
                                <div className="space-y-2">
                                    <Label htmlFor="gender">Gender</Label>
                                    <select 
                                        id="gender" 
                                        value={profile.gender} 
                                        onChange={(e) => setProfile({...profile, gender: e.target.value})}
                                        className="w-full h-12 rounded-xl border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
                                    >
                                        <option value="">Select...</option>
                                        <option value="male">Male</option>
                                        <option value="female">Female</option>
                                    </select>
                                </div>
                            </div>
                        </div>

                        <div className="grid md:grid-cols-2 gap-6">
                            <div className="space-y-2">
                                <Label htmlFor="dob">Date of Birth</Label>
                                <Input id="dob" type="date" value={profile.dob} onChange={(e) => setProfile({...profile, dob: e.target.value})} className="rounded-xl h-12" />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="address">Clinic Address</Label>
                                <Input id="address" placeholder="Primary practice address" value={profile.clinic_address} onChange={(e) => setProfile({...profile, clinic_address: e.target.value})} className="rounded-xl h-12" />
                            </div>
                        </div>

                        <div className="pt-6 border-t border-dashed space-y-6">
                            <div className="flex items-center gap-2">
                                <ShieldCheck className="h-5 w-5 text-primary" />
                                <h3 className="font-bold text-lg">P2P Payment Details</h3>
                            </div>
                            
                            <div className="grid md:grid-cols-3 gap-4">
                                <div className="space-y-2">
                                    <Label htmlFor="bank">Bank Name</Label>
                                    <Input id="bank" placeholder="e.g. Zenith Bank" value={profile.bank_name} onChange={(e) => setProfile({...profile, bank_name: e.target.value})} className="rounded-xl h-11" />
                                </div>
                                <div className="space-y-2">
                                    <Label htmlFor="accN">Account Name</Label>
                                    <Input id="accN" placeholder="Name on account" value={profile.account_name} onChange={(e) => setProfile({...profile, account_name: e.target.value})} className="rounded-xl h-11" />
                                </div>
                                <div className="space-y-2">
                                    <Label htmlFor="accNo">Account Number</Label>
                                    <Input id="accNo" placeholder="10-digit number" value={profile.account_number} onChange={(e) => setProfile({...profile, account_number: e.target.value})} className="rounded-xl h-11" />
                                </div>
                            </div>

                            <div className="space-y-2">
                                <Label htmlFor="fee" className="font-bold text-primary">Consultation Fee (₦)</Label>
                                <Input id="fee" type="number" value={profile.consultation_fee} onChange={(e) => setProfile({...profile, consultation_fee: e.target.value})} className="h-12 text-lg font-bold bg-accent/20 border-primary/20 rounded-xl" />
                            </div>

                            <div className="space-y-2">
                                <Label htmlFor="instructions" className="font-bold">Additional Payment Instructions</Label>
                                <Textarea 
                                    id="instructions"
                                    placeholder="Any additional details if bank transfer isn't the only option..."
                                    value={profile.payment_instructions}
                                    onChange={(e) => setProfile({...profile, payment_instructions: e.target.value})}
                                    className="min-h-[80px] bg-background border-primary/10 rounded-xl"
                                />
                            </div>
                        </div>
                        
                        <div className="pt-4 flex justify-end">
                            <Button type="submit" disabled={saving} className="min-w-[150px] rounded-full h-12 font-bold shadow-lg shadow-primary/20">
                                {saving ? <><Loader2 className="mr-2 h-4 w-4 animate-spin" /> Saving...</> : 'Save Professional Profile'}
                            </Button>
                        </div>
                    </form>
                </CardContent>
            </Card>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pb-10">
                <Card className="border-primary/10 shadow-sm rounded-[2rem] overflow-hidden">
                    <CardHeader className="bg-amber-50/50 border-b border-amber-100">
                        <CardTitle className="text-lg">Update Professional Email</CardTitle>
                    </CardHeader>
                    <CardContent className="pt-6 space-y-4">
                        <Input type="email" placeholder="new@example.com" value={newEmail} onChange={(e) => setNewEmail(e.target.value)} className="rounded-xl h-11" />
                        <Button onClick={handleChangeEmail} disabled={securityLoading || !newEmail} className="w-full rounded-xl h-11 font-bold bg-amber-600 hover:bg-amber-700">
                             Email Change
                        </Button>
                    </CardContent>
                </Card>

                <Card className="border-primary/10 shadow-sm rounded-[2rem] overflow-hidden">
                    <CardHeader className="bg-blue-50/50 border-b border-blue-100">
                        <CardTitle className="text-lg">Update Security Password</CardTitle>
                    </CardHeader>
                    <CardContent className="pt-6 space-y-4">
                        <Input type="password" placeholder="••••••••" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} className="rounded-xl h-11" />
                        <Button onClick={handleChangePassword} disabled={securityLoading || !newPassword} className="w-full rounded-xl h-11 font-bold bg-blue-600 hover:bg-blue-700">
                             Password Update
                        </Button>
                    </CardContent>
                </Card>
            </div>
        </div>
    )
}
