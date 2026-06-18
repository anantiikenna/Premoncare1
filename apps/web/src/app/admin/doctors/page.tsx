import { createClient } from '@/lib/supabase-server'
import { getProfile } from '@/lib/queries'
import { redirect } from 'next/navigation'
import { DoctorManagement } from '@/components/admin/doctor-management'
import { Users } from 'lucide-react'
import { AdminDoctorsActions } from '@/components/admin/admin-doctors-actions'

export default async function AdminDoctorsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    const { data: profile } = await getProfile(user.id)
    if (profile?.role !== 'admin') redirect('/patient/dashboard')

    return (
        <div className="space-y-8 animate-in-fade">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-8 rounded-3xl border shadow-sm">
                <div className="space-y-1">
                    <div className="flex items-center gap-2 text-primary font-bold">
                        <Users className="h-5 w-5" />
                        Professional Management
                    </div>
                    <h1 className="text-4xl font-extrabold tracking-tight text-slate-900">Doctor Verification & Fees</h1>
                    <p className="text-muted-foreground text-lg italic">
                        Approve healthcare providers and negotiate their monthly service fees.
                    </p>
                </div>
                <AdminDoctorsActions />
            </div>

            <DoctorManagement />
        </div>
    )
}
