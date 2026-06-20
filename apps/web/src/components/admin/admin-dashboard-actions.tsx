'use client'

import { useRouter } from 'next/navigation'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Search, Bell } from 'lucide-react'

export function AdminDashboardActions() {
    const router = useRouter()

    return (
        <>
            <Button
                variant="outline"
                size="icon"
                className="rounded-2xl border-slate-200 shadow-sm"
                onClick={() => toast.info('Dashboard-wide search is being developed. Use the sidebar navigation to access specific sections.')}
            >
                <Search className="h-4 w-4 text-slate-500" />
            </Button>
            <div className="relative">
                <Button
                    variant="outline"
                    size="icon"
                    className="rounded-2xl border-slate-200 shadow-sm"
                    onClick={() => router.push('/admin/notifications')}
                >
                    <Bell className="h-4 w-4 text-slate-500" />
                </Button>
                <span className="absolute -top-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[8px] font-black text-white ring-2 ring-white">
                    0
                </span>
            </div>
        </>
    )
}
