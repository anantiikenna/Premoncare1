import { createClient } from '@/lib/supabase-server'
import { getProfile } from '@/lib/queries'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { PatientProfileSettings } from '@/components/patient/profile-settings'
import { ApplyPractitioner } from '@/components/doctor/apply-practitioner'

export default async function ProfilePage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    const { data: profile } = await getProfile(user.id)
    if (profile?.role !== 'patient') redirect(`/${profile?.role}/dashboard`)

    return (
        <div className="max-w-4xl mx-auto space-y-12 pb-12">
            <div className="flex flex-col gap-2">
                <h1 className="text-3xl font-bold tracking-tight">Your Profile</h1>
                <p className="text-muted-foreground">Manage your personal information and practitioner application status.</p>
            </div>
            
            <PatientProfileSettings patientId={user.id} />

            <ApplyPractitioner profile={profile} />

            <div className="bg-primary/5 p-8 rounded-3xl border border-primary/10 flex flex-col sm:flex-row items-center justify-between gap-6 transition-all hover:bg-primary/10">
                <div className="flex-1">
                    <h3 className="font-bold text-xl text-slate-900 mb-2">Medical History & Records</h3>
                    <p className="text-sm text-slate-600 leading-relaxed">Update your allergies, medications, and health history to help your healthcare providers give you the best care possible.</p>
                </div>
                <Link href="/patient/medical-profile" className="w-full sm:w-auto shrink-0">
                    <Button variant="secondary" className="w-full h-12 px-8 rounded-full border-primary/20 font-bold hover:shadow-md transition-all">
                        View Medical Profile
                    </Button>
                </Link>
            </div>
        </div>
    )
}
