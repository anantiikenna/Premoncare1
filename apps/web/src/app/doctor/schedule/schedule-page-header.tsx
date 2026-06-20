'use client'

import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Calendar, Settings } from 'lucide-react'

export function SchedulePageHeader() {
  return (
    <div className="flex items-center gap-3 relative z-10">
      <Button
        variant="outline"
        className="rounded-2xl h-12 px-6 font-bold shadow-sm hover:bg-slate-50 transition-all"
        onClick={() => toast.info('Configure booking windows, patient intake forms, and appointment buffer times — coming soon.')}
      >
        <Settings className="h-4 w-4 mr-2" />
        Booking Preferences
      </Button>
      <Button
        className="rounded-2xl h-12 px-6 font-black bg-primary hover:bg-primary/90 shadow-lg shadow-primary/20 transition-all hover:scale-105 active:scale-95"
        onClick={() => toast.info('Full calendar view with month/week/day toggle is coming soon. Use the schedule table below to manage your availability.')}
      >
        <Calendar className="h-4 w-4 mr-2" />
        View Calendar
      </Button>
    </div>
  )
}
