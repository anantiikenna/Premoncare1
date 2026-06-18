'use client'

import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Plus } from 'lucide-react'

export function AdminDoctorsActions() {
    return (
        <div className="flex items-center gap-3">
            <Button
                variant="outline"
                className="rounded-full shadow-sm"
                onClick={() => toast.info('Export coming soon')}
            >
                Export List
            </Button>
            <Button
                className="rounded-full shadow-lg shadow-primary/20 bg-primary hover:bg-primary/90"
                onClick={() => toast.info('Invite feature coming soon')}
            >
                <Plus className="h-4 w-4 mr-2" />
                Invite Doctor
            </Button>
        </div>
    )
}
