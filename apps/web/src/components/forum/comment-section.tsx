'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent } from '@/components/ui/card'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Loader2, MessageCircle, User } from 'lucide-react'
import { useRouter } from 'next/navigation'

interface Comment {
    id: string
    content: string
    created_at: string
    author: {
        full_name: string
        avatar_url?: string
    }
}

interface CommentListProps {
    postId: string
    initialComments: Comment[]
}

export function CommentSection({ postId, initialComments }: CommentListProps) {
    const [comments, setComments] = useState(initialComments)
    const [newComment, setNewComment] = useState('')
    const [submitting, setSubmitting] = useState(false)
    const supabase = createClient()
    const router = useRouter()

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        if (!newComment.trim()) return

        setSubmitting(true)
        try {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) {
                router.push('/login')
                return
            }

            const { data, error } = await supabase
                .from('forum_replies')
                .insert({
                    post_id: postId,
                    author_id: user.id,
                    content: newComment
                })
                .select(`
                    *,
                    author:profiles!forum_replies_author_id_fkey(full_name, avatar_url)
                `)
                .single()

            if (error) throw error
            if (data) setComments([...comments, data])
            setNewComment('')
        } catch (err) {
            console.error('Failed to add comment:', err)
        } finally {
            setSubmitting(false)
        }
    }

    return (
        <div className="space-y-8 mt-12 pt-8 border-t border-accent">
            <div className="flex items-center gap-2">
                <MessageCircle className="h-6 w-6 text-primary" />
                <h3 className="text-2xl font-bold tracking-tight">Discussion ({comments.length})</h3>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4 bg-muted/30 p-6 rounded-xl border border-primary/5">
                <Textarea
                    placeholder="Add to the conversation..."
                    value={newComment}
                    onChange={(e) => setNewComment(e.target.value)}
                    className="min-h-[100px] text-base leading-relaxed"
                />
                <div className="flex justify-end">
                    <Button type="submit" disabled={submitting || !newComment.trim()} className="px-6">
                        {submitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Post Comment
                    </Button>
                </div>
            </form>

            <div className="space-y-6">
                {comments.length === 0 ? (
                    <div className="text-center py-12 text-muted-foreground border-2 border-dashed rounded-xl">
                        No comments yet. Be the first to start the discussion!
                    </div>
                ) : (
                    comments.map((comment) => (
                        <div key={comment.id} className="flex gap-4 group">
                            <Avatar className="h-10 w-10 border border-primary/10">
                                <AvatarFallback className="bg-primary/5 text-primary">
                                    <User className="h-5 w-5" />
                                </AvatarFallback>
                            </Avatar>
                            <div className="flex-1 space-y-2">
                                <div className="flex items-baseline justify-between">
                                    <span className="font-bold text-sm">{comment.author.full_name}</span>
                                    <span className="text-xs text-muted-foreground">
                                        {new Date(comment.created_at).toLocaleDateString()}
                                    </span>
                                </div>
                                <Card className="border-primary/5 group-hover:border-primary/20 transition-all shadow-sm">
                                    <CardContent className="p-4 text-sm leading-relaxed whitespace-pre-wrap">
                                        {comment.content}
                                    </CardContent>
                                </Card>
                            </div>
                        </div>
                    ))
                )}
            </div>
        </div>
    )
}
