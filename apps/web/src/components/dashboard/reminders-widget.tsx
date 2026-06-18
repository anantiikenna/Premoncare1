'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Calendar, Clock, ArrowRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import Link from 'next/link'
import { getAppointments } from '@/lib/queries-client'

export function RemindersWidget({ userId, role }: { userId: string, role: 'patient' | 'doctor' }) {
    const [upcoming, setUpcoming] = useState<any[]>([])
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        async function fetchUpcoming() {
            const { data } = await getAppointments(userId, role)
            if (data) {
                const now = new Date()
                const soon = data
                    .filter(a => (a.status === 'confirmed' || a.status === 'pending') && new Date(a.appointment_date) > now)
                    .slice(0, 2)
                setUpcoming(soon)
            }
            setLoading(false)
        }
        fetchUpcoming()
    }, [userId, role])

    if (loading || upcoming.length === 0) return null

    return (
        <div className="space-y-4">
            <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider px-1">Upcoming Reminders</h3>
            <div className="grid gap-3">
                {upcoming.map((apt) => (
                    <Card key={apt.id} className="border-l-4 border-l-primary bg-primary/5">
                        <CardContent className="p-4 flex items-center justify-between">
                            <div className="flex items-center gap-4">
                                <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center">
                                    <Calendar className="h-5 w-5 text-primary" />
                                </div>
                                <div>
                                    <p className="text-sm font-bold">
                                        Appointment with {role === 'patient' ? `Dr. ${apt.doctor.full_name}` : apt.patient.full_name}
                                    </p>
                                    <div className="flex items-center gap-2 text-xs text-muted-foreground mt-1">
                                        <Clock className="h-3 w-3" />
                                        {new Date(apt.appointment_date).toLocaleString([], { weekday: 'short', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
                                    </div>
                                </div>
                            </div>
                            <Button variant="ghost" size="sm" className="gap-2" asChild>
                                <Link href={role === 'patient' ? '/patient/appointments' : '/doctor/appointments'}>
                                    Details <ArrowRight className="h-3 w-3" />
                                </Link>
                            </Button>
                        </CardContent>
                    </Card>
                ))}
            </div>
        </div>
    )
}
