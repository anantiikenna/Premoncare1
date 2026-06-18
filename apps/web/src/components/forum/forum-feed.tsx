import Link from 'next/link'
import { getForumPosts, getProfile } from '@/lib/queries'
import { PostCard } from '@/components/forum/post-card'
import { Button } from '@/components/ui/button'
import { Plus, Search } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { createClient } from '@/lib/supabase-server'
import { GuidelinesModal } from '@/components/forum/guidelines-modal'

interface ForumFeedProps {
    category?: string
    role: 'patient' | 'doctor' | 'admin'
}

export async function ForumFeed({ category, role }: ForumFeedProps) {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()
    const { data: profile } = user ? await getProfile(user.id) : { data: null }
    
    // For admins, show ALL posts. For others, only approved posts.
    const fetchStatus = role === 'admin' ? 'all' : 'approved'
    const { data: posts } = await getForumPosts(category, fetchStatus)

    const categories = [
        'All',
        'General Health',
        'Nutrition',
        'Mental Health',
        'Chronic Conditions',
        'Recovery Stories',
        'Medical Advice (General)',
        'Community Events'
    ]

    return (
        <div className="space-y-8 max-w-6xl mx-auto animate-in-fade">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-4xl font-extrabold tracking-tight">Community Forum</h1>
                    <p className="text-muted-foreground mt-2 text-lg">Connect, share, and learn from others in the community.</p>
                </div>
                {profile && <GuidelinesModal profile={profile} />}
                <Link href={`/${role}/forum/new`}>
                    <Button className="px-6 py-6 text-lg shadow-lg shadow-primary/20">
                        <Plus className="mr-2 h-5 w-5" />
                        New Discussion
                    </Button>
                </Link>
            </div>

            <div className="flex flex-col md:flex-row gap-4 items-center bg-card p-4 rounded-xl border shadow-sm">
                <div className="relative flex-1 w-full">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input placeholder="Search discussions..." className="pl-10 h-12 bg-background/50" />
                </div>
                <div className="flex gap-2 overflow-x-auto pb-1 w-full md:w-auto">
                    {categories.map((cat) => (
                        <Link
                            key={cat}
                            href={cat === 'All' ? `/${role}/forum` : `/${role}/forum?category=${cat}`}
                        >
                            <Button
                                variant={category === cat || (!category && cat === 'All') ? 'default' : 'outline'}
                                size="sm"
                                className="whitespace-nowrap"
                            >
                                {cat}
                            </Button>
                        </Link>
                    ))}
                </div>
            </div>

            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                {posts?.length === 0 ? (
                    <div className="col-span-full py-20 text-center space-y-4 bg-muted/20 rounded-2xl border-2 border-dashed">
                        <div className="bg-background w-16 h-16 rounded-full flex items-center justify-center mx-auto shadow-sm">
                            <Search className="h-8 w-8 text-muted-foreground" />
                        </div>
                        <div className="space-y-2">
                            <h3 className="text-xl font-bold">No posts found</h3>
                            <p className="text-muted-foreground max-w-xs mx-auto">Try adjusting your filters or be the first to start a conversation in this category.</p>
                        </div>
                    </div>
                ) : (
                    posts?.map((post) => (
                        <PostCard key={post.id} post={post} role={role} />
                    ))
                )}
            </div>
        </div>
    )
}
