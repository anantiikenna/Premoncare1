import { createClient } from '@/lib/supabase-server'
import { getProfile } from '@/lib/queries'
import { redirect } from 'next/navigation'
import { MedicalProfileForm } from '@/components/patient/medical-profile-form'

export default async function MedicalProfilePage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    const { data: profile } = await getProfile(user.id)
    if (profile?.role !== 'patient') redirect('/dashboard')

    return (
        <div className="max-w-4xl mx-auto space-y-8">
            <div className="flex flex-col gap-2">
                <h1 className="text-3xl font-bold tracking-tight">Medical Profile</h1>
                <p className="text-muted-foreground">Keep your health history updated for better care.</p>
            </div>
            
            <MedicalProfileForm patientId={user.id} />
        </div>
    )
}
