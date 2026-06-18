import { BookingForm } from "@/components/appointments/booking-form"
import { PatientAppointmentsList } from "@/components/patient/appointments-list"
import { createClient } from "@/lib/supabase-server"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

export default async function AppointmentsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return null

    return (
        <div className="max-w-6xl mx-auto space-y-8">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">Appointments</h1>
                <p className="text-muted-foreground mt-1">Manage your consultations and book new sessions.</p>
            </div>

            <Tabs defaultValue="list" className="w-full">
                <TabsList className="grid w-full max-w-md grid-cols-2">
                    <TabsTrigger value="list">My Appointments</TabsTrigger>
                    <TabsTrigger value="book">Book New</TabsTrigger>
                </TabsList>
                <TabsContent value="list" className="mt-6">
                    <PatientAppointmentsList userId={user.id} />
                </TabsContent>
                <TabsContent value="book" className="mt-6">
                    <BookingForm />
                </TabsContent>
            </Tabs>
        </div>
    )
}
