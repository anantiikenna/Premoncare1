import { PostDetail } from "@/components/forum/post-detail"

export default async function PostDetailPage({
    params,
}: {
    params: Promise<{ id: string }>
}) {
    const { id } = await params
    return <PostDetail id={id} role="doctor" />
}
