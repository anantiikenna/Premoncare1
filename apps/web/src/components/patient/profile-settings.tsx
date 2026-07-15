'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { updateProfile, getProfile } from '@/lib/queries-client'
import { Loader2, User, Bell, ShieldCheck, FileUp } from 'lucide-react'
import { Switch } from '@/components/ui/switch'
import { AvatarUpload } from '@/components/ui/avatar-upload'

export function PatientProfileSettings({ patientId }: { patientId: string }) {
    const [loading, setLoading] = useState(true)
    const [saving, setSaving] = useState(false)
    const [fullName, setFullName] = useState('')
    const [avatarUrl, setAvatarUrl] = useState('')
    const [emailAlerts, setEmailAlerts] = useState(true)
    
    // New Fields
    const [phone, setPhone] = useState('')
    const [address, setAddress] = useState('')
    const [dob, setDob] = useState('')
    const [gender, setGender] = useState('')
    const [bloodGroup, setBloodGroup] = useState('')
    const [nextOfKinName, setNextOfKinName] = useState('')
    const [nextOfKinPhone, setNextOfKinPhone] = useState('')
    const [emergencyName, setEmergencyName] = useState('')
    const [emergencyPhone, setEmergencyPhone] = useState('')
    const [idUrl, setIdUrl] = useState('')
    const [originalIdUrl, setOriginalIdUrl] = useState('')
    const [uploadingId, setUploadingId] = useState(false)

    // Security States
    const [newEmail, setNewEmail] = useState('')
    const [newPassword, setNewPassword] = useState('')
    const [securityLoading, setSecurityLoading] = useState(false)
    
    const supabase = createClient()

    useEffect(() => {
        const fetchInitialData = async () => {
            const { data, error } = await getProfile(patientId)
            if (data) {
                setFullName(data.full_name || '')
                setAvatarUrl(data.avatar_url || '')
                setEmailAlerts(data.email_alerts_enabled !== false)
                setPhone(data.phone || '')
                setAddress(data.address || '')
                setDob(data.dob || '')
                setGender(data.gender || '')
                setBloodGroup(data.blood_group || '')
                setNextOfKinName(data.next_of_kin_name || '')
                setNextOfKinPhone(data.next_of_kin_phone || '')
                setEmergencyName(data.emergency_contact_name || '')
                setEmergencyPhone(data.emergency_contact_phone || '')
                setIdUrl(data.identity_document_url || '')
                setOriginalIdUrl(data.identity_document_url || '')
            }
            setLoading(false)
        }
        fetchInitialData()
    }, [patientId])

    const handleSave = async (e: React.FormEvent) => {
        e.preventDefault()
        if (!fullName.trim()) {
            toast.error('Full name is required')
            return
        }
        if (phone && !/^\+?[\d\s-]{7,15}$/.test(phone)) {
            toast.error('Invalid phone number format')
            return
        }
        const validBloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', '']
        if (bloodGroup && !validBloodGroups.includes(bloodGroup)) {
            toast.error('Invalid blood group')
            return
        }
        setSaving(true)
        try {
            const updates = {
                full_name: fullName.trim(),
                avatar_url: avatarUrl,
                email_alerts_enabled: emailAlerts,
                phone: phone || null,
                address: address || null,
                dob: dob || null,
                gender: gender || null,
                blood_group: bloodGroup || null,
                next_of_kin_name: nextOfKinName || null,
                next_of_kin_phone: nextOfKinPhone || null,
                emergency_contact_name: emergencyName || null,
                emergency_contact_phone: emergencyPhone || null,
                identity_document_url: idUrl || null,
                updated_at: new Date().toISOString()
            }
            const { error } = await updateProfile(patientId, updates)
            if (error) throw error

            if (originalIdUrl && originalIdUrl !== idUrl) {
                try {
                    const oldPath = originalIdUrl.split('/patient-identity-documents/')[1]?.split('?')[0]
                    if (oldPath) await supabase.storage.from('patient-identity-documents').remove([oldPath])
                } catch (_) {}
            }

            toast.success('Profile updated successfully')
            window.location.reload()
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

    const validatePassword = (pass: string) => {
        const minLength = 8
        const hasUpperCase = /[A-Z]/.test(pass)
        const hasLowerCase = /[a-z]/.test(pass)
        const hasNumber = /[0-9]/.test(pass)
        const hasSymbol = /[!@#$%^&*(),.?":{}|<>]/.test(pass)

        if (pass.length < minLength) return 'Password must be at least 8 characters long'
        if (!hasUpperCase || !hasLowerCase) return 'Password must contain both uppercase and lowercase letters'
        if (!hasNumber) return 'Password must contain at least one number'
        if (!hasSymbol) return 'Password must contain at least one symbol'
        return null
    }

    const handleChangePassword = async () => {
        const pwdError = validatePassword(newPassword)
        if (pwdError) {
            toast.error(pwdError)
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

    const handleIdUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        setUploadingId(true);
        try {
            const fileExt = file.name.split('.').pop();
            const fileName = `${patientId}/id_${Date.now()}.${fileExt}`;
            const { error: uploadError } = await supabase.storage
                .from('patient-identity-documents')
                .upload(fileName, file);
            if (uploadError) throw uploadError;
            const { data: { publicUrl } } = supabase.storage.from('patient-identity-documents').getPublicUrl(fileName);
            setIdUrl(publicUrl);
            toast.success('Identity document uploaded');
        } catch (err: any) {
            toast.error('Upload failed: ' + err.message);
        } finally {
            setUploadingId(false);
        }
    }

    if (loading) return <div className="flex justify-center p-8"><Loader2 className="h-8 w-8 animate-spin" /></div>

    return (
        <div className="space-y-6">
            <Card className="border-primary/10 shadow-sm overflow-hidden rounded-[2rem]">
                <CardHeader className="bg-muted/30">
                    <CardTitle className="flex items-center gap-2">
                        <User className="h-5 w-5 text-primary" />
                        Personal Health Profile
                    </CardTitle>
                    <CardDescription>Update your medical identifiers and emergency contacts.</CardDescription>
                </CardHeader>
                <CardContent className="pt-6">
                    <form onSubmit={handleSave} className="space-y-8">
                        <div className="flex flex-col items-center sm:flex-row gap-8 pb-8 border-b border-dashed">
                            <div className="space-y-2 text-center sm:text-left">
                                <Label className="text-xs font-bold uppercase tracking-widest text-muted-foreground ml-1">Profile Photo</Label>
                                <AvatarUpload 
                                    userId={patientId}
                                    currentAvatarUrl={avatarUrl}
                                    onUploadSuccess={(url) => setAvatarUrl(url)}
                                />
                            </div>
                            <div className="flex-1 space-y-2">
                                <h3 className="text-lg font-bold leading-none">Identity & Presence</h3>
                                <p className="text-sm text-muted-foreground leading-relaxed">
                                    Your profile photo is used for practitioner identification and across your digital medical vault.
                                </p>
                            </div>
                        </div>

                        <div className="grid md:grid-cols-2 gap-6">
                            <div className="space-y-2">
                                <Label htmlFor="fullName">Full Name</Label>
                                <Input id="fullName" value={fullName} onChange={(e) => setFullName(e.target.value)} required className="rounded-xl h-12" />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="phone">Phone Number</Label>
                                <Input id="phone" placeholder="+234..." value={phone} onChange={(e) => setPhone(e.target.value)} className="rounded-xl h-12" />
                            </div>
                        </div>

                        <div className="grid md:grid-cols-2 gap-6">
                            <div className="grid grid-cols-2 gap-4">
                                <div className="space-y-2">
                                    <Label htmlFor="dob">Date of Birth</Label>
                                    <Input id="dob" type="date" value={dob} onChange={(e) => setDob(e.target.value)} className="rounded-xl h-12" />
                                </div>
                                <div className="space-y-2">
                                    <Label htmlFor="gender">Gender</Label>
                                    <select 
                                        id="gender" 
                                        value={gender} 
                                        onChange={(e) => setGender(e.target.value)}
                                        className="w-full h-12 rounded-xl border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
                                    >
                                        <option value="">Select...</option>
                                        <option value="male">Male</option>
                                        <option value="female">Female</option>
                                        <option value="other">Other</option>
                                    </select>
                                </div>
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="address">Address</Label>
                                <Input id="address" placeholder="Home address" value={address} onChange={(e) => setAddress(e.target.value)} className="rounded-xl h-12" />
                            </div>
                        </div>

                        <div className="grid md:grid-cols-3 gap-6 pt-4 border-t border-dashed">
                            <div className="space-y-2">
                                <Label htmlFor="blood">Blood Group</Label>
                                <Input id="blood" placeholder="e.g. O+" value={bloodGroup} onChange={(e) => setBloodGroup(e.target.value)} className="rounded-xl h-12" />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="nokN">Next of Kin Name</Label>
                                <Input id="nokN" placeholder="Full Name" value={nextOfKinName} onChange={(e) => setNextOfKinName(e.target.value)} className="rounded-xl h-12" />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="nokP">Next of Kin Phone</Label>
                                <Input id="nokP" placeholder="+234..." value={nextOfKinPhone} onChange={(e) => setNextOfKinPhone(e.target.value)} className="rounded-xl h-12" />
                            </div>
                        </div>

                        <div className="grid md:grid-cols-2 gap-6 pt-4 border-t border-dashed">
                            <div className="space-y-2">
                                <Label htmlFor="eN">Emergency Contact Name</Label>
                                <Input id="eN" placeholder="Full Name" value={emergencyName} onChange={(e) => setEmergencyName(e.target.value)} className="rounded-xl h-12" />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="eP">Emergency Contact Phone</Label>
                                <Input id="eP" placeholder="+234..." value={emergencyPhone} onChange={(e) => setEmergencyPhone(e.target.value)} className="rounded-xl h-12" />
                            </div>
                        </div>

                        <div className="space-y-4 pt-4 border-t border-dashed">
                            <div className="flex items-center gap-2 mb-2">
                                <ShieldCheck className="h-4 w-4 text-primary" />
                                <h3 className="font-bold text-sm">Identity Verification</h3>
                            </div>
                            <div className="p-6 bg-muted/20 border border-dashed rounded-2xl flex flex-col items-center text-center gap-4">
                                {idUrl ? (
                                    <div className="space-y-3 w-full">
                                        <div className="h-40 w-full rounded-xl overflow-hidden border bg-background flex items-center justify-center">
                                            <img src={idUrl} alt="Identity Card" className="h-full w-full object-contain" />
                                        </div>
                                        <Button variant="outline" size="sm" onClick={() => setIdUrl('')} className="rounded-full">Replace Identity Card</Button>
                                    </div>
                                ) : (
                                    <>
                                        <div className="p-4 bg-primary/10 rounded-full">
                                            <FileUp className="h-8 w-8 text-primary" />
                                        </div>
                                        <div className="space-y-1">
                                            <p className="font-bold">National ID or Driver's License</p>
                                            <p className="text-xs text-muted-foreground">Upload a clear photo of your government-issued ID for verification.</p>
                                        </div>
                                        <div className="relative">
                                            <Button disabled={uploadingId} className="rounded-xl px-8 font-bold">
                                                {uploadingId ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Select ID Card'}
                                            </Button>
                                            <input 
                                                type="file" 
                                                className="absolute inset-0 opacity-0 cursor-pointer" 
                                                accept="image/*"
                                                onChange={handleIdUpload}
                                            />
                                        </div>
                                    </>
                                )}
                            </div>
                        </div>

                        <div className="space-y-4 pt-4 border-t border-dashed">
                            <div className="flex items-center gap-2 mb-2">
                                <Bell className="h-4 w-4 text-primary" />
                                <h3 className="font-bold text-sm">Notification Preferences</h3>
                            </div>
                            <div className="flex items-center justify-between p-4 bg-muted/30 rounded-xl border border-primary/5">
                                <div className="space-y-0.5">
                                    <Label htmlFor="email-notifications" className="text-base">Email Notifications</Label>
                                    <p className="text-xs text-muted-foreground">Receive real-time updates for payments and account status.</p>
                                </div>
                                <Switch id="email-notifications" checked={emailAlerts} onCheckedChange={setEmailAlerts} />
                            </div>
                        </div>
                        
                        <div className="pt-4 flex justify-end">
                            <Button type="submit" disabled={saving} className="min-w-[150px] rounded-full h-12 font-bold shadow-lg shadow-primary/20">
                                {saving ? <><Loader2 className="mr-2 h-4 w-4 animate-spin" /> Saving...</> : 'Update Health Profile'}
                            </Button>
                        </div>
                    </form>
                </CardContent>
            </Card>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <Card className="border-primary/10 shadow-sm rounded-[2rem] overflow-hidden">
                    <CardHeader className="bg-amber-50/50 border-b border-amber-100">
                        <CardTitle className="text-lg">Update Email Address</CardTitle>
                        <CardDescription>A confirmation link will be sent to the new address.</CardDescription>
                    </CardHeader>
                    <CardContent className="pt-6 space-y-4">
                        <div className="space-y-2">
                            <Label htmlFor="newEmail">New Email Address</Label>
                            <Input 
                                id="newEmail" 
                                type="email" 
                                placeholder="new@example.com" 
                                value={newEmail}
                                onChange={(e) => setNewEmail(e.target.value)}
                                className="rounded-xl h-11"
                            />
                        </div>
                        <Button 
                            onClick={handleChangeEmail} 
                            disabled={securityLoading || !newEmail}
                            className="w-full rounded-xl h-11 font-bold bg-amber-600 hover:bg-amber-700"
                        >
                            {securityLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Change Email'}
                        </Button>
                    </CardContent>
                </Card>

                <Card className="border-primary/10 shadow-sm rounded-[2rem] overflow-hidden">
                    <CardHeader className="bg-blue-50/50 border-b border-blue-100">
                        <CardTitle className="text-lg">Update Password</CardTitle>
                        <CardDescription>Ensure your new password follows security rules.</CardDescription>
                    </CardHeader>
                    <CardContent className="pt-6 space-y-4">
                        <div className="space-y-2">
                            <Label htmlFor="newPass">New Password</Label>
                            <Input 
                                id="newPass" 
                                type="password" 
                                placeholder="••••••••" 
                                value={newPassword}
                                onChange={(e) => setNewPassword(e.target.value)}
                                className="rounded-xl h-11"
                            />
                        </div>
                        <Button 
                            onClick={handleChangePassword} 
                            disabled={securityLoading || !newPassword}
                            className="w-full rounded-xl h-11 font-bold bg-blue-600 hover:bg-blue-700"
                        >
                            {securityLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Change Password'}
                        </Button>
                    </CardContent>
                </Card>
            </div>
        </div>
    )
}
