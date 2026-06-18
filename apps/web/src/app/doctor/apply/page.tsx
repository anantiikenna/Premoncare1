import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase-server'
import { getProfile } from '@/lib/queries'
import { ApplyPractitioner } from '@/components/doctor/apply-practitioner'

export default async function DoctorApplyPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  const { data: profile } = await getProfile(user.id)

  return (
    <div className="mx-auto max-w-4xl space-y-8 pb-12">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Practitioner Verification Wizard</h1>
        <p className="text-sm font-medium text-muted-foreground">
          Submit your professional details and credentials for admin review.
        </p>
      </div>
      <ApplyPractitioner profile={profile} />
    </div>
  )
}
