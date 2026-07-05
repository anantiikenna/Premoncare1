'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase'
import { Loader2, Camera, Upload } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { getUserFacingError } from '@/lib/user-facing-errors'

interface AvatarUploadProps {
    userId: string
    currentAvatarUrl?: string
    onUploadSuccess: (url: string) => void
}

export function AvatarUpload({ userId, currentAvatarUrl, onUploadSuccess }: AvatarUploadProps) {
    const [uploading, setUploading] = useState(false)
    const supabase = createClient()

    const handleUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
        try {
            setUploading(true)

            if (!event.target.files || event.target.files.length === 0) {
                throw new Error('You must select an image to upload.')
            }

            const file = event.target.files[0]
            const fileExt = file.name.split('.').pop()
            const filePath = `${userId}/avatar_${Date.now()}.${fileExt}`

            const { error: uploadError } = await supabase.storage
                .from('avatars')
                .upload(filePath, file, { upsert: true })

            if (uploadError) {
                throw uploadError
            }

            const { data } = supabase.storage.from('avatars').getPublicUrl(filePath)
            const cacheBustedUrl = `${data.publicUrl}?t=${Date.now()}`
            onUploadSuccess(cacheBustedUrl)
            toast.success('Profile photo updated!')
        } catch (error: unknown) {
            console.error('Avatar upload failed', error)
            toast.error(getUserFacingError(error, 'We could not upload your profile photo. Please try again.'))
        } finally {
            setUploading(false)
        }
    }

    return (
        <div className="flex flex-col items-center gap-4">
            <div className="relative group w-32 h-32 rounded-full border-4 border-background shadow-lg overflow-hidden bg-muted flex items-center justify-center">
                {currentAvatarUrl ? (
                    <img 
                        src={currentAvatarUrl.includes('?') ? currentAvatarUrl : `${currentAvatarUrl}?t=${Date.now()}`} 
                        alt="Avatar" 
                        className="w-full h-full object-cover object-center" 
                    />
                ) : (
                    <Upload className="w-10 h-10 text-muted-foreground/50" />
                )}
                
                <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                    {uploading ? (
                        <Loader2 className="h-6 w-6 text-white animate-spin" />
                    ) : (
                        <Camera className="h-8 w-8 text-white" />
                    )}
                </div>
                
                <input
                    type="file"
                    className="absolute inset-0 opacity-0 cursor-pointer w-full h-full"
                    accept="image/*"
                    onChange={handleUpload}
                    disabled={uploading}
                />
            </div>
            {uploading && <p className="text-xs text-muted-foreground animate-pulse">Uploading...</p>}
        </div>
    )
}
