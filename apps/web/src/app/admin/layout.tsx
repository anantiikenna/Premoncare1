import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase-server'
import { getProfile } from '@/lib/queries'
import { DashboardLayout } from "@/components/layout/dashboard-layout"

export default async function AdminDashboardLayout({
    children,
}: {
    children: React.ReactNode
}) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    const { data: profile } = await getProfile(user.id)
    if (profile?.role !== 'admin') redirect('/patient/dashboard')

    return <DashboardLayout>{children}</DashboardLayout>
}
