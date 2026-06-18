'use client'

import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { ShieldCheck, Cookie, Info } from 'lucide-react'

export function CookieConsent() {
  const [isOpen, setIsOpen] = useState(false)

  useEffect(() => {
    const consent = localStorage.getItem('premon_cookie_consent')
    if (!consent) {
      // Trigger short delay for smooth fade in entrance
      const timer = setTimeout(() => {
        setIsOpen(true)
      }, 1500)
      return () => clearTimeout(timer)
    }
  }, [])

  const handleAccept = () => {
    localStorage.setItem('premon_cookie_consent', 'accepted')
    setIsOpen(false)
  }

  const handleReject = () => {
    localStorage.setItem('premon_cookie_consent', 'rejected')
    setIsOpen(false)
  }

  if (!isOpen) return null

  return (
    <div 
      role="region" 
      aria-label="Cookie Consent Banner" 
      className="fixed bottom-6 left-6 right-6 md:left-auto md:right-8 md:max-w-md z-50 animate-in-fade"
    >
      <div className="glass-panel border-none p-6 rounded-[2.5rem] bg-white/70 backdrop-blur-xl shadow-2xl flex flex-col gap-5 border border-white/40">
        <div className="flex gap-4 items-start">
          <div className="h-12 w-12 rounded-2xl bg-primary/10 flex items-center justify-center text-primary shrink-0">
            <Cookie className="h-6 w-6" />
          </div>
          <div className="space-y-1">
            <h4 className="text-sm font-black text-slate-900 uppercase tracking-widest flex items-center gap-1.5">
              Cookie Consent <span className="text-[10px] font-black bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded-full lowercase tracking-normal">secure</span>
            </h4>
            <p className="text-xs text-slate-500 font-bold leading-relaxed pt-1">
              We value your privacy. We use standard session tokens and security telemetry logs to authenticate clinical visits, verify payments, and keep video streams functional.
            </p>
          </div>
        </div>

        <div className="flex gap-3 justify-end pt-1">
          <Button
            variant="ghost"
            onClick={handleReject}
            className="h-10 rounded-xl font-black text-[10px] uppercase tracking-widest text-slate-500 hover:bg-slate-100"
            aria-label="Reject non-essential cookies"
          >
            Reject Non-Essential
          </Button>
          <Button
            onClick={handleAccept}
            className="h-10 rounded-xl bg-primary hover:bg-primary/90 text-white font-black text-[10px] uppercase tracking-widest px-5 shadow-lg shadow-primary/20"
            aria-label="Accept all cookies"
          >
            Accept All
          </Button>
        </div>
      </div>
    </div>
  )
}
