import { createClient } from '@/lib/supabase-server'
import { NotificationsList } from '@/components/notifications/notifications-page'
import { redirect } from 'next/navigation'

export default async function NotificationsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    return (
        <div className="max-w-4xl mx-auto py-8">
            <NotificationsList userId={user.id} />
        </div>
    )
}
