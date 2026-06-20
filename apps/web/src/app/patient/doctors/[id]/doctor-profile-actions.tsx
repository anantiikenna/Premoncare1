'use client'

import { useRouter } from 'next/navigation'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { MessageSquare, Video, Calendar } from 'lucide-react'

export function ShareProfileButton() {
  return (
    <Button
      variant="outline"
      className="rounded-xl border-slate-200 text-xs font-bold"
      onClick={() => {
        if (navigator.clipboard) {
          navigator.clipboard.writeText(window.location.href)
          toast.success('Profile link copied!')
        } else {
          toast.error('Clipboard not available')
        }
      }}
    >
      Share Profile
    </Button>
  )
}

export function ViewCredentialsButton() {
  return (
    <Button
      variant="outline"
      size="sm"
      className="bg-white border-blue-200 text-blue-600 text-xs font-bold rounded-xl h-9 shrink-0"
      onClick={() => toast.info('You can request credentials verification from the doctor\'s profile. This feature is being enhanced.')}
    >
      View Credentials
    </Button>
  )
}

export function DoctorBottomBar({
  doctorId,
  videoFee,
  inPersonFee,
}: {
  doctorId: string
  videoFee: number
  inPersonFee: number
}) {
  const router = useRouter()

  return (
    <div className="fixed bottom-0 left-0 right-0 lg:left-64 p-6 bg-white border-t border-slate-100 shadow-[0_-10px_40px_-15px_rgba(0,0,0,0.05)] z-50">
      <div className="max-w-4xl mx-auto flex gap-4">
        <Button
          variant="outline"
          className="h-16 w-16 rounded-2xl border-slate-200 flex flex-col items-center justify-center gap-1"
          onClick={() => router.push(`/messages?doctorId=${doctorId}`)}
        >
          <MessageSquare className="h-5 w-5 text-primary" />
          <span className="text-[10px] font-black text-primary uppercase tracking-widest">Chat</span>
        </Button>
        <Button
          className="flex-1 h-16 rounded-2xl bg-primary hover:bg-primary/90 flex flex-col items-center justify-center gap-1 shadow-lg shadow-primary/20"
          onClick={() => router.push(`/patient/doctors/${doctorId}?book=video`)}
        >
          <div className="flex items-center gap-2">
            <Video className="h-5 w-5" />
            <span className="font-black text-sm uppercase tracking-widest">Book Video</span>
          </div>
          <span className="text-[10px] text-white/80 font-bold uppercase tracking-widest">
            ₦{videoFee.toLocaleString()}
          </span>
        </Button>
        <Button
          className="flex-1 h-16 rounded-2xl bg-emerald-500 hover:bg-emerald-600 flex flex-col items-center justify-center gap-1 shadow-lg shadow-emerald-500/20"
          onClick={() => router.push(`/patient/doctors/${doctorId}?book=in-person`)}
        >
          <div className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            <span className="font-black text-sm uppercase tracking-widest">Book Appointment</span>
          </div>
          <span className="text-[10px] text-white/80 font-bold uppercase tracking-widest">
            ₦{inPersonFee.toLocaleString()}
          </span>
        </Button>
      </div>
    </div>
  )
}
