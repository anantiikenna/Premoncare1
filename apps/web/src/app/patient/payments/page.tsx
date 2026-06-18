import { createClient } from '@/lib/supabase-server'
import { getProfile } from '@/lib/queries'
import { redirect } from 'next/navigation'
import { PaymentDashboard } from '@/components/patient/payment-dashboard'
import { Suspense } from 'react'

export default async function PaymentsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    const { data: profile } = await getProfile(user.id)
    if (profile?.role !== 'patient' && profile?.role !== 'doctor') redirect('/dashboard')

    return (
        <div className="space-y-6">
            <div className="flex flex-col gap-2">
                <h1 className="text-3xl font-bold tracking-tight">Payments & Billing</h1>
                <p className="text-muted-foreground">Submit and track your payments to book appointments with doctors.</p>
            </div>

            <Suspense fallback={<div className="flex justify-center p-8">Loading dashboard...</div>}>
                <PaymentDashboard userId={user.id} />
            </Suspense>
        </div>
    )
}
