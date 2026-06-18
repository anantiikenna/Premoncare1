'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { TrendingUp } from 'lucide-react'

export function WellnessTip() {
    const [dismissed, setDismissed] = useState(false)

    if (dismissed) return null

    return (
        <div className="p-8 rounded-[3rem] bg-linear-to-br from-indigo-500 to-primary text-white shadow-xl shadow-primary/20 relative overflow-hidden group">
            <div className="absolute top-0 right-0 p-6 opacity-10 group-hover:scale-110 transition-transform">
                <TrendingUp className="h-16 w-16" />
            </div>
            <p className="text-[9px] font-black uppercase tracking-widest text-white/60 mb-3">Health Protocol #42</p>
            <p className="text-sm font-bold leading-relaxed mb-6">Hydration increases cognitive performance by 14%. Drink 500ml now.</p>
            <Button
                variant="ghost"
                className="h-8 rounded-lg bg-white/20 text-[9px] font-black uppercase tracking-widest hover:bg-white/30 text-white w-full"
                onClick={() => setDismissed(true)}
            >
                Got it
            </Button>
        </div>
    )
}
