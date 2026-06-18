'use client'

import { useState, useEffect } from 'react'
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog"
import { Button } from '@/components/ui/button'
import { ShieldCheck, AlertCircle, MessageCircle, HeartPulse } from 'lucide-react'
import { createClient } from '@/lib/supabase'
import { updateProfile } from '@/lib/queries-client'

export function GuidelinesModal({ profile }: { profile: any }) {
    const [open, setOpen] = useState(false)
    const [loading, setLoading] = useState(false)

    useEffect(() => {
        if (profile && !profile.accepted_guidelines) {
            setOpen(true)
        }
    }, [profile])

    const handleAccept = async () => {
        setLoading(true)
        try {
            await updateProfile(profile.id, { accepted_guidelines: true } as any)
            setOpen(false)
        } catch (error) {
            console.error('Failed to accept guidelines:', error)
        } finally {
            setLoading(false)
        }
    }

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogContent className="sm:max-w-md md:max-w-lg lg:max-w-xl p-0 overflow-hidden border-none shadow-2xl">
                <div className="bg-primary p-6 text-white flex items-center gap-4">
                    <div className="bg-white/20 p-3 rounded-2xl">
                        <ShieldCheck className="h-8 w-8" />
                    </div>
                    <div>
                        <DialogTitle className="text-2xl font-bold">Community Guidelines</DialogTitle>
                        <DialogDescription className="text-primary-foreground/80 text-sm">
                            Please review our rules before joining the discussion.
                        </DialogDescription>
                    </div>
                </div>

                <div className="p-8 space-y-6 max-h-[60vh] overflow-y-auto">
                    <div className="flex gap-4">
                        <div className="bg-amber-100 p-2 h-fit rounded-lg shrink-0">
                            <HeartPulse className="h-5 w-5 text-amber-600" />
                        </div>
                        <div>
                            <h4 className="font-bold text-slate-900 mb-1">Medical Disclaimer</h4>
                            <p className="text-sm text-slate-600 leading-relaxed">
                                Information shared here is for educational purposes only and should not replace professional medical advice, diagnosis, or treatment. Always seek the advice of your physician.
                            </p>
                        </div>
                    </div>

                    <div className="flex gap-4">
                        <div className="bg-blue-100 p-2 h-fit rounded-lg shrink-0">
                            <MessageCircle className="h-5 w-5 text-blue-600" />
                        </div>
                        <div>
                            <h4 className="font-bold text-slate-900 mb-1">Be Respectful</h4>
                            <p className="text-sm text-slate-600 leading-relaxed">
                                We are a supportive community. Harassment, hate speech, or bullying of any kind will not be tolerated and may lead to a permanent ban.
                            </p>
                        </div>
                    </div>

                    <div className="flex gap-4">
                        <div className="bg-red-100 p-2 h-fit rounded-lg shrink-0">
                            <AlertCircle className="h-5 w-5 text-red-600" />
                        </div>
                        <div>
                            <h4 className="font-bold text-slate-900 mb-1">No Misinformation</h4>
                            <p className="text-sm text-slate-600 leading-relaxed">
                                Sharing false medical claims or unverified treatments is prohibited. Posts containing misinformation will be removed by moderators.
                            </p>
                        </div>
                    </div>

                    <div className="bg-muted/50 p-4 rounded-xl border border-dashed border-muted-foreground/20 italic text-xs text-muted-foreground">
                        By clicking "I Agree", you acknowledge that your posts will be reviewed by administrators before being visible to the community.
                    </div>
                </div>

                <DialogFooter className="p-6 bg-slate-50 border-t items-center sm:justify-between gap-4">
                    <p className="text-xs text-slate-500 max-w-[200px]">
                        Last updated: March 2026
                    </p>
                    <Button 
                        onClick={handleAccept} 
                        className="w-full sm:w-auto px-10 rounded-full font-bold shadow-lg shadow-primary/20"
                        disabled={loading}
                    >
                        {loading ? 'Processing...' : 'I Agree & Continue'}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    )
}
