'use client'

import { useState, useEffect, useRef } from 'react'
import { Card } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { getConversations, getMessages, sendMessage, markMessagesAsRead } from '@/lib/queries-client'
import { createClient } from '@/lib/supabase'
import { Send, Search, Loader2 } from 'lucide-react'
import { toast } from 'sonner'
import { format } from 'date-fns'
import { Badge } from '@/components/ui/badge'

export function MessagingDashboard({ currentUserId }: { currentUserId: string }) {
    const [conversations, setConversations] = useState<any[]>([])
    const [activeContact, setActiveContact] = useState<any | null>(null)
    const [messages, setMessages] = useState<any[]>([])
    const [newMessage, setNewMessage] = useState('')
    const [loading, setLoading] = useState(true)
    const [loadingMessages, setLoadingMessages] = useState(false)
    const [searchQuery, setSearchQuery] = useState('')
    const messagesEndRef = useRef<HTMLDivElement>(null)
    const supabase = createClient()

    useEffect(() => {
        const fetchInitialConversations = async () => {
            const { data } = await getConversations(currentUserId)
            if (data) setConversations(data)
            setLoading(false)
        }
        fetchInitialConversations()

        // Set up real-time listener for incoming messages
        const channel = supabase
            .channel(`messages:user:${currentUserId}`, {
                config: { private: true },
            })
            .on('postgres_changes', {
                event: 'INSERT',
                schema: 'public',
                table: 'messages',
                filter: `receiver_id=eq.${currentUserId}`
            }, async (payload) => {
                // Refresh conversations to update order/unread count
                const { data } = await getConversations(currentUserId)
                if (data) setConversations(data)

                // If the message is from the active contact, add it to the view and mark read
                if (activeContact && payload.new.sender_id === activeContact.id) {
                    setMessages(prev => [...prev, payload.new])
                    await markMessagesAsRead(currentUserId, activeContact.id)
                } else {
                    toast.info('New message received')
                }
            })
            .subscribe()

        return () => {
            supabase.removeChannel(channel)
        }
    }, [currentUserId, activeContact])

    useEffect(() => {
        const loadMessages = async () => {
            if (!activeContact) return
            setLoadingMessages(true)
            const { data } = await getMessages(currentUserId, activeContact.id)
            if (data) {
                setMessages(data)
                // Mark as read
                await markMessagesAsRead(currentUserId, activeContact.id)
                
                // Update local conversation state to clear unread tally
                setConversations(prev => prev.map(c => 
                    c.contact.id === activeContact.id 
                        ? { ...c, unreadCount: 0 } 
                        : c
                ))
            }
            setLoadingMessages(false)
        }
        loadMessages()
    }, [activeContact, currentUserId])

    useEffect(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
    }, [messages])

    const handleSendMessage = async (e: React.FormEvent) => {
        e.preventDefault()
        if (!newMessage.trim() || !activeContact) return

        const content = newMessage.trim()
        setNewMessage('') // Optimistic clear

        // Optimistic UI update
        const tempMsg = {
            id: 'temp-' + Date.now(),
            sender_id: currentUserId,
            receiver_id: activeContact.id,
            content,
            created_at: new Date().toISOString(),
            is_read: false
        }
        setMessages(prev => [...prev, tempMsg])

        const { error } = await sendMessage(currentUserId, activeContact.id, content)
        if (error) {
            toast.error('Failed to send message')
            // Revert optimistic update (simplified)
            setMessages(prev => prev.filter(m => m.id !== tempMsg.id))
            setNewMessage(content)
        } else {
            // Update conversations list to put this one on top
            const { data } = await getConversations(currentUserId)
            if (data) setConversations(data)
        }
    }

    const filteredConversations = conversations.filter(c => 
        c.contact.full_name.toLowerCase().includes(searchQuery.toLowerCase())
    )

    if (loading) {
        return <div className="flex h-[600px] items-center justify-center"><Loader2 className="h-8 w-8 animate-spin" /></div>
    }

    return (
        <Card className="flex h-[calc(100vh-12rem)] min-h-[500px] overflow-hidden">
            {/* Sidebar / Contacts List */}
            <div className={`w-full md:w-80 border-r flex flex-col ${activeContact ? 'hidden md:flex' : 'flex'}`}>
                <div className="p-4 border-b">
                    <div className="relative">
                        <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                        <Input
                            placeholder="Search contacts..."
                            className="pl-8"
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                        />
                    </div>
                </div>
                <ScrollArea className="flex-1">
                    {filteredConversations.length === 0 ? (
                        <div className="p-4 text-center text-sm text-muted-foreground">
                            No conversations found.
                        </div>
                    ) : (
                        filteredConversations.map((conv) => (
                            <button
                                key={conv.contact.id}
                                onClick={() => setActiveContact(conv.contact)}
                                className={`w-full p-4 flex items-start gap-4 hover:bg-accent/50 transition-colors text-left border-b last:border-0 ${activeContact?.id === conv.contact.id ? 'bg-accent' : ''}`}
                            >
                                <Avatar>
                                    <AvatarImage src={conv.contact.avatar_url} />
                                    <AvatarFallback>{conv.contact.full_name?.charAt(0)}</AvatarFallback>
                                </Avatar>
                                <div className="flex-1 overflow-hidden">
                                    <div className="flex justify-between items-baseline mb-1">
                                        <h4 className="font-semibold text-sm truncate">{conv.contact.full_name}</h4>
                                        <span className="text-xs text-muted-foreground whitespace-nowrap ml-2">
                                            {format(new Date(conv.lastMessage.created_at), 'MMM d, h:mm a')}
                                        </span>
                                    </div>
                                    <p className="text-sm text-muted-foreground truncate">
                                        {conv.lastMessage.sender_id === currentUserId ? 'You: ' : ''}
                                        {conv.lastMessage.content}
                                    </p>
                                </div>
                                {conv.unreadCount > 0 && (
                                    <Badge variant="default" className="ml-2 bg-primary">
                                        {conv.unreadCount}
                                    </Badge>
                                )}
                            </button>
                        ))
                    )}
                </ScrollArea>
            </div>

            {/* Chat Area */}
            <div className={`flex-1 flex flex-col ${!activeContact ? 'hidden md:flex' : 'flex'}`}>
                {activeContact ? (
                    <>
                        {/* Chat Header */}
                        <div className="p-4 border-b flex items-center justify-between bg-card text-card-foreground">
                            <div className="flex items-center gap-3">
                                {/* Mobile back button */}
                                <Button 
                                    variant="ghost" 
                                    className="md:hidden mr-2 px-2" 
                                    onClick={() => setActiveContact(null)}
                                >
                                    &larr; Back
                                </Button>
                                <Avatar>
                                    <AvatarImage src={activeContact.avatar_url} />
                                    <AvatarFallback>{activeContact.full_name?.charAt(0)}</AvatarFallback>
                                </Avatar>
                                <div>
                                    <h3 className="font-bold">{activeContact.full_name}</h3>
                                    <p className="text-xs text-muted-foreground capitalize">{activeContact.role}</p>
                                </div>
                            </div>
                        </div>

                        {/* Messages Area */}
                        <ScrollArea className="flex-1 p-4">
                            {loadingMessages ? (
                                <div className="flex h-full items-center justify-center"><Loader2 className="h-6 w-6 animate-spin" /></div>
                            ) : (
                                <div className="space-y-4">
                                    {messages.map((msg) => {
                                        const isMe = msg.sender_id === currentUserId
                                        return (
                                            <div key={msg.id} className={`flex flex-col ${isMe ? 'items-end' : 'items-start'}`}>
                                                <div 
                                                    className={`max-w-[75%] px-4 py-2 rounded-2xl ${
                                                        isMe 
                                                            ? 'bg-primary text-primary-foreground rounded-tr-sm' 
                                                            : 'bg-muted rounded-tl-sm'
                                                    }`}
                                                >
                                                    {msg.content}
                                                </div>
                                                <div className="text-[10px] text-muted-foreground mt-1 mx-1">
                                                    {format(new Date(msg.created_at), 'h:mm a')}
                                                    {isMe && msg.is_read && <span className="ml-2 text-primary">Read</span>}
                                                </div>
                                            </div>
                                        )
                                    })}
                                    <div ref={messagesEndRef} />
                                </div>
                            )}
                        </ScrollArea>

                        {/* Message Input */}
                        <div className="p-4 bg-background border-t">
                            <form onSubmit={handleSendMessage} className="flex gap-2">
                                <Input
                                    value={newMessage}
                                    onChange={(e) => setNewMessage(e.target.value)}
                                    placeholder="Type a message..."
                                    className="flex-1"
                                />
                                <Button type="submit" size="icon" disabled={!newMessage.trim()}>
                                    <Send className="h-4 w-4" />
                                </Button>
                            </form>
                        </div>
                    </>
                ) : (
                    <div className="flex-1 flex flex-col items-center justify-center text-muted-foreground">
                        <MessageSquareIcon className="h-12 w-12 mb-4 opacity-20" />
                        <p>Select a conversation to start messaging</p>
                    </div>
                )}
            </div>
        </Card>
    )
}

function MessageSquareIcon(props: any) {
    return (
        <svg
            {...props}
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
        >
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
        </svg>
    )
}
