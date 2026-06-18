import { createClient } from '@/lib/supabase-server'
import { getAppointments, getProfile } from '@/lib/queries'
import { redirect } from 'next/navigation'
import { DoctorAppointmentManager } from '@/components/doctor/appointment-manager'

export default async function DoctorAppointmentsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    const { data: profile } = await getProfile(user.id)
    if (profile?.role !== 'doctor') redirect('/dashboard')

    const { data: appointments } = await getAppointments(user.id, 'doctor')

    return (
        <div className="max-w-4xl mx-auto space-y-8">
            <div className="flex flex-col gap-2">
                <h1 className="text-3xl font-bold tracking-tight">Appointment Center</h1>
                <p className="text-muted-foreground">Manage your requests, confirm sessions, and start virtual meetings.</p>
            </div>

            <DoctorAppointmentManager appointments={appointments || []} docId={user.id} />
        </div>
    )
}
