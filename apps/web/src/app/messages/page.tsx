import { redirectToRolePath } from '@/lib/role-redirect'

export default async function MessagesAliasPage() {
  await redirectToRolePath('/messages')
}
