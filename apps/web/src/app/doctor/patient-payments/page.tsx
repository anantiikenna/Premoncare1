import { createClient } from '@/lib/supabase-server'
import { redirect } from 'next/navigation'
import { DoctorPaymentReview } from '@/components/doctor/doctor-payments'

export default async function DoctorPaymentsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    const { data: profile } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single()

    if (profile?.role !== 'doctor') redirect('/dashboard')

    return (
        <div className="max-w-5xl mx-auto">
            <DoctorPaymentReview doctorId={user.id} />
        </div>
    )
}
