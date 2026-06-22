'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Search, Bell } from 'lucide-react'
import { createClient } from '@/lib/supabase'

export function AdminDashboardActions() {
    const router = useRouter()
    const [unreadCount, setUnreadCount] = useState(0)

    useEffect(() => {
        const supabase = createClient()
        const fetchCount = async () => {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) return
            const { count } = await supabase
                .from('notifications')
                .select('*', { count: 'exact', head: true })
                .eq('user_id', user.id)
                .eq('is_read', false)
            setUnreadCount(count || 0)
        }
        fetchCount()
    }, [])

    return (
        <>
            <Button
                variant="outline"
                size="icon"
                className="rounded-2xl border-slate-200 shadow-sm"
                onClick={() => router.push('/admin/users')}
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
                {unreadCount > 0 && (
                    <span className="absolute -top-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[8px] font-black text-white ring-2 ring-white">
                        {unreadCount > 99 ? '99+' : unreadCount}
                    </span>
                )}
            </div>
        </>
    )
}
