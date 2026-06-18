import { createClient } from '@/lib/supabase-server'
import { getProfile } from '@/lib/queries'
import { redirect } from 'next/navigation'
import { DoctorProfileSettings } from '@/components/doctor/profile-settings'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import Link from 'next/link'
import { Button } from '@/components/ui/button'

export default async function ProfilePage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    const { data: profile } = await getProfile(user.id)
    
    if (profile?.role !== 'doctor') {
        // Fallback for non-doctors if we use a shared route, or just redirect
        redirect(`/${profile?.role}/dashboard`) 
    }

    return (
        <div className="max-w-4xl mx-auto space-y-8">
            <div className="flex flex-col gap-2">
                <h1 className="text-3xl font-bold tracking-tight">My Profile</h1>
                <p className="text-muted-foreground">Manage your personal and professional information.</p>
            </div>
            
            <div className="grid gap-6">
                <DoctorProfileSettings doctorId={user.id} />
                
                <div className="bg-primary/5 p-6 rounded-2xl border border-primary/10 flex flex-col sm:flex-row items-center justify-between gap-4">
                    <div>
                        <h3 className="font-bold text-lg text-slate-900">Patient Reviews</h3>
                        <p className="text-sm text-slate-600">See what your patients are saying about their experience.</p>
                    </div>
                    <Link href="/doctor/reviews" className="w-full sm:w-auto">
                        <Button variant="secondary" className="w-full rounded-full border-primary/20 hover:bg-primary/10 transition-colors">
                            View My Reviews
                        </Button>
                    </Link>
                </div>
            </div>
        </div>
    )
}
