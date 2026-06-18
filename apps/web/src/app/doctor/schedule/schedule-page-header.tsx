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
        onClick={() => toast.info('Booking preferences coming soon')}
      >
        <Settings className="h-4 w-4 mr-2" />
        Booking Preferences
      </Button>
      <Button
        className="rounded-2xl h-12 px-6 font-black bg-primary hover:bg-primary/90 shadow-lg shadow-primary/20 transition-all hover:scale-105 active:scale-95"
        onClick={() => toast.info('Calendar view coming soon')}
      >
        <Calendar className="h-4 w-4 mr-2" />
        View Calendar
      </Button>
    </div>
  )
}
