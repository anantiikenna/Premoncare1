'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { createNotification } from '@/lib/queries-client'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Upload, Loader2, FileText, X, CheckCircle2, Shield } from 'lucide-react'
import { toast } from 'sonner'
import { Label } from '@/components/ui/label'
import { Input } from '@/components/ui/input'
import { getUserFacingError } from '@/lib/user-facing-errors'

export function TestResultUpload({ patientId }: { patientId: string }) {
    const [file, setFile] = useState<File | null>(null)
    const [title, setTitle] = useState('')
    const [loading, setLoading] = useState(false)
    const supabase = createClient()
    const router = useRouter()

    const handleUpload = async () => {
        if (!file || !title.trim()) {
            toast.error('Please provide a title and select a file')
            return
        }

        setLoading(true)
        try {
            const fileExt = file.name.split('.').pop()
            const fileName = `${patientId}/${Math.random()}.${fileExt}`
            
            // Upload to storage
            const { error: uploadError } = await supabase.storage
                .from('medical-documents')
                .upload(fileName, file)

            if (uploadError) throw uploadError

            // Insert into medical_documents table
            const { error: dbError } = await supabase
                .from('medical_documents')
                .insert({
                    patient_id: patientId,
                    title: title.trim(),
                    file_url: fileName,
                    file_type: fileExt,
                    status: 'active'
                })

            if (dbError) throw dbError

            // Notify patient (self)
            await createNotification({
                user_id: patientId,
                title: 'Document Uploaded',
                message: `"${title}" has been securely uploaded to your health archive.`,
                type: 'system',
                link: '/patient/records'
            })

            toast.success('Medical document uploaded successfully!')
            setFile(null)
            setTitle('')
            router.refresh()
        } catch (error: unknown) {
            console.error('Medical document upload failed', error)
            toast.error(getUserFacingError(error, 'We could not upload this document. Please try again.'))
        } finally {
            setLoading(false)
        }
    }

    return (
        <Card className="border-primary/20 shadow-lg shadow-primary/5 overflow-hidden">
            <CardHeader className="bg-primary/5 pb-6">
                <div className="flex items-center gap-2 text-primary font-bold mb-1">
                    <Shield className="h-4 w-4" />
                    Secure Medical Storage
                </div>
                <CardTitle className="text-2xl">Upload Test Results</CardTitle>
                <CardDescription>
                    Safely share your laboratory results or medical reports with your doctor.
                </CardDescription>
            </CardHeader>
            <CardContent className="pt-6 space-y-6">
                <div className="space-y-2">
                    <Label htmlFor="doc-title" className="text-base font-semibold">Document Title</Label>
                    <Input 
                        id="doc-title" 
                        placeholder="e.g. Blood Test Results - Jan 2024" 
                        value={title}
                        onChange={(e) => setTitle(e.target.value)}
                        className="h-12"
                    />
                </div>

                <div 
                    className="border-2 border-dashed rounded-2xl p-8 text-center hover:bg-muted/30 transition-all cursor-pointer group"
                    onClick={() => document.getElementById('test-file-upload')?.click()}
                >
                    {file ? (
                        <div className="flex items-center justify-center gap-3">
                            <div className="bg-primary/10 p-3 rounded-xl">
                                <FileText className="h-8 w-8 text-primary" />
                            </div>
                            <div className="text-left">
                                <p className="font-bold text-slate-900 truncate max-w-[200px]">{file.name}</p>
                                <p className="text-xs text-muted-foreground">{(file.size / 1024 / 1024).toFixed(2)} MB</p>
                            </div>
                            <Button 
                                variant="ghost" 
                                size="icon" 
                                className="h-8 w-8 rounded-full ml-4"
                                onClick={(e) => {
                                    e.stopPropagation()
                                    setFile(null)
                                }}
                            >
                                <X className="h-4 w-4" />
                            </Button>
                        </div>
                    ) : (
                        <div className="flex flex-col items-center">
                            <div className="bg-muted p-4 rounded-full mb-3 group-hover:bg-primary/10 group-hover:text-primary transition-colors">
                                <Upload className="h-10 w-10 text-muted-foreground group-hover:text-primary" />
                            </div>
                            <p className="font-bold text-slate-900">Click to upload document</p>
                            <p className="text-sm text-muted-foreground mt-1 text-center max-w-[200px]">
                                Supports PDF, JPG, or PNG (Max 5MB)
                            </p>
                        </div>
                    )}
                    <input 
                        id="test-file-upload"
                        type="file"
                        className="hidden"
                        accept=".pdf,image/*"
                        onChange={(e) => setFile(e.target.files?.[0] || null)}
                    />
                </div>
            </CardContent>
            <CardFooter className="bg-muted/10 border-t p-6">
                <Button 
                    className="w-full h-12 rounded-xl font-bold text-lg bg-primary hover:bg-primary/90 shadow-lg shadow-primary/20"
                    onClick={handleUpload}
                    disabled={loading || !file || !title.trim()}
                >
                    {loading ? <Loader2 className="h-5 w-5 animate-spin mr-2" /> : <Shield className="h-5 w-5 mr-2" />}
                    Confirm Secure Upload
                </Button>
            </CardFooter>
        </Card>
    )
}
