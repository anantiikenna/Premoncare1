'use client'

import { Share2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { toast } from 'sonner'

interface ShareButtonProps {
    title: string
}

export function ShareButton({ title }: ShareButtonProps) {
    const handleShare = () => {
        const url = window.location.href
        if (navigator.share) {
            navigator.share({
                title: title,
                url: url
            }).catch(() => {
                navigator.clipboard.writeText(url)
                toast.success('Link copied to clipboard')
            })
        } else {
            navigator.clipboard.writeText(url)
            toast.success('Link copied to clipboard')
        }
    }

    return (
        <Button 
            variant="ghost" 
            size="icon" 
            className="rounded-full h-8 w-8"
            onClick={handleShare}
        >
            <Share2 className="h-4 w-4" />
        </Button>
    )
}
