'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Upload, Loader2, CheckCircle2, AlertCircle } from 'lucide-react'
import { toast } from 'sonner'

interface VerificationBannerProps {
    status: 'unsubmitted' | 'pending' | 'approved' | 'rejected'
    userId: string
    onUpdate?: () => void
}

export function VerificationBanner({ status, userId, onUpdate }: VerificationBannerProps) {
    const [file, setFile] = useState<File | null>(null)
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const supabase = createClient()
    const router = useRouter()

    const handleUpload = async () => {
        if (!file) return
        setLoading(true)
        setError(null)

        try {
            const fileExt = file.name.split('.').pop()
            const fileName = `${userId}/${Math.random()}.${fileExt}`
            const { error: uploadError, data: uploadData } = await supabase.storage
                .from('patient-verifications')
                .upload(fileName, file)

            if (uploadError) throw uploadError

            const { error: updateError } = await supabase
                .from('profiles')
                .update({
                    verification_document_url: fileName,
                    verification_status: 'pending'
                })
                .eq('id', userId)

            if (updateError) throw updateError

            if (onUpdate) onUpdate()
            setFile(null)
            toast.success('Verification document uploaded successfully!')
            router.refresh()
        } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : 'Failed to upload verification document';
            setError(msg)
            toast.error(msg)
        } finally {
            setLoading(false)
        }
    }

    if (status === 'approved') return null

    return (
        <Card className="border-primary/20 bg-primary/5 mb-8">
            <CardHeader>
                <CardTitle className="flex items-center gap-2">
                    {status === 'unsubmitted' && <Upload className="h-5 w-5" />}
                    {status === 'pending' && <Loader2 className="h-5 w-5 animate-spin" />}
                    {status === 'rejected' && <AlertCircle className="h-5 w-5 text-destructive" />}
                    Identity Verification Required
                </CardTitle>
                <CardDescription>
                    {status === 'unsubmitted' && 'Please upload a valid National Identity or Driver License to unlock all features.'}
                    {status === 'pending' && 'Your document is being reviewed. Please wait for approval.'}
                    {status === 'rejected' && 'Your previous document was rejected. Please upload a valid document.'}
                </CardDescription>
            </CardHeader>
            <CardContent>
                {status !== 'pending' && (
                    <div className="flex flex-col gap-4">
                        <div
                            className="border-2 border-dashed rounded-lg p-6 text-center hover:bg-zinc-50 dark:hover:bg-zinc-900 transition-colors cursor-pointer relative"
                            onClick={() => document.getElementById('dash-file-upload')?.click()}
                        >
                            <div className="flex flex-col items-center">
                                <Upload className="h-8 w-8 text-muted-foreground mb-2" />
                                <span className="text-sm font-medium">
                                    {file ? file.name : 'Click to upload document'}
                                </span>
                            </div>
                            <input
                                id="dash-file-upload"
                                type="file"
                                className="hidden"
                                accept="image/*,.pdf"
                                onChange={(e) => setFile(e.target.files?.[0] || null)}
                            />
                        </div>
                        {error && <p className="text-sm text-destructive font-medium">{error}</p>}
                        <Button
                            onClick={handleUpload}
                            disabled={!file || loading}
                            className="w-full sm:w-auto"
                        >
                            {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            Submit for Verification
                        </Button>
                    </div>
                )}
                {status === 'pending' && (
                    <div className="flex items-center gap-2 text-primary font-medium">
                        <CheckCircle2 className="h-5 w-5" />
                        Awaiting Administrator Review
                    </div>
                )}
            </CardContent>
        </Card>
    )
}
