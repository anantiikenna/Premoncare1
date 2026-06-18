import { redirectToRolePath } from '@/lib/role-redirect'

export default async function AppointmentsAliasPage() {
  await redirectToRolePath('/appointments')
}
