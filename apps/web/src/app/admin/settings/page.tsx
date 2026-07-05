import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase-server'
import { getProfile } from '@/lib/queries'
import { AdminSettings } from '@/components/admin/admin-settings'

export default async function AdminSettingsPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  const { data: profile } = await getProfile(user.id)
  if (profile?.role !== 'admin') redirect('/patient/dashboard')

  return (
    <div className="mx-auto max-w-5xl space-y-8 pb-12">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Platform Settings</h1>
        <p className="text-sm font-medium text-muted-foreground">
          Manage verification, payment, and administrative alert policies.
        </p>
      </div>
      <AdminSettings />
    </div>
  )
}
