'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Switch } from '@/components/ui/switch'
import { Label } from '@/components/ui/label'
import { Input } from '@/components/ui/input'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { 
    Clock, Calendar, Coffee, ShieldAlert, 
    CheckCircle2, Globe, Copy, Plus, 
    Trash2, Save, Info, Zap
} from 'lucide-react'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { cn } from '@/lib/utils'

export function ScheduleManagement() {
    const [loading, setLoading] = useState(true)
    const [vacationMode, setVacationMode] = useState(false)
    const [emergencyAvailability, setEmergencyAvailability] = useState(false)
    const [autoAccept, setAutoAccept] = useState(false)
    const [weeklyHours, setWeeklyHours] = useState([
        { day: 'Monday', enabled: true, start: '08:00', end: '18:00' },
        { day: 'Tuesday', enabled: true, start: '08:00', end: '18:00' },
        { day: 'Wednesday', enabled: true, start: '08:00', end: '18:00' },
        { day: 'Thursday', enabled: true, start: '08:00', end: '18:00' },
        { day: 'Friday', enabled: true, start: '08:00', end: '17:00' },
        { day: 'Saturday', enabled: false, start: '09:00', end: '13:00' },
        { day: 'Sunday', enabled: false, start: '00:00', end: '00:00' },
    ])
    const [breaks, setBreaks] = useState([
        { id: '1', label: 'Lunch Break', start: '12:00', end: '13:00' },
        { id: '2', label: 'Short Break', start: '16:00', end: '16:15' },
    ])

    const supabase = createClient()

    useEffect(() => {
        const fetchSchedule = async () => {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) return

            const { data, error } = await supabase
                .from('doctor_schedules')
                .select('*')
                .eq('doctor_id', user.id)
                .single()
            
            if (data) {
                setWeeklyHours(data.weekly_hours)
                setBreaks(data.break_times)
                setVacationMode(data.vacation_mode)
                setEmergencyAvailability(data.emergency_availability)
                setAutoAccept(data.auto_accept)
            }
            setLoading(false)
        }
        fetchSchedule()
    }, [supabase])

    const handleSave = async () => {
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) return

        try {
            const { error } = await supabase
                .from('doctor_schedules')
                .upsert({
                    doctor_id: user.id,
                    weekly_hours: weeklyHours,
                    break_times: breaks,
                    vacation_mode: vacationMode,
                    emergency_availability: emergencyAvailability,
                    auto_accept: autoAccept,
                    updated_at: new Date().toISOString()
                })
            
            if (error) throw error
            toast.success('Schedule updated successfully')
        } catch (error: any) {
            toast.error(error.message)
        }
    }

    if (loading) return <div className="flex justify-center p-20"><Clock className="h-10 w-10 animate-spin text-primary" /></div>

    return (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
            <div className="lg:col-span-8 space-y-8">
                {/* Weekly Working Hours */}
                <Card className="rounded-[2.5rem] border shadow-sm bg-white overflow-hidden">
                    <CardHeader className="p-8 pb-4 flex flex-row items-center justify-between">
                        <div>
                            <CardTitle className="text-xl font-black">Weekly Working Hours</CardTitle>
                            <CardDescription>Set your regular working hours for each day of the week.</CardDescription>
                        </div>
                        <Button
                            variant="outline"
                            size="sm"
                            className="rounded-xl font-bold gap-2"
                            onClick={() => {
                                const firstDay = weeklyHours.find((d) => d.enabled)
                                if (!firstDay) return
                                setWeeklyHours(
                                    weeklyHours.map((d) =>
                                        d.enabled ? { ...d, start: firstDay.start, end: firstDay.end } : d
                                    )
                                )
                                toast.success('Hours copied to all active days')
                            }}
                        >
                            <Copy className="h-4 w-4" />
                            Copy to all
                        </Button>
                    </CardHeader>
                    <CardContent className="p-8 space-y-6">
                        {weeklyHours.map((day, idx) => (
                            <div key={day.day} className="flex items-center gap-6 group">
                                <div className="w-32 flex items-center gap-3">
                                    <Switch 
                                        checked={day.enabled} 
                                        onCheckedChange={(val) => {
                                            const newHours = [...weeklyHours]
                                            newHours[idx].enabled = val
                                            setWeeklyHours(newHours)
                                        }}
                                    />
                                    <span className={cn("font-bold text-sm", day.enabled ? "text-slate-900" : "text-slate-400")}>
                                        {day.day}
                                    </span>
                                </div>
                                
                                {day.enabled ? (
                                    <div className="flex items-center gap-3 flex-1">
                                        <Input 
                                            type="time" 
                                            value={day.start} 
                                            onChange={(e) => {
                                                const newHours = [...weeklyHours]
                                                newHours[idx].start = e.target.value
                                                setWeeklyHours(newHours)
                                            }}
                                            className="w-32 h-11 rounded-xl bg-slate-50 border-none"
                                        />
                                        <span className="text-slate-400 text-sm font-medium">to</span>
                                        <Input 
                                            type="time" 
                                            value={day.end} 
                                            onChange={(e) => {
                                                const newHours = [...weeklyHours]
                                                newHours[idx].end = e.target.value
                                                setWeeklyHours(newHours)
                                            }}
                                            className="w-32 h-11 rounded-xl bg-slate-50 border-none"
                                        />
                                        <Button variant="ghost" size="icon" className="ml-auto opacity-0 group-hover:opacity-100 transition-opacity">
                                            <Plus className="h-4 w-4 text-slate-300" />
                                        </Button>
                                    </div>
                                ) : (
                                    <span className="text-slate-400 italic text-sm">Unavailable</span>
                                )}
                            </div>
                        ))}
                    </CardContent>
                </Card>

                {/* Break Times */}
                <Card className="rounded-[2.5rem] border shadow-sm bg-white">
                    <CardHeader className="p-8 pb-4 flex flex-row items-center justify-between">
                        <div>
                            <CardTitle className="text-xl font-black">Break Times (Daily)</CardTitle>
                            <CardDescription>These slots will be automatically blocked from your booking calendar.</CardDescription>
                        </div>
                        <Button
                            variant="outline"
                            size="sm"
                            className="rounded-xl font-bold gap-2 text-primary border-primary/20 hover:bg-primary/5"
                            onClick={() => toast.info('Break scheduling is being developed. Remove individual time slots from the table below to create breaks.')}
                        >
                            <Plus className="h-4 w-4" />
                            Add Break
                        </Button>
                    </CardHeader>
                    <CardContent className="p-8 pt-4">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            {breaks.map((brk) => (
                                <div key={brk.id} className="flex items-center justify-between p-5 rounded-[2rem] bg-slate-50 border border-slate-100 group">
                                    <div className="flex items-center gap-4">
                                        <div className="bg-white p-3 rounded-2xl shadow-sm">
                                            <Coffee className="h-5 w-5 text-amber-500" />
                                        </div>
                                        <div>
                                            <p className="font-black text-slate-900 tracking-tight">{brk.label}</p>
                                            <p className="text-xs font-bold text-slate-500">{brk.start} — {brk.end}</p>
                                        </div>
                                    </div>
                                    <Button
                                        variant="ghost"
                                        size="icon"
                                        className="rounded-xl text-rose-500 opacity-0 group-hover:opacity-100 hover:bg-rose-50 transition-all"
                                        onClick={() => toast.info('Bulk break removal is being developed. Use the table to remove individual time slots.')}
                                    >
                                        <Trash2 className="h-4 w-4" />
                                    </Button>
                                </div>
                            ))}
                        </div>
                    </CardContent>
                </Card>
            </div>

            <div className="lg:col-span-4 space-y-8">
                {/* Global Controls */}
                <Card className="rounded-[2.5rem] border shadow-xl bg-slate-900 text-white overflow-hidden relative">
                    <div className="absolute top-0 right-0 w-32 h-32 bg-primary/20 blur-3xl -mr-16 -mt-16 rounded-full" />
                    <CardHeader className="p-8 pb-4">
                        <CardTitle className="text-xl font-black">Global Controls</CardTitle>
                    </CardHeader>
                    <CardContent className="p-8 space-y-6">
                        <div className="flex items-center justify-between">
                            <div className="space-y-0.5">
                                <Label className="text-sm font-bold">Vacation Mode</Label>
                                <p className="text-[10px] text-slate-500 font-medium">Pause all new bookings immediately</p>
                            </div>
                            <Switch checked={vacationMode} onCheckedChange={setVacationMode} />
                        </div>
                        
                        <div className="flex items-center justify-between">
                            <div className="space-y-0.5">
                                <Label className="text-sm font-bold">Emergency Availability</Label>
                                <p className="text-[10px] text-slate-500 font-medium">Accept calls outside working hours</p>
                            </div>
                            <Switch checked={emergencyAvailability} onCheckedChange={setEmergencyAvailability} />
                        </div>

                        <div className="flex items-center justify-between">
                            <div className="space-y-0.5">
                                <Label className="text-sm font-bold">Auto-Accept Bookings</Label>
                                <p className="text-[10px] text-slate-500 font-medium">Bypass manual review for slots</p>
                            </div>
                            <Switch checked={autoAccept} onCheckedChange={setAutoAccept} />
                        </div>

                        <div className="pt-4 border-t border-slate-800 space-y-4">
                            <div className="flex items-center gap-3 text-emerald-400 bg-emerald-500/10 p-4 rounded-2xl border border-emerald-500/20">
                                <Zap className="h-5 w-5" />
                                <div className="text-[10px] font-black uppercase tracking-widest leading-relaxed">
                                    Emergency Rate: 5x normal rate enabled
                                </div>
                            </div>
                        </div>
                    </CardContent>
                </Card>

                {/* Timezone Settings */}
                <Card className="rounded-[2.5rem] border shadow-sm bg-white p-8 space-y-6">
                    <div className="flex items-center gap-3">
                        <div className="bg-primary/10 p-3 rounded-2xl">
                            <Globe className="h-6 w-6 text-primary" />
                        </div>
                        <div>
                            <h3 className="text-sm font-black">System Timezone</h3>
                            <p className="text-[10px] text-slate-500 font-bold uppercase tracking-widest">Ensures accurate syncing</p>
                        </div>
                    </div>
                    
                    <Select defaultValue="WAT">
                        <SelectTrigger className="h-12 rounded-xl bg-slate-50 border-none font-bold">
                            <SelectValue placeholder="Select Timezone" />
                        </SelectTrigger>
                        <SelectContent className="rounded-xl">
                            <SelectItem value="WAT">(GMT+1) West Africa Time (WAT)</SelectItem>
                            <SelectItem value="GMT">(GMT+0) Greenwich Mean Time</SelectItem>
                            <SelectItem value="EST">(GMT-5) Eastern Standard Time</SelectItem>
                        </SelectContent>
                    </Select>
                </Card>

                <Button 
                    className="w-full h-16 rounded-[2rem] bg-primary hover:bg-primary/90 text-white font-black text-lg shadow-2xl shadow-primary/30 transition-all hover:scale-[1.02] active:scale-[0.98] gap-3"
                    onClick={handleSave}
                >
                    <Save className="h-5 w-5" />
                    Save Schedule Changes
                </Button>
            </div>
        </div>
    )
}

