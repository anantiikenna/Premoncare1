'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { Loader2, CheckCircle, XCircle, Flag, MessageSquare, User, Calendar, ExternalLink } from 'lucide-react'
import { createNotification } from '@/lib/queries-client'
import Link from 'next/link'

export function ModerationDashboard() {
    const [loading, setLoading] = useState(true)
    const [pendingPosts, setPendingPosts] = useState<any[]>([])
    const [reports, setReports] = useState<any[]>([])
    const [processingId, setProcessingId] = useState<string | null>(null)
    const supabase = createClient()

    const fetchData = async () => {
        setLoading(true)
        try {
            // Fetch pending posts
            const { data: posts } = await supabase
                .from('forum_posts')
                .select('*, author:profiles!forum_posts_author_id_fkey(full_name)')
                .eq('status', 'pending')
                .order('created_at', { ascending: false })

            // Fetch reports
            const { data: reportData } = await supabase
                .from('forum_reports')
                .select('*, post:forum_posts(*, author:profiles!forum_posts_author_id_fkey(full_name)), reporter:profiles!reporter_id(full_name)')
                .eq('status', 'pending')
                .order('created_at', { ascending: false })

            setPendingPosts(posts || [])
            setReports(reportData || [])
        } catch (error) {
            console.error('Error fetching moderation data:', error)
        } finally {
            setLoading(false)
        }
    }

    useEffect(() => {
        fetchData()
    }, [])

    const handleAction = async (postId: string, action: 'approved' | 'rejected') => {
        setProcessingId(postId)
        try {
            // Update post status
            const { error: postError } = await supabase
                .from('forum_posts')
                .update({ status: action })
                .eq('id', postId)

            if (postError) throw postError

            // Send notification to author
            const { data: post } = await supabase.from('forum_posts').select('author_id, title').eq('id', postId).single()
            if (post) {
                await createNotification({
                    user_id: post.author_id,
                    title: `Post ${action === 'approved' ? 'Approved' : 'Rejected'}`,
                    message: `Your discussion "${post.title}" has been ${action} by moderators.`,
                    type: 'other', // Forum categorized as other/system
                    link: action === 'approved' ? `/patient/forum/${postId}` : '/patient/forum'
                })
            }

            toast.success(`Post ${action} successfully`)
            fetchData()
        } catch (error: unknown) {
            toast.error('Failed to update: ' + (error instanceof Error ? error.message : String(error)))
        } finally {
            setProcessingId(null)
        }
    }

    const resolveReport = async (reportId: string) => {
        setProcessingId(reportId)
        try {
            const { error } = await supabase
                .from('forum_reports')
                .update({ status: 'action_taken', resolved_at: new Date().toISOString(), resolved_by: null })
                .eq('id', reportId)

            if (error) throw error
            toast.success('Report marked as resolved')
            fetchData()
        } catch (error: unknown) {
            toast.error('Failed to resolve report: ' + (error instanceof Error ? error.message : String(error)))
        } finally {
            setProcessingId(null)
        }
    }

    if (loading) return <div className="flex justify-center p-12"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>

    return (
        <div className="space-y-8">
            <div className="flex flex-col gap-2">
                <h1 className="text-3xl font-bold tracking-tight">Community Moderation</h1>
                <p className="text-muted-foreground">Review pending discussions and member reports.</p>
            </div>

            <Tabs defaultValue="pending" className="w-full">
                <TabsList className="grid w-full max-w-md grid-cols-2">
                    <TabsTrigger value="pending" className="flex gap-2">
                        Pending Posts
                        {pendingPosts.length > 0 && <Badge variant="secondary" className="ml-1 bg-primary/10 text-primary">{pendingPosts.length}</Badge>}
                    </TabsTrigger>
                    <TabsTrigger value="reports" className="flex gap-2">
                        Reports
                        {reports.length > 0 && <Badge variant="destructive" className="ml-1">{reports.length}</Badge>}
                    </TabsTrigger>
                </TabsList>

                <TabsContent value="pending" className="mt-6">
                    <div className="grid gap-6">
                        {pendingPosts.length === 0 ? (
                            <Card className="border-dashed flex items-center justify-center h-48 text-muted-foreground">
                                <div className="text-center">
                                    <CheckCircle className="h-8 w-8 mx-auto mb-2 opacity-20" />
                                    <p>Queue is clear! No pending posts.</p>
                                </div>
                            </Card>
                        ) : (
                            pendingPosts.map((post) => (
                                <Card key={post.id} className="overflow-hidden border-primary/10 hover:border-primary/30 transition-all">
                                    <CardHeader className="bg-muted/30 pb-4">
                                        <div className="flex justify-between items-start">
                                            <div className="space-y-1">
                                                <div className="flex items-center gap-2">
                                                    <Badge variant="outline" className="bg-background">{post.category}</Badge>
                                                    <span className="text-xs text-muted-foreground flex items-center gap-1">
                                                        <Calendar className="h-3 w-3" />
                                                        {new Date(post.created_at).toLocaleString()}
                                                    </span>
                                                </div>
                                                <CardTitle className="text-xl pt-1">{post.title}</CardTitle>
                                            </div>
                                            <div className="flex gap-2">
                                                <Button 
                                                    size="sm" 
                                                    className="bg-green-600 hover:bg-green-700 text-white"
                                                    onClick={() => handleAction(post.id, 'approved')}
                                                    disabled={processingId === post.id}
                                                >
                                                    <CheckCircle className="h-4 w-4 mr-1" />
                                                    Approve
                                                </Button>
                                                <Button 
                                                    size="sm" 
                                                    variant="destructive"
                                                    onClick={() => handleAction(post.id, 'rejected')}
                                                    disabled={processingId === post.id}
                                                >
                                                    <XCircle className="h-4 w-4 mr-1" />
                                                    Reject
                                                </Button>
                                            </div>
                                        </div>
                                    </CardHeader>
                                    <CardContent className="pt-6">
                                        <div className="flex items-center gap-2 mb-4 text-sm font-medium">
                                            <User className="h-4 w-4 text-primary" />
                                            Author: {post.author.full_name}
                                        </div>
                                        <p className="text-slate-600 line-clamp-3 whitespace-pre-wrap italic bg-muted/50 p-4 rounded-lg">
                                            "{post.content}"
                                        </p>
                                    </CardContent>
                                </Card>
                            ))
                        )}
                    </div>
                </TabsContent>

                <TabsContent value="reports" className="mt-6">
                    <div className="grid gap-6">
                        {reports.length === 0 ? (
                            <Card className="border-dashed flex items-center justify-center h-48 text-muted-foreground">
                                <div className="text-center">
                                    <Flag className="h-8 w-8 mx-auto mb-2 opacity-20" />
                                    <p>No active reports to review.</p>
                                </div>
                            </Card>
                        ) : (
                            reports.map((report) => (
                                <Card key={report.id} className="border-red-100 shadow-sm">
                                    <CardHeader className="bg-red-50/50 pb-4">
                                        <div className="flex justify-between items-center">
                                            <div className="flex items-center gap-2">
                                                <Flag className="h-4 w-4 text-red-600" />
                                                <span className="font-bold text-red-900">New Report Filing</span>
                                                <Badge variant="outline" className="bg-red-100 text-red-700 border-red-200">Pending Review</Badge>
                                            </div>
                                            <Button 
                                                variant="outline" 
                                                size="sm"
                                                onClick={() => resolveReport(report.id)}
                                                disabled={processingId === report.id}
                                            >
                                                Mark Resolved
                                            </Button>
                                        </div>
                                    </CardHeader>
                                    <CardContent className="pt-6 space-y-4">
                                        <div className="grid grid-cols-2 gap-4 text-sm">
                                            <div className="space-y-1">
                                                <p className="text-muted-foreground font-medium">Reporter</p>
                                                <p className="font-semibold">{report.reporter.full_name}</p>
                                            </div>
                                            <div className="space-y-1">
                                                <p className="text-muted-foreground font-medium">Report Reason</p>
                                                <p className="font-semibold text-red-700">{report.reason}</p>
                                            </div>
                                        </div>

                                        <div className="p-4 bg-muted rounded-xl border">
                                            <div className="flex justify-between items-start mb-2">
                                                <p className="text-xs uppercase font-bold tracking-wider text-muted-foreground">Reported Post Content</p>
                                                <Link href={`/admin/forum/${report.post_id}`} className="text-xs text-primary flex items-center gap-1 hover:underline">
                                                    <ExternalLink className="h-3 w-3" /> View Detail
                                                </Link>
                                            </div>
                                            <h4 className="font-bold mb-2">{report.post.title}</h4>
                                            <p className="text-sm line-clamp-2 text-slate-600 italic">"{report.post.content}"</p>
                                            <p className="text-xs mt-3 text-muted-foreground">Author: {report.post.author.full_name}</p>
                                        </div>
                                    </CardContent>
                                </Card>
                            ))
                        )}
                    </div>
                </TabsContent>
            </Tabs>
        </div>
    )
}
