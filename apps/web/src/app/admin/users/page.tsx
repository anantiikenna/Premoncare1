import { createClient } from '@/lib/supabase-server'
import { getProfile } from '@/lib/queries'
import { redirect } from 'next/navigation'
import { UserManagement } from '@/components/admin/user-management'
import { Users } from 'lucide-react'
import { AdminUsersActions } from '@/components/admin/admin-users-actions'

export default async function AdminUsersPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    const { data: profile } = await getProfile(user.id)
    if (profile?.role !== 'admin') redirect('/patient/dashboard')

    return (
        <div className="space-y-8 animate-in-fade">
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6 bg-white p-8 rounded-[2.5rem] border shadow-sm relative overflow-hidden group">
                <div className="absolute top-0 left-0 w-full h-1 bg-linear-to-r from-primary via-accent to-primary opacity-50" />
                <div className="space-y-2 relative z-10">
                    <div className="flex items-center gap-2 text-primary font-black uppercase tracking-widest text-xs">
                        <Users className="h-4 w-4" />
                        Admin
                    </div>
                    <h1 className="text-4xl font-black tracking-tighter text-slate-900">User Management</h1>
                    <p className="text-muted-foreground text-lg font-medium max-w-xl">
                        Monitor system activity, manage access levels, and perform administrative moderation on all platform participants.
                    </p>
                </div>
                <AdminUsersActions />
            </div>

            <UserManagement />
        </div>
    )
}
