import { createClient } from '@/lib/supabase-server'
import { getProfile } from '@/lib/queries'
import { redirect } from 'next/navigation'
import { Metadata } from 'next'
import { DisputeResolutionCenter } from '@/components/admin/disputes/dispute-resolution-center'

export const metadata: Metadata = {
    title: 'Dispute Resolution Center | Premon Care Admin',
    description: 'Mediate and resolve conflicts between patients and practitioners securely.',
}

export default async function AdminDisputesPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    const { data: profile } = await getProfile(user.id)
    if (profile?.role !== 'admin') redirect('/patient/dashboard')

    return (
        <div className="min-h-screen bg-slate-50">
            <DisputeResolutionCenter />
        </div>
    )
}
