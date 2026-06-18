import { PostDetail } from "@/components/forum/post-detail"

export default async function AdminPostDetailPage({
    params,
}: {
    params: Promise<{ id: string }>
}) {
    const { id } = await params
    return <PostDetail id={id} role="admin" />
}
