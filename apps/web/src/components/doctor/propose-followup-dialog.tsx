'use client'

import { useState } from 'react'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { History, Calendar, Clock, Send, Loader2 } from 'lucide-react'
import { toast } from 'sonner'
import { proposeFollowupAction } from '@/app/actions/doctor-actions'

export function ProposeFollowupDialog({ doctorProfile, patients = [], appointmentPatientId, appointmentReason }: { doctorProfile: any, patients?: { id: string, full_name: string, lastVisit?: string }[], appointmentPatientId?: string, appointmentReason?: string }) {
  const [loading, setLoading] = useState(false)
  const [open, setOpen] = useState(false)
  const [patientId, setPatientId] = useState(appointmentPatientId || '')
  const [date, setDate] = useState('')
  const [time, setTime] = useState('')
  const [reason, setReason] = useState(appointmentReason || '')
  
  const handlePropose = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    
    try {
        const result = await proposeFollowupAction({
            patientId,
            doctorId: doctorProfile.id,
            doctorName: doctorProfile.full_name,
            date,
            time,
            reason
        })
        
        if (result.success) {
            toast.success('Follow-up proposal sent to patient!')
            setOpen(false)
        } else {
            toast.error('Failed to send proposal')
        }
    } catch (error) {
        toast.error('An error occurred')
    } finally {
        setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger render={
        <button className="flex flex-col items-center gap-3 p-6 rounded-[2rem] bg-white border border-slate-100 hover:border-primary/20 hover:shadow-xl transition-all group">
          <div className="h-12 w-12 rounded-2xl bg-indigo-50 flex items-center justify-center text-indigo-600 group-hover:scale-110 transition-transform shadow-sm">
            <History className="h-6 w-6" />
          </div>
          <span className="text-[10px] font-black uppercase tracking-widest text-slate-600 text-center">Propose Follow-up</span>
        </button>
      } />
      
      <DialogContent className="max-w-md rounded-[3rem] p-0 overflow-hidden border-none shadow-2xl">
        <DialogHeader className="bg-slate-900 text-white p-10">
          <div className="flex items-center gap-4">
            <div className="h-12 w-12 rounded-2xl bg-white/10 flex items-center justify-center text-white">
              <History className="h-6 w-6" />
            </div>
            <div>
              <DialogTitle className="text-2xl font-black tracking-tight">Propose Follow-up</DialogTitle>
              <p className="text-slate-400 text-xs font-bold uppercase tracking-widest mt-1">Patient Retention & Care</p>
            </div>
          </div>
        </DialogHeader>
        
        <form onSubmit={handlePropose} className="p-10 space-y-6">
          <div className="space-y-4">
            <div className="space-y-2">
              <Label className="font-black text-[10px] uppercase tracking-widest text-slate-400">Select Patient</Label>
              <Select required onValueChange={setPatientId} value={patientId}>
                <SelectTrigger className="h-14 rounded-2xl border-slate-100 font-black">
                  <SelectValue placeholder="Search recently seen patients..." />
                </SelectTrigger>
                <SelectContent className="rounded-2xl border-slate-100">
                  {patients.length > 0 ? (
                    patients.map((p) => (
                      <SelectItem key={p.id} value={p.id} className="rounded-xl">
                        {p.full_name}{p.lastVisit ? ` (${new Date(p.lastVisit).toLocaleDateString())}` : ''}
                      </SelectItem>
                    ))
                  ) : (
                    <SelectItem value="" disabled className="rounded-xl">No recent patients found</SelectItem>
                  )}
                </SelectContent>
              </Select>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label className="font-black text-[10px] uppercase tracking-widest text-slate-400">Proposed Date</Label>
                <div className="relative">
                  <Input 
                    type="date" 
                    required 
                    className="h-14 rounded-2xl border-slate-100 font-black pl-11"
                    value={date}
                    onChange={(e) => setDate(e.target.value)}
                  />
                  <Calendar className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-primary" />
                </div>
              </div>
              <div className="space-y-2">
                <Label className="font-black text-[10px] uppercase tracking-widest text-slate-400">Preferred Time</Label>
                <div className="relative">
                  <Input 
                    type="time" 
                    required 
                    className="h-14 rounded-2xl border-slate-100 font-black pl-11"
                    value={time}
                    onChange={(e) => setTime(e.target.value)}
                  />
                  <Clock className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-primary" />
                </div>
              </div>
            </div>

            <div className="space-y-2">
              <Label className="font-black text-[10px] uppercase tracking-widest text-slate-400">Clinical Reason / Instructions</Label>
              <Textarea 
                placeholder="Explain why this follow-up is necessary (e.g., Post-surgical review, Lab results discussion)..."
                className="min-h-[120px] rounded-[1.5rem] border-slate-100 font-medium p-4"
                required
                value={reason}
                onChange={(e) => setReason(e.target.value)}
              />
            </div>
          </div>

          <div className="pt-4 flex flex-col gap-4">
            <Button 
              type="submit" 
              className="w-full h-16 rounded-[1.5rem] bg-primary hover:bg-primary/90 text-white font-black uppercase tracking-widest text-xs shadow-xl shadow-primary/20"
              disabled={loading}
            >
              {loading ? <Loader2 className="h-5 w-5 animate-spin mr-3" /> : <Send className="h-5 w-5 mr-3" />}
              Send Proposal to Patient
            </Button>
            <p className="text-[9px] font-bold text-slate-400 text-center uppercase tracking-wider italic leading-relaxed">
              *The patient will receive a notification to confirm an