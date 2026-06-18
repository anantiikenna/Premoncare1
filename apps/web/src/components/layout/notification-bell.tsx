'use client'

import { useState, useEffect } from 'react'
import { Bell, Check, Trash2, Loader2, Info, Calendar, CreditCard, Pill, MessageSquare } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
    DropdownMenuSeparator
} from '@/components/ui/dropdown-menu'
import { Badge } from '@/components/ui/badge'
import { getUserNotifications, markNotificationAsRead, markAllNotificationsAsRead } from '@/lib/queries-client'
import { createClient } from '@/lib/supabase'
import { formatDistanceToNow } from 'date-fns'
import Link from 'next/link'

export function NotificationBell({ userId }: { userId: string }) {
    const [notifications, setNotifications] = useState<any[]>([])
    const [loading, setLoading] = useState(true)
    const [unreadCount, setUnreadCount] = useState(0)
    const supabase = createClient()

    const fetchNotifications = async () => {
        const { data } = await getUserNotifications(userId)
        if (data) {
            setNotifications(data)
            setUnreadCount(data.filter(n => !n.is_read).length)
        }
        setLoading(false)
    }

    useEffect(() => {
        fetchNotifications()

        // Real-time subscription
        const channel = supabase
            .channel(`notifications-${userId}`)
            .on(
                'postgres_changes',
                {
                    event: 'INSERT',
                    schema: 'public',
                    table: 'notifications',
                    filter: `user_id=eq.${userId}`
                },
                (payload) => {
                    setNotifications(prev => [payload.new, ...prev])
                    setUnreadCount(prev => prev + 1)
                }
            )
            .subscribe()

        return () => {
            supabase.removeChannel(channel)
        }
    }, [userId])

    const handleMarkAsRead = async (id: string) => {
        await markNotificationAsRead(id)
        setNotifications(prev => prev.map(n => n.id === id ? { ...n, is_read: true } : n))
        setUnreadCount(prev => Math.max(0, prev - 1))
    }

    const handleMarkAllRead = async () => {
        await markAllNotificationsAsRead(userId)
        setNotifications(prev => prev.map(n => ({ ...n, is_read: true })))
        setUnreadCount(0)
    }

    const getIcon = (type: string) => {
        switch (type) {
            case 'appointment': return <Calendar className="h-4 w-4 text-primary" />
            case 'payment': return <CreditCard className="h-4 w-4 text-green-500" />
            case 'prescription': return <Pill className="h-4 w-4 text-amber-500" />
            case 'message': return <MessageSquare className="h-4 w-4 text-blue-500" />
            default: return <Info className="h-4 w-4 text-muted-foreground" />
        }
    }

    return (
        <DropdownMenu>
            <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="relative">
                    <Bell className="h-5 w-5" />
                    {unreadCount > 0 && (
                        <Badge className="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center p-0 text-[10px] bg-destructive text-destructive-foreground border-2 border-background">
                            {unreadCount}
                        </Badge>
                    )}
                </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent className="w-80" align="end">
                <div className="flex items-center justify-between px-4 py-2 border-b">
                    <span className="font-semibold text-sm">Notifications</span>
                    {unreadCount > 0 && (
                        <Button variant="ghost" size="sm" className="h-auto p-0 text-xs text-primary" onClick={handleMarkAllRead}>
                            Mark all as read
                        </Button>
                    )}
                </div>
                <div className="max-h-[400px] overflow-y-auto">
                    {loading ? (
                        <div className="flex justify-center p-8">
                            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                        </div>
                    ) : notifications.length === 0 ? (
                        <div className="p-8 text-center text-sm text-muted-foreground">
                            No notifications yet.
                        </div>
                    ) : (
                        notifications.map((n) => (
                            <DropdownMenuItem key={n.id} className={`flex flex-col items-start gap-1 p-4 focus:bg-accent/50 ${!n.is_read ? 'bg-primary/5' : ''}`}>
                                <div className="flex w-full items-start justify-between gap-2">
                                    <div className="flex items-center gap-2">
                                        {getIcon(n.type)}
                                        <span className={`text-sm font-semibold truncate ${!n.is_read ? '' : 'text-muted-foreground font-normal'}`}>{n.title}</span>
                                    </div>
                                    {!n.is_read && <div className="h-2 w-2 rounded-full bg-primary mt-1.5 shrink-0" />}
                                </div>
                                <p className="text-xs text-muted-foreground line-clamp-2">{n.message}</p>
                                <div className="flex w-full items-center justify-between mt-2">
                                    <span className="text-[10px] text-muted-foreground">
                                        {formatDistanceToNow(new Date(n.created_at), { addSuffix: true })}
                                    </span>
                                    {n.link && (
                                        <Link href={n.link} className="text-[10px] text-primary hover:underline font-medium">
                                            View Details
                                        </Link>
                                    )}
                                </div>
                                {!n.is_read && (
                                    <Button 
                                        variant="ghost" 
                                        size="sm" 
                                        className="h-6 mt-2 self-end text-[10px] gap-1"
                                        onClick={(e) => {
                                            e.preventDefault()
                                            handleMarkAsRead(n.id)
                                        }}
                                    >
                                        <Check className="h-3 w-3" /> Mark Read
                                    </Button>
                                )}
                            </DropdownMenuItem>
                        ))
                    )}
                </div>
                <DropdownMenuSeparator />
                <div className="p-2">
                    <Button variant="ghost" size="sm" className="w-full text-xs text-muted-foreground" asChild>
                        <Link href="/notifications">See all notifications</Link>
                    </Button>
                </div>
            </DropdownMenuContent>
        </DropdownMenu>
    )
}
