'use client'

import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { UserPlus, Download } from 'lucide-react'

export function AdminUsersActions() {
    return (
        <div className="flex items-center gap-3 relative z-10">
            <Button
                variant="outline"
                className="rounded-2xl h-12 px-6 font-bold shadow-sm hover:bg-slate-50 transition-all"
                onClick={() => toast.info('User data export is being developed. Use the browser\'s print function to save a report in the meantime.')}
            >
                <Download className="h-4 w-4 mr-2" />
                Export Data
            </Button>
            <Button
                className="rounded-2xl h-12 px-6 font-black bg-primary hover:bg-primary/90 shadow-lg shadow-primary/20 transition-all hover:scale-105 active:scale-95"
                onClick={() => toast.info('User invitations can be sent from the user management panel once accounts are set up.')}
            >
                <UserPlus className="h-4 w-4 mr-2" />
                Invite User
            </Button>
        </div>
    )
}
