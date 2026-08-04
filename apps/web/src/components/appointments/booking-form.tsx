'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { createNotification } from '@/lib/queries-client'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { CheckCircle, AlertCircle, ShieldAlert, Banknote, Loader2, MessageSquare, ArrowRight, ArrowLeft, CheckCircle2, Star, StarHalf, CreditCard } from 'lucide-react'
import { Badge } from '@/components/ui/badge'

interface Doctor {
    id: string
    full_name: string
}

export function BookingForm() {
    const [step, setStep] = useState(1)
    const [doctors, setDoctors] = useState<any[]>([])
    const [loading, setLoading] = useState(false)
    const [submitting, setSubmitting] = useState(false)
    const [success, setSuccess] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [hasApprovedPayment, setHasApprovedPayment] = useState<boolean | null>(null)
    const [timeBalance, setTimeBalance] = useState<number>(0)
    const [selectedDuration, setSelectedDuration] = useState<number>(15)
    const [doctorSchedule, setDoctorSchedule] = useState<any[]>([])
    const [pricingSettings, setPricingSettings] = useState({ allowCustom: false, baseFee: 50 })
    
    // Filtering state
    const [specialties, setSpecialties] = useState<string[]>(['All'])
    const [selectedSpecialty, setSelectedSpecialty] = useState<string>('All')

    const router = useRouter()
    const supabase = createClient()

    // Form state
    const [formData, setFormData] = useState({
        doctor_id: '',
        appointment_date: '',
        reason: '',
        duration_minutes: 15
    })

    useEffect(() => {
        async function fetchInitialData() {
            setLoading(true)
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) return

            // Check payments
            const { data: payments } = await supabase
                .from('payments')
                .select('id')
                .eq('user_id', user.id)
                .eq('status', 'approved')

            setHasApprovedPayment(payments && payments.length > 0)

            // Fetch pricing settings
            const { data: settings } = await supabase
                .from('system_settings')
                .select('allow_doctor_pricing, base_consultation_fee')
                .eq('id', 'default')
                .single()

            if (settings) {
                setPricingSettings({
                    allowCustom: settings.allow_doctor_pricing,
                    baseFee: settings.base_consultation_fee || 50
                })
            }

            // Fetch ONLY verified and active doctors (with valid subscription expiry)
            const now = new Date().toISOString()
            const { data: docData } = await supabase
                .from('profiles')
                .select('id, full_name, specialty, experience_years, clinic_address, hourly_rate, consultation_fee, payment_instructions, verification_status, subscription_status, subscription_expires_at, reviews(rating)')
                .eq('role', 'doctor')
                .eq('verification_status', 'approved')
                .eq('subscription_status', 'active')
                .gt('subscription_expires_at', now) // Ensure subscription is not expired

            if (docData) {
                setDoctors(docData)
                // Extract unique specialties
                const uniqueSpecialties = Array.from(new Set(docData.map(d => d.specialty).filter(Boolean))) as string[]
                setSpecialties(['All', ...uniqueSpecialties])
            }
            setLoading(false)
        }
        fetchInitialData()
    }, [supabase])

    useEffect(() => {
        if (formData.doctor_id) {
            fetchDoctorSchedule(formData.doctor_id)
            fetchTimeBalance(formData.doctor_id)
        }
    }, [formData.doctor_id])

    async function fetchTimeBalance(docId: string) {
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) return

        const { data } = await supabase
            .from('time_balances')
            .select('minutes_remaining')
            .eq('patient_id', user.id)
            .eq('doctor_id', docId)
            .single()
        
        setTimeBalance(data?.minutes_remaining || 0)
    }

    async function fetchDoctorSchedule(docId: string) {
        setDoctorSchedule([]) // Reset when doctor changes
        const { data } = await supabase
            .from('doctor_schedules')
            .select('*')
            .eq('doctor_id', docId)
            .eq('is_available', true)
        if (data) setDoctorSchedule(data)
    }

    const handleNext = () => {
        // We no longer block at Step 1. We allow selections.
        // We will only block at the final step if payment is missing.
        setError(null)
        setStep(step + 1)
    }
    const handleBack = () => setStep(step - 1)

    const handleSubmit = async () => {
        setSubmitting(true)
        setError(null)

        try {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) throw new Error('Not authenticated')

            const { error: bookingError } = await supabase
                .from('appointments')
                .insert({
                    patient_id: user.id,
                    doctor_id: formData.doctor_id,
                    appointment_date: new Date(formData.appointment_date).toISOString(),
                    reason: formData.reason,
                    duration_minutes: formData.duration_minutes,
                    status: 'pending',
                    is_patient_approved: true,
                    is_doctor_approved: false,
                    consultation_mode: 'video',
                    total_amount: 0,
                    is_emergency: false
                })

            if (bookingError) throw bookingError

            // Notify the doctor (In-app)
            await createNotification({
                user_id: formData.doctor_id,
                title: 'New Appointment Request',
                message: 'A patient has requested a new appointment. Please review and confirm the time.',
                type: 'appointment',
                link: '/doctor/appointments'
            })

            // Notify the patient (Email with Doctor Instructions)
            try {
                const doctor = doctors.find(d => d.id === formData.doctor_id)
                const { data: patient } = await supabase.from('profiles').select('full_name').eq('id', user.id).single()
                
                await fetch('/api/notifications/email', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        type: 'bookingInstructions',
                        userId: user.id, // Recipient is the patient
                        data: {
                            doctorName: doctor?.full_name || 'Your Doctor',
                            amount: doctor?.consultation_fee || pricingSettings.baseFee,
                            instructions: doctor?.payment_instructions || 'Please contact your doctor for payment instructions.'
                        }
                    })
                })
            } catch (e) {
                console.error('Failed to trigger patient instruction email:', e)
            }

            setSuccess(true)
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : 'Failed to book appointment')
        } finally {
            setSubmitting(false)
        }
    }
    
    const filteredDoctors = selectedSpecialty === 'All' 
        ? doctors 
        : doctors.filter(d => d.specialty === selectedSpecialty)

    if (success) {
        const doctor = doctors.find(d => d.id === formData.doctor_id)
        return (
            <Card className="w-full max-w-lg mx-auto text-center border-primary/20 shadow-2xl overflow-hidden">
                <div className="bg-primary/5 p-8 border-b">
                    <CheckCircle2 className="h-16 w-16 text-primary mx-auto mb-4" />
                    <CardTitle className="text-2xl font-black">Booking Requested!</CardTitle>
                    <CardDescription className="text-base mt-2">
                        Your appointment has been successfully requested.
                    </CardDescription>
                </div>
                <CardContent className="p-8 space-y-6">
                    <div className="bg-amber-50 border border-amber-200 rounded-2xl p-6 text-left">
                        <div className="flex items-center gap-3 text-amber-800 mb-4">
                            <Banknote className="h-6 w-6" />
                            <h3 className="font-extrabold text-lg uppercase tracking-tight">Manual Payment Required</h3>
                        </div>
                        <p className="text-sm text-amber-900 leading-relaxed font-medium mb-4">
                            To secure your session with <span className="font-black text-amber-950">Dr. {doctor?.full_name}</span>, please follow the payment instructions below:
                        </p>
                        <div className="p-4 bg-white/80 rounded-xl border border-amber-100 shadow-sm font-mono text-sm whitespace-pre-wrap text-amber-950">
                            {doctor?.payment_instructions || 'Please contact the doctor for payment details.'}
                        </div>
                        <p className="text-[10px] text-amber-700 mt-4 italic font-bold">
                            💡 Once you have made the payment, the doctor will verify it and confirm your appointment.
                        </p>
                    </div>
                    
                    <div className="flex flex-col gap-3 pt-4">
                        <Button 
                            onClick={() => router.push('/patient/appointments')} 
                            className="h-12 rounded-xl font-bold bg-slate-900"
                        >
                            View Appointment Status
                        </Button>
                        <Button variant="ghost" onClick={() => router.push('/patient/dashboard')}>
                            Back to Dashboard
                        </Button>
                    </div>
                </CardContent>
            </Card>
        )
    }

    return (
        <Card className="w-full max-w-2xl mx-auto border-primary/20 shadow-xl shadow-primary/5">
            <CardHeader className="bg-primary/5 pb-8 rounded-t-2xl">
                <div className="flex justify-between items-center mb-2">
                    <CardTitle className="text-2xl font-extrabold flex items-center gap-2">
                        <CheckCircle2 className="h-6 w-6 text-primary" />
                        Book an Appointment
                    </CardTitle>
                    <Badge variant="outline" className="bg-white px-3 py-1 font-bold text-xs uppercase tracking-wider">
                        Step {step} of 3
                    </Badge>
                </div>
                <CardDescription className="text-muted-foreground font-medium">Follow the steps to schedule your session with a verified specialist.</CardDescription>
                <div className="w-full bg-accent h-3 rounded-full mt-6 overflow-hidden border border-primary/10">
                    <div
                        className="bg-primary h-full transition-all duration-500 ease-out shadow-[0_0_10px_rgba(0,219,222,0.5)]"
                        style={{ width: `${(step / 3) * 100}%` }}
                    />
                </div>
            </CardHeader>
            <CardContent className="space-y-6 pt-4">
                {error && (
                    <div className="p-3 text-sm bg-destructive/10 text-destructive rounded-md border border-destructive/20 font-medium flex items-start gap-2">
                        <AlertCircle className="h-4 w-4 mt-0.5 shrink-0" />
                        <div>
                            {error}
                        </div>
                    </div>
                )}

                {step === 1 && (
                    <div className="space-y-6">
                        {loading ? (
                            <div className="flex justify-center p-8">
                                <Loader2 className="h-8 w-8 animate-spin text-primary" />
                            </div>
                        ) : (
                            <>
                                <div className="space-y-2">
                                    <Label>Filter by Specialty</Label>
                                    <Select value={selectedSpecialty} onValueChange={setSelectedSpecialty}>
                                        <SelectTrigger className="w-full md:w-[250px]" aria-label="Filter Doctors by Medical Specialty">
                                            <SelectValue placeholder="All Specialties" />
                                        </SelectTrigger>
                                        <SelectContent>
                                            {specialties.map(spec => (
                                                <SelectItem key={spec} value={spec}>{spec}</SelectItem>
                                            ))}
                                        </SelectContent>
                                    </Select>
                                </div>

                                <div className="space-y-3">
                                    <Label>Select a Doctor</Label>
                                    {filteredDoctors.length === 0 ? (
                                        <p className="text-sm text-muted-foreground italic border rounded-md p-4 bg-accent/30 text-center">
                                            No doctors found for this specialty.
                                        </p>
                                    ) : (
                                        <div className="grid grid-cols-1 md:grid-cols-2 gap-3 max-h-[400px] overflow-y-auto p-1" role="radiogroup" aria-label="Available Doctors">
                                            {filteredDoctors.map((doctor) => (
                                                <div 
                                                    key={doctor.id}
                                                    onClick={() => setFormData({ ...formData, doctor_id: doctor.id })}
                                                    onKeyDown={(e) => {
                                                        if (e.key === 'Enter' || e.key === ' ') {
                                                            e.preventDefault();
                                                            setFormData({ ...formData, doctor_id: doctor.id });
                                                        }
                                                    }}
                                                    role="radio"
                                                    aria-checked={formData.doctor_id === doctor.id}
                                                    tabIndex={0}
                                                    aria-label={`Select Dr. ${doctor.full_name}, Specialty: ${doctor.specialty || 'General Practitioner'}, Consultation Fee: ${doctor.consultation_fee || 50} Naira`}
                                                    className={`
                                                        p-4 border rounded-lg cursor-pointer transition-all focus:outline-none focus:ring-2 focus:ring-primary
                                                        ${formData.doctor_id === doctor.id 
                                                            ? 'border-primary bg-primary/5 ring-1 ring-primary' 
                                                            : 'hover:border-primary/50 hover:bg-accent/50'}
                                                    `}
                                                >
                                                    <div className="font-semibold">Dr. {doctor.full_name}</div>
                                                    <div className="text-sm text-primary font-medium mt-1">
                                                        {doctor.specialty || 'General Practitioner'}
                                                    </div>
                                                    {doctor.experience_years && (
                                                        <div className="text-xs text-muted-foreground mt-1">
                                                            {doctor.experience_years} years experience
                                                        </div>
                                                    )}
                                                    <div className="text-xs text-muted-foreground mt-1 truncate">
                                                            {doctor.clinic_address}
                                                        </div>

                                                    <div className="flex items-center justify-between p-3 bg-primary/5 rounded-xl border border-primary/10 mt-3">
                                            <div className="flex items-center gap-2 text-primary font-bold">
                                                <Banknote className="h-4 w-4" />
                                                Consultation Fee
                                            </div>
                                            <div className="text-xl font-black">
                                                ₦{(doctor.consultation_fee || 50)}
                                            </div>
                                        </div>
                                                    
                                                    {/* Rating & Review Summary */}
                                                    <div className="flex items-center justify-between mt-3 pt-3 border-t">
                                                        <div className="flex items-center gap-2">
                                                            <div className="flex">
                                                                {[1, 2, 3, 4, 5].map((star) => {
                                                                    const ratings = doctor.reviews?.map((r: any) => r.rating) || []
                                                                    const avg = ratings.length > 0 ? ratings.reduce((a: number, b: number) => a + b, 0) / ratings.length : 0
                                                                    
                                                                    if (avg >= star) {
                                                                        return <Star key={star} className="h-3 w-3 fill-yellow-400 text-yellow-400" />
                                                                    } else if (avg >= star - 0.5) {
                                                                        return <StarHalf key={star} className="h-3 w-3 fill-yellow-400 text-yellow-400" />
                                                                    } else {
                                                                        return <Star key={star} className="h-3 w-3 text-muted-foreground" />
                                                                    }
                                                                })}
                                                            </div>
                                                            <span className="text-[10px] text-muted-foreground font-medium">
                                                                {doctor.reviews?.length || 0} reviews
                                                            </span>
                                                        </div>
                                                        <Badge variant="outline" className="text-[9px] font-bold h-5 px-2 bg-primary/5 text-primary border-primary/20">
                                                            Top Rated
                                                        </Badge>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    )}
                                </div>

                                {hasApprovedPayment === false && (
                                    <p className="text-sm text-amber-600 flex items-center gap-1 border border-amber-200 bg-amber-50 dark:bg-amber-900/10 p-3 rounded-md">
                                        <AlertCircle className="h-4 w-4 shrink-0" /> 
                                        You do not have an approved payment on file. You must add one before booking.
                                    </p>
                                )}
                            </>
                        )}
                    </div>
                )}

                {step === 2 && (
                    <div className="space-y-4">
                        <div className="space-y-2">
                            <Label htmlFor="date">Appointment Date & Time</Label>
                            <Input
                                id="date"
                                type="datetime-local"
                                required
                                value={formData.appointment_date}
                                onChange={(e) => setFormData({ ...formData, appointment_date: e.target.value })}
                                min={new Date().toISOString().slice(0, 16)}
                                aria-label="Appointment Date and Time"
                                aria-required="true"
                            />
                        </div>

                        {doctorSchedule.length > 0 && (
                            <div className="bg-accent/30 p-4 rounded-lg">
                                <p className="text-xs font-semibold mb-2 uppercase text-muted-foreground tracking-wider">Doctor Availability</p>
                                <div className="space-y-1">
                                    {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day, i) => {
                                        const slots = doctorSchedule.filter(s => s.day_of_week === i)
                                        if (slots.length === 0) return null
                                        return (
                                            <div key={day} className="text-sm flex justify-between">
                                                <span className="font-medium">{day}:</span>
                                                <span className="text-muted-foreground">
                                                    {slots.map(s => `${s.start_time.slice(0, 5)}-${s.end_time.slice(0, 5)}`).join(', ')}
                                                </span>
                                            </div>
                                        )
                                    })}
                                </div>
                            </div>
                        )}

                        <div className="space-y-4 p-4 border border-primary/20 bg-primary/5 rounded-lg">
                            <div className="space-y-2">
                                <Label>Consultation Duration</Label>
                                <Select 
                                    value={formData.duration_minutes.toString()} 
                                    onValueChange={(v) => setFormData({ ...formData, duration_minutes: parseInt(v) })}
                                >
                                    <SelectTrigger className="bg-white" aria-label="Select Consultation Duration">
                                        <SelectValue placeholder="Select duration" />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="15">15 Minutes</SelectItem>
                                        <SelectItem value="30">30 Minutes</SelectItem>
                                        <SelectItem value="45">45 Minutes</SelectItem>
                                        <SelectItem value="60">1 Hour</SelectItem>
                                    </SelectContent>
                                </Select>
                            </div>

                            <div className="flex items-center space-x-2 p-3 bg-red-50 rounded-xl border border-red-100">
                                <input 
                                    type="checkbox" 
                                    id="is_emergency" 
                                    className="h-4 w-4 text-red-600 focus:ring-red-500 border-gray-300 rounded"
                                    onChange={(e) => setFormData({ ...formData, is_emergency: e.target.checked } as any)}
                                />
                                <Label htmlFor="is_emergency" className="text-red-700 font-bold text-xs uppercase tracking-widest flex items-center gap-2">
                                    <ShieldAlert className="h-3 w-3" /> This is an Emergency (5x Rate)
                                </Label>
                            </div>

                            <div className="flex justify-between items-center pt-2">
                                <div className="space-y-0.5">
                                    <span className="text-xs font-semibold uppercase text-muted-foreground">Estimated Fee</span>
                                    <p className="text-xl font-bold text-primary">
                                        ₦{(() => {
                                            const doc = doctors.find(d => d.id === formData.doctor_id)
                                            const base = doc?.consultation_fee || pricingSettings.baseFee
                                            const multiplier = (formData as any).is_emergency ? 5 : 1
                                            return (base * multiplier).toFixed(2)
                                        })()}
                                    </p>
                                </div>
                                <div className="text-right space-y-0.5">
                                    <span className="text-xs font-semibold uppercase text-muted-foreground">Your Balance</span>
                                    <p className={`text-xl font-bold ${timeBalance >= formData.duration_minutes ? 'text-green-600' : 'text-amber-600'}`}>
                                        {timeBalance}m
                                    </p>
                                </div>
                            </div>
                            
                            {timeBalance < formData.duration_minutes && (
                                <p className="text-[10px] text-amber-600 font-medium bg-amber-50 p-2 rounded border border-amber-100">
                                    <AlertCircle className="h-3 w-3 inline mr-1" />
                                    Insufficient balance. You will be prompted to pay upfront.
                                </p>
                            )}
                        </div>
                    </div>
                )}

                {step === 3 && (
                    <div className="space-y-6">
                        <div className="space-y-2">
                            <Label htmlFor="reason">Reason for Visit</Label>
                            <Textarea
                                id="reason"
                                placeholder="Briefly describe your symptoms or reason for the appointment..."
                                value={formData.reason}
                                onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
                                rows={4}
                                className="bg-background"
                                aria-label="Reason for Visit"
                                aria-required="true"
                            />
                        </div>

                        <div className="p-5 border border-primary/20 bg-primary/5 rounded-2xl space-y-4">
                            <div className="flex items-center gap-2 text-primary font-black uppercase tracking-widest text-xs">
                                <Banknote className="h-4 w-4" />
                                Payment Notice
                            </div>
                            <p className="text-sm text-muted-foreground leading-relaxed">
                                You are booking a session with <span className="font-bold text-foreground">Dr. {doctors.find(d => d.id === formData.doctor_id)?.full_name}</span>. 
                                After clicking confirm, you will receive manual payment instructions to pay the fee directly to the doctor.
                            </p>
                            <div className="pt-2 border-t border-primary/10">
                                <div className="flex justify-between items-center">
                                    <span className="text-sm font-semibold">Total to Pay:</span>
                                    <span className="text-xl font-black text-primary">
                                        ₦{(() => {
                                            const doc = doctors.find(d => d.id === formData.doctor_id)
                                            const base = doc?.consultation_fee || pricingSettings.baseFee
                                            const multiplier = (formData as any).is_emergency ? 5 : 1
                                            return (base * multiplier).toFixed(2)
                                        })()}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                )}
            </CardContent>
            <CardFooter className="flex justify-between border-t border-accent mt-6 pt-6">
                <Button
                    variant="ghost"
                    onClick={handleBack}
                    disabled={step === 1 || submitting}
                >
                    <ArrowLeft className="mr-2 h-4 w-4" /> Back
                </Button>

                {step < 3 ? (
                    <Button
                        onClick={handleNext}
                        disabled={step === 1 ? !formData.doctor_id : !formData.appointment_date}
                    >
                        Next <ArrowRight className="ml-2 h-4 w-4" />
                    </Button>
                ) : (
                    <Button 
                        size="lg"
                        className="h-14 px-16 rounded-full font-extrabold shadow-lg transition-all bg-primary hover:bg-primary/90 text-white shadow-primary/20"
                        onClick={handleSubmit} 
                        disabled={!formData.reason || submitting}
                    >
                        {submitting ? (
                            <Loader2 className="mr-3 h-5 w-5 animate-spin" />
                        ) : (
                            <CheckCircle2 className="mr-3 h-5 w-5" />
                        )}
                        Confirm & View Payment Instructions
                    </Button>
                )}
            </CardFooter>
        </Card>
    )
}
