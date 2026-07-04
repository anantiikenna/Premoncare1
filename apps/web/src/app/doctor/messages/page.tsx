'use client'

import { useState, useEffect, useRef } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { createClient } from '@/lib/supabase'
import { toast } from 'sonner'
import { Loader2, Send, ShieldCheck, Mail, ArrowLeft } from 'lucide-react'
import Link from 'next/link'
import { getUserFacingError } from '@/lib/user-facing-errors'

interface Message {
    id: string
    created_at: string
    sender_id: string
    sender_role: string
    message: string
}

export default function DoctorMessagesPage() {
    const [messages, setMessages] = useState<Message[]>([])
    const [newMessage, setNewMessage] = useState('')
    const [loading, setLoading] = useState(true)
    const [sending, setSending] = useState(false)
    const [doctor, setDoctor] = useState<any>(null)
    const scrollRef = useRef<HTMLDivElement>(null)
    const supabase = createClient()

    useEffect(() => {
        const fetchInitialData = async () => {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) return

            const { data: profile } = await supabase
                .from('profiles')
                .select('*')
                .eq('id', user.id)
                .single()
            setDoctor(profile)

            const { data: msgs } = await supabase
                .from('fee_negotiation_messages')
                .select('*')
                .eq('doctor_id', user.id)
                .order('created_at', { ascending: true })

            if (msgs) setMessages(msgs)
            setLoading(false)
        }

        fetchInitialData()

        // Realtime Subscription
        const channel = supabase.channel('doctor:messages:fee', {
                config: { private: true },
            })
            .on(
                'postgres_changes',
                { event: 'INSERT', schema: 'public', table: 'fee_negotiation_messages' },
                (payload) => {
                    setMessages(current => [...current, payload.new as Message])
                }
            )
            .subscribe()

        return () => {
            supabase.removeChannel(channel)
        }
    }, [supabase])

    useEffect(() => {
        if (scrollRef.current) {
            scrollRef.current.scrollIntoView({ behavior: 'smooth' })
        }
    }, [messages])

    const handleSend = async (e: React.FormEvent) => {
        e.preventDefault()
        if (!newMessage.trim() || !doctor) return
        
        setSending(true)
        const content = newMessage.trim()
        setNewMessage('') // Optimistic clear
        
        try {
            const { error } = await supabase.from('fee_negotiation_messages').insert({
                doctor_id: doctor.id,
                sender_id: doctor.id,
                sender_role: 'doctor',
                message: content
            })
            if (error) throw error
        } catch (error: unknown) {
            console.error('Fee negotiation message failed', error)
            toast.error(getUserFacingError(error, 'We could not send this message. Please try again.'))
            setNewMessage(content) // restore
        } finally {
            setSending(false)
        }
    }

    if (loading) return <div className="flex justify-center items-center h-[50vh]"><Loader2 className="w-8 h-8 animate-spin text-primary" /></div>

    return (
        <div className="max-w-4xl mx-auto py-8">
            <Link href="/doctor/dashboard" className="inline-flex items-center text-sm font-bold text-muted-foreground hover:text-primary mb-6 transition-colors">
                <ArrowLeft className="w-4 h-4 mr-2" /> Back to Dashboard
            </Link>

            <Card className="border-0 shadow-2xl overflow-hidden rounded-3xl">
                <CardHeader className="bg-slate-900 text-white p-6 border-b border-white/10">
                    <div className="flex items-center justify-between">
                        <div className="space-y-1">
                            <CardTitle className="text-xl font-black flex items-center gap-2">
                                <ShieldCheck className="h-5 w-5 text-primary" />
                                Administration Negotiation
                            </CardTitle>
                            <p className="text-slate-400 text-sm">Agree on platform fees and subscription terms with our core team.</p>
                        </div>
                        <div className="text-right">
                            <p className="text-xs uppercase tracking-widest text-slate-500 font-bold mb-1">Fee Status</p>
                            <span className="px-3 py-1 bg-yellow-500/20 text-yellow-500 border border-yellow-500/30 rounded-full text-[10px] font-black uppercase tracking-wider">
                                {doctor?.fee_status.replace(/_/g, ' ')}
                            </span>
                        </div>
                    </div>
                </CardHeader>
                
                <CardContent className="p-0">
                    <ScrollArea className="h-[500px]">
                        <div className="p-6 space-y-6">
                            {messages.length === 0 ? (
                                <div className="text-center py-20 text-muted-foreground">
                                    <Mail className="h-12 w-12 mx-auto mb-4 opacity-20" />
                                    <p className="font-medium">No messages yet.</p>
                                    <p className="text-sm">Initiate a conversation regarding your platform fees.</p>
                                </div>
                            ) : (
                                messages.map((msg) => {
                                    const isMe = msg.sender_role === 'doctor'
                                    return (
                                        <div key={msg.id} className={`flex gap-3 ${isMe ? 'justify-end' : 'justify-start'}`}>
                                            {!isMe && (
                                                <Avatar className="h-8 w-8 ring-2 ring-primary/20">
                                                    <AvatarFallback className="bg-primary/10 text-primary text-xs font-black">A</AvatarFallback>
                                                </Avatar>
                                            )}
                                            
                                            <div className={`max-w-[75%] ${isMe ? 'items-end' : 'items-start'} flex flex-col gap-1`}>
                                                <div className="flex items-center gap-2 px-1">
                                                    <span className="text-[10px] font-bold text-muted-foreground uppercase">{isMe ? 'You' : 'Admin'}</span>
                                                    <span className="text-[9px] text-muted-foreground/60">{new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                                                </div>
                                                <div className={`px-4 py-3 rounded-2xl text-sm ${isMe ? 'bg-primary text-white rounded-br-none shadow-md shadow-primary/20' : 'bg-muted rounded-bl-none border border-border'}`}>
                                                    {msg.message}
                                                </div>
                                            </div>
                                            
                                            {isMe && (
                                                <Avatar className="h-8 w-8 ring-2 ring-transparent">
                                                    <AvatarImage src={doctor?.avatar_url} />
                                                    <AvatarFallback className="bg-slate-200 text-xs font-bold">ME</AvatarFallback>
                                                </Avatar>
                                            )}
                                        </div>
                                    )
                                })
                            )}
                            <div ref={scrollRef} />
                        </div>
                    </ScrollArea>
                    
                    <div className="p-4 bg-slate-50 border-t">
                        <form onSubmit={handleSend} className="flex gap-2">
                            <Input
                                value={newMessage}
                                onChange={(e) => setNewMessage(e.target.value)}
                                placeholder="Type your message to the administration..."
                                className="h-12 rounded-full border-slate-200 bg-white"
                                disabled={sending}
                            />
                            <Button 
                                type="submit" 
                                disabled={!newMessage.trim() || sending} 
                                className="h-12 w-12 rounded-full p-0 shadow-lg"
                            >
                                {sending ? <Loader2 className="h-5 w-5 animate-spin" /> : <Send className="h-5 w-5 ml-1" />}
                            </Button>
                        </form>
                    </div>
                </CardContent>
            </Card>
        </div>
    )
}
