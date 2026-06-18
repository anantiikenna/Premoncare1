import { PatientMedicalRecords } from "@/components/patient/patient-medical-records"
import { createClient } from "@/lib/supabase-server"

export default async function RecordsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return null

    return (
        <div className="max-w-6xl mx-auto space-y-8">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">Medical Vault</h1>
                <p className="text-muted-foreground mt-1">Upload and securely share your medical history with trusted practitioners.</p>
            </div>
            
            <PatientMedicalRecords patientId={user.id} />
        </div>
    )
}
