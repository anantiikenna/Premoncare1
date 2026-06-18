import { ForumFeed } from "@/components/forum/forum-feed"

export default async function ForumFeedPage({
    searchParams,
}: {
    searchParams: Promise<{ category?: string }>
}) {
    const params = await searchParams
    return <ForumFeed category={params.category} role="doctor" />
}
