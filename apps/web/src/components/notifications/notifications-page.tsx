'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Bell, Check, Trash2, Calendar, CreditCard, Pill, MessageSquare, Info, Loader2, Sparkles, Filter } from 'lucide-react'
import { getUserNotifications, markNotificationAsRead, markAllNotificationsAsRead } from '@/lib/queries-client'
import { formatDistanceToNow } from 'date-fns'
import Link from 'next/link'
import { createClient } from '@/lib/supabase'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

export function NotificationsList({ userId }: { userId: string }) {
    const [notifications, setNotifications] = useState<any[]>([])
    const [loading, setLoading] = useState(true)
    const supabase = createClient()

    const fetchNotifications = async () => {
        const { data } = await getUserNotifications(userId)
        if (data) setNotifications(data)
        setLoading(false)
    }

    useEffect(() => {
        fetchNotifications()
        
        const channel = supabase
            .channel(`notifications-page-${userId}`)
            .on(
                'postgres_changes',
                { event: 'INSERT', schema: 'public', table: 'notifications', filter: `user_id=eq.${userId}` },
                () => fetchNotifications()
            )
            .subscribe()

        return () => { supabase.removeChannel(channel) }
    }, [userId])

    const handleMarkAsRead = async (id: string) => {
        await markNotificationAsRead(id)
        setNotifications(prev => prev.map(n => n.id === id ? { ...n, is_read: true } : n))
    }

    const handleMarkAllRead = async () => {
        await markAllNotificationsAsRead(userId)
        setNotifications(prev => prev.map(n => ({ ...n, is_read: true })))
    }

    const getIcon = (type: string) => {
        switch (type) {
            case 'appointment': return <Calendar className="h-5 w-5 text-primary" />
            case 'payment': return <CreditCard className="h-5 w-5 text-green-500" />
            case 'prescription': return <Pill className="h-5 w-5 text-amber-500" />
            case 'message': return <MessageSquare className="h-5 w-5 text-blue-500" />
            case 'appointment_proposal': return <Sparkles className="h-5 w-5 text-indigo-600" />
            default: return <Info className="h-5 w-5 text-muted-foreground" />
        }
    }

    const EmptyState = ({ message }: { message: string }) => (
        <div className="text-center py-32 flex flex-col items-center justify-center animate-in-fade">
            <div className="relative mb-6">
                <div className="absolute inset-0 bg-primary/10 blur-2xl rounded-full" />
                <div className="h-20 w-20 rounded-3xl bg-white shadow-xl flex items-center justify-center text-primary/30 relative z-10">
                    <Bell className="h-10 w-10" />
                </div>
            </div>
            <h3 className="text-2xl font-black tracking-tighter text-slate-900">Silence is Golden</h3>
            <p className="text-muted-foreground font-bold text-[10px] uppercase tracking-[0.2em] mt-2 max-w-[200px] mx-auto leading-loose">
                {message}
            </p>
        </div>
    )

    if (loading) {
        return (
            <div className="space-y-6">
                <Card className="animate-pulse h-20 rounded-[1.5rem] bg-muted/20 border-none" />
                <Card className="animate-pulse h-96 rounded-[3rem] bg-muted/10 border-none" />
            </div>
        )
    }

    const bookingNotifications = notifications.filter(n => n.type === 'appointment')
    const paymentNotifications = notifications.filter(n => n.type === 'payment')

    return (
        <div className="space-y-8 pb-20">
            <div className="flex items-center justify-between px-2">
                <div className="flex items-center gap-4">
                    <div className="bg-primary/10 p-3 rounded-2xl">
                        <Bell className="h-6 w-6 text-primary" />
                    </div>
                    <div>
                        <h1 className="text-3xl font-black tracking-tighter text-foreground uppercase">Alerts Hub</h1>
                        <p className="text-[10px] font-black text-muted-foreground/60 uppercase tracking-widest">Stay updated with your clinical activity</p>
                    </div>
                </div>
                {notifications.some(n => !n.is_read) && (
                    <Button variant="outline" size="sm" onClick={handleMarkAllRead} className="rounded-full font-black uppercase tracking-widest text-[9px] border-primary/20 text-primary hover:bg-primary/5">
                        Mark all as read
                    </Button>
                )}
            </div>

            <Tabs defaultValue="all" className="w-full">
                <TabsList className="grid w-full max-w-md grid-cols-3 rounded-[1.5rem] p-1 bg-muted/30 h-14 mb-8">
                    <TabsTrigger value="all" className="rounded-2xl font-black text-[10px] uppercase tracking-widest data-[state=active]:bg-white data-[state=active]:shadow-lg">All</TabsTrigger>
                    <TabsTrigger value="bookings" className="rounded-2xl font-black text-[10px] uppercase tracking-widest data-[state=active]:bg-white data-[state=active]:shadow-lg">Bookings</TabsTrigger>
                    <TabsTrigger value="payments" className="rounded-2xl font-black text-[10px] uppercase tracking-widest data-[state=active]:bg-white data-[state=active]:shadow-lg">Payments</TabsTrigger>
                </TabsList>

                <TabsContent value="all" className="mt-0">
                    <Card className="border-none shadow-2xl shadow-primary/5 rounded-[3rem] overflow-hidden bg-card/50">
                        <CardContent className="p-8">
                            {notifications.length === 0 ? (
                                <EmptyState message="You're all caught up with your notifications." />
                            ) : (
                                <div className="space-y-4">
                                    {notifications.map((n) => (
                                        <NotificationItem key={n.id} n={n} getIcon={getIcon} onMarkAsRead={handleMarkAsRead} />
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>

                <TabsContent value="bookings" className="mt-0">
                    <Card className="border-none shadow-2xl shadow-primary/5 rounded-[3rem] overflow-hidden bg-card/50">
                        <CardContent className="p-8">
                            {bookingNotifications.length === 0 ? (
                                <EmptyState message="No appointment updates found in your records." />
                            ) : (
                                <div className="space-y-4">
                                    {bookingNotifications.map((n) => (
                                        <NotificationItem key={n.id} n={n} getIcon={getIcon} onMarkAsRead={handleMarkAsRead} />
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>

                <TabsContent value="payments" className="mt-0">
                    <Card className="border-none shadow-2xl shadow-primary/5 rounded-[3rem] overflow-hidden bg-card/50">
                        <CardContent className="p-8">
                            {paymentNotifications.length === 0 ? (
                                <EmptyState message="No financial or transaction alerts found." />
                            ) : (
                                <div className="space-y-4">
                                    {paymentNotifications.map((n) => (
                                        <NotificationItem key={n.id} n={n} getIcon={getIcon} onMarkAsRead={handleMarkAsRead} />
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>
            </Tabs>
        </div>
    )
}

function NotificationItem({ n, getIcon, onMarkAsRead }: { n: any, getIcon: (t: string) => React.ReactNode, onMarkAsRead: (id: string) => void }) {
    return (
        <div 
            className={`flex items-start gap-5 p-6 rounded-[2rem] border transition-all duration-300 group hover:shadow-lg hover:shadow-primary/5 ${!n.is_read ? 'bg-primary/5 border-primary/20' : 'bg-white border-slate-100 hover:border-primary/20'}`}
        >
            <div className={`p-4 rounded-2xl shadow-sm group-hover:scale-110 transition-transform ${!n.is_read ? 'bg-white' : 'bg-slate-50'}`}>
                {getIcon(n.type)}
            </div>
            <div className="flex-1 space-y-2">
                <div className="flex items-center justify-between">
                    <h4 className={`text-lg font-black tracking-tight ${!n.is_read ? 'text-primary' : 'text-slate-900'}`}>{n.title}</h4>
                    <span className="text-[10px] font-black uppercase tracking-widest text-muted-foreground/50">
                        {formatDistanceToNow(new Date(n.created_at), { addSuffix: true })}
                    </span>
                </div>
                <p className="text-sm font-bold text-muted-foreground/70 leading-relaxed">{n.message}</p>
                <div className="flex items-center gap-6 pt-3">
                    {n.type === 'appointment_proposal' ? (
                        <Button className="h-10 px-6 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-black uppercase tracking-widest text-[9px] shadow-lg shadow-indigo-200 group/btn" asChild>
                            <Link href={n.link}>
                                Accept Proposal <Sparkles className="ml-2 h-3 w-3 transition-transform group-hover/btn:scale-125" />
                            </Link>
                        </Button>
                    ) : (
                        n.link && (
                            <Button variant="link" size="sm" className="h-auto p-0 text-[10px] font-black uppercase tracking-widest text-primary hover:text-primary/70" asChild>
                                <Link href={n.link}>Explore Details</Link>
                            </Button>
                        )
                    )}
                    {!n.is_read && (
                        <Button variant="ghost" size="sm" className="h-auto p-0 text-[10px] font-black uppercase tracking-widest text-primary hover:bg-transparent" onClick={() => onMarkAsRead(n.id)}>
                            Mark as resolved
                        </Button>
                    )}
                </div>
            </div>
        </div>
    )
}
