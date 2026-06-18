'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase'
import { getProfile, updateProfile } from '@/lib/queries-client'
import { Profile } from '@/lib/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { toast } from 'sonner'
import { Loader2, ShieldCheck, Save, User } from 'lucide-react'

export default function AdminProfilePage() {
    const [loading, setLoading] = useState(true)
    const [saving, setSaving] = useState(false)
    const [profile, setProfile] = useState<Profile | null>(null)
    const [fullName, setFullName] = useState('')
    const supabase = createClient()

    useEffect(() => {
        async function load() {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) return
            const { data } = await getProfile(user.id)
            if (data) {
                setProfile(data)
                setFullName(data.full_name || '')
            }
            setLoading(false)
        }
        load()
    }, [supabase.auth])

    const handleSave = async () => {
        if (!profile) return
        setSaving(true)
        try {
            const { error } = await updateProfile(profile.id, { full_name: fullName })
            if (error) throw error
            toast.success('Profile updated successfully')
        } catch (err: unknown) {
            const errorMessage = err instanceof Error ? err.message : 'Unknown error'
            toast.error('Failed to update: ' + errorMessage)
        } finally {
            setSaving(false)
        }
    }

    if (loading) {
        return <div className="flex justify-center py-20"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>
    }

    return (
        <div className="max-w-2xl mx-auto space-y-8">
            <div className="flex items-center gap-3">
                <div className="h-12 w-12 rounded-full bg-primary/15 flex items-center justify-center">
                    <ShieldCheck className="h-6 w-6 text-primary" />
                </div>
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Admin Profile</h1>
                    <p className="text-muted-foreground">Manage your administrator account settings.</p>
                </div>
            </div>

            <Card className="shadow-sm border-primary/5">
                <CardHeader>
                    <CardTitle className="flex items-center gap-2 text-xl">
                        <User className="h-5 w-5 text-primary" /> Account Details
                    </CardTitle>
                    <CardDescription>Update your display name and account information.</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                    <div className="space-y-1.5">
                        <label className="text-sm font-medium">Full Name</label>
                        <Input
                            value={fullName}
                            onChange={e => setFullName(e.target.value)}
                            placeholder="Your full name"
                        />
                    </div>
                    <div className="space-y-1.5">
                        <label className="text-sm font-medium text-muted-foreground">Role</label>
                        <div className="flex items-center gap-2 px-3 py-2 rounded-lg border bg-muted/30 text-sm">
                            <ShieldCheck className="h-4 w-4 text-primary" />
                            <span className="capitalize font-medium">{profile?.role}</span>
                        </div>
                    </div>
                    <div className="space-y-1.5">
                        <label className="text-sm font-medium text-muted-foreground">User ID</label>
                        <div className="px-3 py-2 rounded-lg border bg-muted/30 text-xs text-muted-foreground font-mono">
                            {profile?.id}
                        </div>
                    </div>
                    <div className="pt-2">
                        <Button onClick={handleSave} disabled={saving} className="gap-2">
                            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                            Save Changes
                        </Button>
                    </div>
                </CardContent>
            </Card>
        </div>
    )
}
