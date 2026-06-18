import { DoctorMedicalRecords } from "@/components/doctor/doctor-medical-records"
import { createClient } from "@/lib/supabase-server"

export default async function DoctorRecordsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return null

    return (
        <div className="max-w-6xl mx-auto space-y-8">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">Patient Records Vault</h1>
                <p className="text-muted-foreground mt-1">Safely decrypt and review medical documents explicitly shared with you by your patients.</p>
            </div>
            
            <DoctorMedicalRecords />
        </div>
    )
}
