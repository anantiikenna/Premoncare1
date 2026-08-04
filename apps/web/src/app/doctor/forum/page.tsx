import { getForumPosts, getProfile } from '@/lib/queries'
import { createClient } from '@/lib/supabase-server'
import { ForumFeed } from '@/components/forum/forum-feed'

export default async function ForumFeedPage({
    searchParams,
}: {
    searchParams: Promise<{ category?: string }>
}) {
    const params = await searchParams
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()
    const { data: profile } = user ? await getProfile(user.id) : { data: null }
    const { data: posts } = await getForumPosts(params.category, 'approved')

    return <ForumFeed category={params.category} role="doctor" posts={posts ?? []} profile={profile} />
}
