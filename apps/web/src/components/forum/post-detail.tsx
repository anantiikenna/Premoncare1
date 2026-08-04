import { getForumPostById, getCommentsByPostId } from '@/lib/queries'
import { CommentSection } from '@/components/forum/comment-section'
import { Badge } from '@/components/ui/badge'
import { Calendar, User, ArrowLeft, Share2, Flag, ShieldAlert } from 'lucide-react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { notFound } from 'next/navigation'
import { DeletePostButton } from './delete-post-button'
import { ShareButton } from './share-button'
import { ReportPostButton } from './report-post-button'

interface PostDetailProps {
    id: string
    role: 'patient' | 'doctor' | 'admin'
}

export async function PostDetail({ id, role }: PostDetailProps) {
    const { data: post } = await getForumPostById(id)
    const { data: comments } = await getCommentsByPostId(id)

    if (!post) notFound()

    const categoryName = post.category && typeof post.category === 'object'
        ? (post.category as { name: string }).name
        : (post.category || 'Uncategorized')
    const backHref = `/${role}/forum`

    return (
        <div className="max-w-4xl mx-auto py-8 lg:py-12 px-4">
            <Link href={backHref} className="inline-flex items-center text-sm text-muted-foreground hover:text-primary transition-colors mb-8 group">
                <ArrowLeft className="mr-2 h-4 w-4 transition-transform group-hover:-translate-x-1" />
                Back to Feed
            </Link>

            <article className="space-y-8 animate-in-fade">
                <header className="space-y-6">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                            <Badge variant="secondary" className="px-3 py-1 text-sm font-medium">{categoryName}</Badge>
                            {role === 'admin' && (
                                <Badge className="bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20 gap-1 px-3 py-1">
                                    <ShieldAlert className="h-3 w-3" />
                                    Moderator View
                                </Badge>
                            )}
                        </div>
                        <div className="flex items-center gap-2">
                            {role === 'admin' ? (
                                <DeletePostButton postId={id} variant="default" />
                            ) : (
                                <>
                                    <ShareButton title={post.title} />
                                    <ReportPostButton postId={id} title={post.title} />
                                </>
                            )}
                        </div>
                    </div>

                    <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight leading-tight">{post.title}</h1>

                    <div className="flex items-center gap-6 text-sm text-muted-foreground bg-muted/30 p-4 rounded-xl border border-primary/5">
                        <div className="flex items-center gap-2 font-medium text-foreground">
                            <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center">
                                <User className="h-4 w-4 text-primary" />
                            </div>
                            {post.author.full_name}
                        </div>
                        <div className="flex items-center gap-2">
                            <Calendar className="h-4 w-4" />
                            {new Date(post.created_at).toLocaleDateString(undefined, { dateStyle: 'long' })}
                        </div>
                    </div>
                </header>

                <div className="prose prose-lg dark:prose-invert max-w-none leading-relaxed">
                    <p className="whitespace-pre-wrap text-foreground/90 text-xl font-light">
                        {post.content}
                    </p>
                </div>

                <CommentSection postId={id} initialComments={comments || []} />
            </article>
        </div>
    )
}
