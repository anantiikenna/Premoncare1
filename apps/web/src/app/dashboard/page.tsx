import { redirectToRolePath } from '@/lib/role-redirect'

export default async function DashboardAliasPage() {
  await redirectToRolePath('/dashboard')
}
