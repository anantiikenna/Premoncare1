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
                onClick={() => toast.info('Doctor data export is being developed. Use the browser\'s print function to save a report in the meantime.')}
            >
                Export List
            </Button>
            <Button
                className="rounded-full shadow-lg shadow-primary/20 bg-primary hover:bg-primary/90"
                onClick={() => toast.info('Doctor invitations can be sent from the verification panel once credentials are submitted.')}
            >
                <Plus className="h-4 w-4 mr-2" />
                Invite Doctor
            </Button>
        </div>
    )
}
