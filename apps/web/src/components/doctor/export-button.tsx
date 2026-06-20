'use client'

import { toast } from 'sonner'
import { Button } from '@/components/ui/button'

export function ExportButton() {
    return (
        <Button
            variant="outline"
            className="w-full h-12 rounded-2xl border-slate-200 font-black uppercase tracking-widest text-[10px] text-slate-600 hover:bg-slate-50"
            onClick={() => toast.info('Schedule export is being developed. Use the browser\'s print function to save your schedule.')}
        >
            Export Session Logs
        </Button>
    )
}
