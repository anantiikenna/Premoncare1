import { createClient } from '@/lib/supabase-server'
import { getProfile } from '@/lib/queries'
import { redirect } from 'next/navigation'
import { ScheduleManagement } from '@/components/doctor/schedule-management'
import { Clock } from 'lucide-react'
import { SchedulePageHeader } from './schedule-page-header'

export default async function DoctorSchedulePage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    const { data: profile } = await getProfile(user.id)
    if (profile?.role !== 'doctor') redirect('/patient/dashboard')

    return (
        <div className="space-y-8 animate-in-fade">
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6 bg-white p-8 rounded-[2.5rem] border shadow-sm relative overflow-hidden group">
                <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-primary via-accent to-primary opacity-50" />
                <div className="space-y-2 relative z-10">
                    <div className="flex items-center gap-2 text-primary font-black uppercase tracking-widest text-xs">
                        <Clock className="h-4 w-4" />
                        Practitioner Tools
                    </div>
                    <h1 className="text-4xl font-black tracking-tighter text-slate-900">Availability & Schedule</h1>
                    <p className="text-muted-foreground text-lg font-medium max-w-xl">
                        Define your clinical hours, manage break times, and configure emergency availability to streamline your practice.
                    </p>
                </div>
                <SchedulePageHeader />
            </div>

            <ScheduleManagement />
        </div>
    )
}
