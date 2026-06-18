'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Switch } from '@/components/ui/switch'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { toast } from 'sonner'
import { getDoctorSchedule, updateDoctorSchedule } from '@/lib/queries-client'
import { Loader2, Plus, Trash2 } from 'lucide-react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'

const DAYS = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
]

interface ScheduleItem {
    id?: string
    doctor_id: string
    day_of_week: number
    start_time: string
    end_time: string
    is_available: boolean
}

export function ScheduleManager({ doctorId }: { doctorId: string }) {
    const queryClient = useQueryClient()
    const [schedule, setSchedule] = useState<ScheduleItem[]>([])

    // Use React Query for fetching
    const { data: fetchedSchedule, isLoading: loading } = useQuery({
        queryKey: ['doctorSchedule', doctorId],
        queryFn: async () => {
            const { data, error } = await getDoctorSchedule(doctorId)
            if (error) throw error
            return data as ScheduleItem[] || []
        }
    })

    // Sync fetched data to local state for editing
    useEffect(() => {
        if (fetchedSchedule) {
            setSchedule(fetchedSchedule)
        }
    }, [fetchedSchedule])

    // Use React Query for mutating
    const { mutate: saveSchedule, isPending: saving } = useMutation({
        mutationFn: async (newSchedule: ScheduleItem[]) => {
            const { error } = await updateDoctorSchedule(newSchedule)
            if (error) throw error
        },
        onSuccess: () => {
            toast.success('Schedule updated successfully')
            queryClient.invalidateQueries({ queryKey: ['doctorSchedule', doctorId] })
        },
        onError: (error: any) => {
            toast.error('Failed to save schedule: ' + (error instanceof Error ? error.message : String(error)))
        }
    })

    const handleAddSlot = (dayIndex: number) => {
        const newSlot: ScheduleItem = {
            doctor_id: doctorId,
            day_of_week: dayIndex,
            start_time: '09:00',
            end_time: '17:00',
            is_available: true
        }
        setSchedule([...schedule, newSlot])
    }

    const handleRemoveSlot = (index: number) => {
        const newSchedule = [...schedule]
        newSchedule.splice(index, 1)
        setSchedule(newSchedule)
    }

    const handleChange = (index: number, field: keyof ScheduleItem, value: any) => {
        const newSchedule = [...schedule]
        newSchedule[index] = { ...newSchedule[index], [field]: value }
        setSchedule(newSchedule)
    }

    const handleSave = () => {
        saveSchedule(schedule)
    }

    if (loading) return <div className="flex justify-center p-8"><Loader2 className="h-8 w-8 animate-spin" /></div>

    return (
        <Card>
            <CardHeader className="flex flex-row items-center justify-between">
                <div>
                    <CardTitle>Availability Schedule</CardTitle>
                    <CardDescription>Set your recurring weekly availability for appointments.</CardDescription>
                </div>
                <Button onClick={handleSave} disabled={saving}>
                    {saving ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : null}
                    Save Schedule
                </Button>
            </CardHeader>
            <CardContent className="space-y-6">
                {DAYS.map((day, dayIndex) => {
                    const daySlots = schedule.filter(s => s.day_of_week === dayIndex)
                    return (
                        <div key={day} className="border-b pb-4 last:border-0 last:pb-0">
                            <div className="flex items-center justify-between mb-2">
                                <h3 className="font-semibold">{day}</h3>
                                <Button variant="outline" size="sm" onClick={() => handleAddSlot(dayIndex)}>
                                    <Plus className="h-4 w-4 mr-1" /> Add Slot
                                </Button>
                            </div>
                            {daySlots.length === 0 ? (
                                <p className="text-sm text-muted-foreground italic">No availability set</p>
                            ) : (
                                <div className="space-y-2">
                                    {daySlots.map((slot, i) => {
                                        const originalIndex = schedule.indexOf(slot)
                                        return (
                                            <div key={i} className="flex items-center gap-4">
                                                <div className="grid grid-cols-2 gap-2 flex-1">
                                                    <div className="flex flex-col gap-1">
                                                        <Label className="text-xs">Start</Label>
                                                        <Input
                                                            type="time"
                                                            value={slot.start_time}
                                                            onChange={(e) => handleChange(originalIndex, 'start_time', e.target.value)}
                                                        />
                                                    </div>
                                                    <div className="flex flex-col gap-1">
                                                        <Label className="text-xs">End</Label>
                                                        <Input
                                                            type="time"
                                                            value={slot.end_time}
                                                            onChange={(e) => handleChange(originalIndex, 'end_time', e.target.value)}
                                                        />
                                                    </div>
                                                </div>
                                                <div className="flex items-center gap-2 mt-4">
                                                    <Switch
                                                        checked={slot.is_available}
                                                        onCheckedChange={(val) => handleChange(originalIndex, 'is_available', val)}
                                                    />
                                                    <Button variant="ghost" size="icon" onClick={() => handleRemoveSlot(originalIndex)}>
                                                        <Trash2 className="h-4 w-4 text-destructive" />
                                                    </Button>
                                                </div>
                                            </div>
                                        )
                                    })}
                                </div>
                            )}
                        </div>
                    )
                })}
            </CardContent>
        </Card>
    )
}
