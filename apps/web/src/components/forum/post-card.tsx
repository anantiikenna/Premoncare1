import Link from 'next/link'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { MessageSquare, Calendar, User, ShieldAlert } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { DeletePostButton } from './delete-post-button'

interface PostCardProps {
    post: {
        id: string
        title: string
        content: string
        category: string | { id: string; name: string; icon_name?: string }
        created_at: string
        author: {
            full_name: string
        }
    }
    role: string
}

export function PostCard({ post, role }: PostCardProps) {
    const categoryName = typeof post.category === 'object' && post.category !== null
        ? post.category.name
        : (post.category || 'Uncategorized')

    return (
        <div className="relative group">
            <Link href={`/${role}/forum/${post.id}`}>
                <Card className="hover:border-primary/50 transition-colors cursor-pointer overflow-hidden h-full flex flex-col">
                    <CardHeader className="pb-3">
                        <div className="flex justify-between items-start gap-4">
                            <Badge variant="secondary" className="mb-2 shrink-0">{categoryName}</Badge>
                            <div className="flex items-center gap-1 text-xs text-muted-foreground whitespace-nowrap">
                                <Calendar className="h-3 w-3" />
                                {new Date(post.created_at).toLocaleDateString()}
                            </div>
                        </div>
                        <CardTitle className="text-xl line-clamp-2 leading-tight">{post.title}</CardTitle>
                    </CardHeader>
                    <CardContent className="flex-1 pb-4">
                        <p className="text-muted-foreground text-sm line-clamp-3 leading-relaxed">
                            {post.content}
                        </p>
                    </CardContent>
                    <CardFooter className="pt-0 flex items-center justify-between border-t bg-accent/5 py-4 px-6 mt-auto">
                        <div className="flex items-center gap-2 text-sm font-medium">
                            <div className="bg-primary/10 p-1 rounded-full">
                                <User className="h-3 w-3 text-primary" />
                            </div>
                            {post.author.full_name}
                        </div>
                        <div className="flex items-center gap-1 text-xs text-muted-foreground group-hover:text-primary transition-colors">
                            <MessageSquare className="h-4 w-4" />
                            Read More
                        </div>
                    </CardFooter>
                </Card>
            </Link>
            {role === 'admin' && (
                <div className="absolute top-2 right-2 flex items-center gap-1">
                    <div className="hidden group-hover:block transition-all animate-in fade-in slide-in-from-right-1">
                        <DeletePostButton postId={post.id} />
                    </div>
                </div>
            )}
        </div>
    )
}
