'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Loader2, Send } from 'lucide-react'

const categories = [
    'General Health',
    'Nutrition',
    'Mental Health',
    'Chronic Conditions',
    'Recovery Stories',
    'Medical Advice (General)',
    'Community Events'
]

export function PostForm({ role }: { role: string }) {
    const [submitting, setSubmitting] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [categoryList, setCategoryList] = useState<Array<{id: string, name: string}>>([])
    const router = useRouter()
    const supabase = createClient()

    const [formData, setFormData] = useState({
        title: '',
        category: '',
        content: ''
    })

    // Fetch categories from database on mount
    useState(() => {
        supabase.from('forum_categories').select('id, name').then(({ data }) => {
            if (data && data.length > 0) setCategoryList(data)
        })
    })

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setSubmitting(true)
        setError(null)

        try {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) throw new Error('Not authenticated')

            // Look up category_id from the selected category name
            let categoryId: string | null = null
            if (categoryList.length > 0) {
                const matched = categoryList.find(c => c.name === formData.category)
                categoryId = matched?.id ?? null
            } else {
                // Fallback: try to find by name directly
                const { data: cat } = await supabase
                    .from('forum_categories')
                    .select('id')
                    .eq('name', formData.category)
                    .single()
                categoryId = cat?.id ?? null
            }

            const { error: postError } = await supabase
                .from('forum_posts')
                .insert({
                    author_id: user.id,
                    title: formData.title,
                    category_id: categoryId,
                    content: formData.content,
                    status: 'pending'
                })

            if (postError) throw postError

            router.push(`/${role}/forum`)
            router.refresh()
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : 'Failed to create post')
            setSubmitting(false)
        }
    }

    return (
        <Card className="w-full max-w-2xl mx-auto shadow-lg border-primary/10">
            <CardHeader className="bg-primary/5 border-b">
                <CardTitle className="text-2xl">Create New Post</CardTitle>
                <CardDescription>Share your thoughts, questions, or experiences with the community.</CardDescription>
            </CardHeader>
            <form onSubmit={handleSubmit}>
                <CardContent className="space-y-6 pt-6">
                    <div className="space-y-2">
                        <Label htmlFor="title" className="text-base font-semibold">Title</Label>
                        <Input
                            id="title"
                            placeholder="What's on your mind?"
                            value={formData.title}
                            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                            required
                            className="text-lg py-6"
                        />
                    </div>
                    <div className="space-y-2">
                        <Label className="text-base font-semibold">Category</Label>
                        <Select
                            value={formData.category}
                            onValueChange={(val) => setFormData({ ...formData, category: val })}
                            required
                        >
                            <SelectTrigger className="py-6">
                                <SelectValue placeholder="Select a category" />
                            </SelectTrigger>
                            <SelectContent>
                                {categories.map((cat) => (
                                    <SelectItem key={cat} value={cat}>{cat}</SelectItem>
                                ))}
                            </SelectContent>
                        </Select>
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="content" className="text-base font-semibold">Content</Label>
                        <Textarea
                            id="content"
                            placeholder="Write your post here..."
                            value={formData.content}
                            onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                            className="min-h-[200px] text-base leading-relaxed p-4"
                            required
                        />
                    </div>
                    {error && (
                        <div className="p-4 text-sm bg-destructive/10 text-destructive rounded-lg border border-destructive/20 font-medium">
                            {error}
                        </div>
                    )}
                </CardContent>
                <CardFooter className="flex justify-between border-t bg-muted/30 p-6 mt-4">
                    <Button variant="ghost" type="button" onClick={() => router.back()}>
                        Cancel
                    </Button>
                    <Button type="submit" className="px-8 py-6 text-lg" disabled={submitting}>
                        {submitting && <Loader2 className="mr-2 h-5 w-5 animate-spin" />}
                        <Send className="mr-2 h-5 w-5" />
                        Publish Post
                    </Button>
                </CardFooter>
            </form>
        </Card>
    )
}
