'use client'

import { useState } from 'react'
import { Flag, Loader2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from "@/components/ui/dialog"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"

interface ReportPostButtonProps {
    postId: string
    title: string
}

export function ReportPostButton({ postId, title }: ReportPostButtonProps) {
    const [open, setOpen] = useState(false)
    const [reason, setReason] = useState('')
    const [submitting, setSubmitting] = useState(false)
    const supabase = createClient()

    const handleReport = async () => {
        if (!reason.trim()) {
            toast.error('Please provide a reason for the report')
            return
        }

        setSubmitting(true)
        try {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) throw new Error('Not authenticated')

            const { error } = await supabase
                .from('forum_reports')
                .insert({
                    post_id: postId,
                    reporter_id: user.id,
                    reason: reason.trim(),
                    status: 'pending'
                })

            if (error) throw error

            toast.success('Post reported successfully. Moderation will review it.')
            setOpen(false)
            setReason('')
        } catch (error: unknown) {
            toast.error('Failed to report: ' + (error instanceof Error ? error.message : String(error)))
        } finally {
            setSubmitting(false)
        }
    }

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger render={
                <Button variant="ghost" size="icon" className="rounded-full h-8 w-8 text-muted-foreground hover:text-destructive">
                    <Flag className="h-4 w-4" />
                </Button>
            } />
            <DialogContent>
                <DialogHeader>
                    <DialogTitle>Report Discussion</DialogTitle>
                    <DialogDescription>
                        Why are you reporting "{title}"? Please clarify how it violates our community guidelines.
                    </DialogDescription>
                </DialogHeader>
                <div className="space-y-4 py-4">
                    <div className="space-y-2">
                        <Label htmlFor="reason">Reason for report</Label>
                        <Textarea 
                            id="reason" 
                            placeholder="e.g. Inappropriate content, medical misinformation, spam..." 
                            value={reason}
                            onChange={(e) => setReason(e.target.value)}
                            className="min-h-[100px]"
                        />
                    </div>
                </div>
                <DialogFooter>
                    <Button variant="ghost" onClick={() => setOpen(false)} disabled={submitting}>Cancel</Button>
                    <Button variant="destructive" onClick={handleReport} disabled={submitting}>
                        {submitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Submit Report
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    )
}
