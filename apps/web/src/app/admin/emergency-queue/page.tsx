'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'
import { EmergencyQueue } from '@/components/admin/emergency-queue'
import { ShieldAlert, RefreshCw, Zap } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { toast } from 'sonner'

export default function AdminEmergencyQueuePage() {
    const router = useRouter()
    const [loading, setLoading] = useState(true)
    const [autoAssigning, setAutoAssigning] = useState(false)

    useEffect(() => {
        const checkAuth = async () => {
            const supabase = createClient()
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) { router.push('/login'); return }
            const { data } = await supabase.from('profiles').select('role').eq('id', user.id).single()
            if (data?.role !== 'admin') { router.push('/patient/dashboard'); return }
            setLoading(false)
        }
        checkAuth()
    }, [router])

    const handleRefresh = () => {
        window.location.reload()
    }

    const handleAutoAssignAll = async () => {
        setAutoAssigning(true)
        try {
            const supabase = createClient()
            const { data: pending } = await supabase
                .from('appointments')
                .select('id')
                .eq('type', 'emergency')
                .eq('status', 'emergency_request')
                .is('doctor_id', null)
                .limit(10)

            if (!pending || pending.length === 0) {
                toast.info('No unassigned emergency requests found')
                return
            }

            const { data: onlineDoctors } = await supabase
                .from('profiles')
                .select('id, full_name')
                .eq('role', 'doctor')
                .eq('is_online', true)

            if (!onlineDoctors || onlineDoctors.length === 0) {
                toast.error('No doctors currently online')
                return
            }

            let assigned = 0
            for (let i = 0; i < Math.min(pending.length, onlineDoctors.length); i++) {
                const { error } = await supabase
                    .from('appointments')
                    .update({ doctor_id: onlineDoctors[i].id, status: 'confirmed' })
                    .eq('id', pending[i].id)
                if (!error) assigned++
            }

            if (assigned > 0) {
                toast.success(`Auto-assigned ${assigned} emergency request(s)`)
            }
        } catch (error: any) {
            toast.error(error.message || 'Auto-assign failed')
        } finally {
            setAutoAssigning(false)
        }
    }

    return (
        <div className="space-y-8 animate-in-fade">
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6 bg-rose-50/50 p-8 rounded-[2.5rem] border border-rose-100 shadow-sm relative overflow-hidden group">
                <div className="absolute top-0 left-0 w-full h-1 bg-linear-to-r from-rose-500 via-rose-400 to-rose-500 opacity-50" />
                <div className="space-y-2 relative z-10">
                    <div className="flex items-center gap-2 text-rose-600 font-black uppercase tracking-widest text-xs">
                        <ShieldAlert className="h-4 w-4 animate-pulse" />
                        Critical Operations
                    </div>
                    <h1 className="text-4xl font-black tracking-tighter text-slate-900 flex items-center gap-3">
                        Emergency Queue Management
                        <Badge variant="outline" className="bg-rose-500 text-white border-none px-3 py-1 animate-pulse">LIVE</Badge>
                    </h1>
                    <p className="text-muted-foreground text-lg font-medium max-w-xl">
                        Monitor and manage all emergency consultation requests in real-time. Assign doctors, escalate cases, and ensure critical response times.
                    </p>
                </div>
                <div className="flex items-center gap-3 relative z-10">
                    <Button variant="outline" onClick={handleRefresh} className="rounded-2xl h-12 px-6 font-bold shadow-sm bg-white hover:bg-slate-50 transition-all">
                        <RefreshCw className="h-4 w-4 mr-2" />
                        Refresh Live Feed
                    </Button>
                    <Button className="rounded-2xl h-12 px-6 font-black bg-rose-600 hover:bg-rose-700 shadow-lg shadow-rose-200 transition-all hover:scale-105 active:scale-95" onClick={handleAutoAssignAll} disabled={autoAssigning}>
                        <Zap className="h-4 w-4 mr-2" />
                        {autoAssigning ? 'Assigning...' : 'Auto-Assign Active'}
                    </Button>
                </div>
            </div>

            <EmergencyQueue />
        </div>
    )
}
