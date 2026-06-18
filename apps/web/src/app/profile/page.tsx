import { redirectToRolePath } from '@/lib/role-redirect'

export default async function ProfileAliasPage() {
  await redirectToRolePath('/profile')
}
