import { createClient } from '@/lib/supabase-server'
import { redirect } from 'next/navigation'
import { PrescriptionList } from '@/components/patient/prescription-list'
import { Pill } from 'lucide-react'

export default async function PrescriptionsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    const { data: profile } = await supabase.from('profiles').select('role').eq('id', user.id).single()
    if (profile?.role !== 'patient') redirect('/dashboard')

    return (
        <div className="max-w-6xl mx-auto space-y-8">
            <div className="flex flex-col gap-2">
                <h1 className="text-3xl font-bold tracking-tight flex items-center gap-3">
                    <Pill className="h-8 w-8 text-primary" /> My Prescriptions
                </h1>
                <p className="text-muted-foreground">Review your medication orders from doctors.</p>
            </div>
            
            <PrescriptionList patientId={user.id} />
        </div>
    )
}
