import { createClient } from '@/lib/supabase-server'
import { NotificationsList } from '@/components/notifications/notifications-page'
import { redirect } from 'next/navigation'
import { Bell } from 'lucide-react'

export default async function PatientNotificationsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    return (
        <div className="max-w-4xl mx-auto space-y-6">
            <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center">
                    <Bell className="h-5 w-5 text-primary" />
                </div>
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Notifications</h1>
                    <p className="text-muted-foreground">Your appointment updates, prescriptions, and messages.</p>
                </div>
            </div>
            <NotificationsList userId={user.id} />
        </div>
    )
}
