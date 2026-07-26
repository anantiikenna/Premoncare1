'use client'

import { useState, useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Loader2, ArrowRight, CheckCircle2, ChevronLeft, Eye, EyeOff } from 'lucide-react'
import Link from 'next/link'
import { OTPForm } from './otp-form'
import { toast } from 'sonner'
import { getUserFacingError } from '@/lib/user-facing-errors'

type Step = 'identity' | 'terms' | 'otp' | 'success'

export function RegisterForm() {
    const [step, setStep] = useState<Step>('identity')
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [showPassword, setShowPassword] = useState(false)
    const [fullName, setFullName] = useState('')
    const [agreed, setAgreed] = useState(false)
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const router = useRouter()
    const searchParams = useSearchParams()
    const supabase = createClient()

    // Guest-to-user migration params
    const guestAppointmentId = searchParams.get('appointment_id')
    const guestEmail = searchParams.get('guest_email')

    const validatePassword = (pass: string) => {
        const minLength = 8
        const hasUpperCase = /[A-Z]/.test(pass)
        const hasLowerCase = /[a-z]/.test(pass)
        const hasNumber = /[0-9]/.test(pass)
        const hasSymbol = /[!@#$%^&*(),.?":{}|<>]/.test(pass)

        if (pass.length < minLength) return 'Password must be at least 8 characters long'
        if (!hasUpperCase || !hasLowerCase) return 'Password must contain both uppercase and lowercase letters'
        if (!hasNumber) return 'Password must contain at least one number'
        if (!hasSymbol) return 'Password must contain at least one symbol'
        return null
    }

    const handleNext = () => {
        if (step === 'identity') {
            if (!email || !password || !fullName) {
                setError('Please fill in all identity fields')
                return
            }
            const pwdError = validatePassword(password)
            if (pwdError) {
                setError(pwdError)
                return
            }
            setError(null)
            setStep('terms')
        } else if (step === 'terms') {
            if (!agreed) {
                toast.error('Please agree to the terms to continue')
                return
            }
            handleRegister()
        }
    }

    const handleBack = () => {
        if (step === 'terms') setStep('identity')
    }

    const handleRegister = async () => {
        setLoading(true)
        setError(null)

        try {
            const { data, error: authError } = await supabase.auth.signUp({
                email,
                password,
                options: {
                    data: {
                        full_name: fullName,
                        requested_role: 'patient', // Force patient role for ALL registrations
                    },
                },
            })

            if (authError) throw authError

            // If Supabase auto-confirmed (email confirmation disabled or OTP already verified),
            // user is signed in immediately — skip OTP step
            if (data.session) {
                setStep('success')
            } else {
                setStep('otp')
            }
        } catch (err: unknown) {
            console.error('Registration failed', err)
            setError(getUserFacingError(err, 'We could not complete registration. Please review your details and try again.'))
        } finally {
            setLoading(false)
        }
    }

    const handleVerifyOtp = async (otp: string) => {
        const { error: verifyError } = await supabase.auth.verifyOtp({
            email,
            token: otp,
            type: 'signup'
        })

        if (verifyError) throw verifyError
        setStep('success')
    }

    const handleResendOtp = async () => {
        const { error: resendError } = await supabase.auth.resend({
            type: 'signup',
            email
        })
        if (resendError) throw resendError
        toast.success('New code sent to your email')
    }

    if (step === 'success') {
        return (
            <Card className="w-full max-w-md glass-panel border-none shadow-2xl rounded-[3rem] p-10 text-center animate-in-fade">
                <CardHeader className="space-y-6">
                    <div className="flex justify-center">
                        <div className="h-20 w-20 rounded-3xl bg-accent/20 flex items-center justify-center text-accent">
                            <CheckCircle2 className="h-10 w-10" />
                        </div>
                    </div>
                    <CardTitle className="text-4xl font-black tracking-tighter text-gradient">Welcome Aboard</CardTitle>
                    <CardDescription className="text-sm font-bold text-muted-foreground/70 leading-relaxed uppercase tracking-widest">
                        Your identity has been verified successfully. <br />
                        Welcome to the future of healthcare.
                    </CardDescription>
                </CardHeader>
                <CardFooter className="pt-10">
                    <Button className="w-full h-16 rounded-[2rem] text-lg font-black shadow-xl shadow-primary/30" onClick={async () => {
                        // Link emergency appointment to new user if coming from guest flow
                        if (guestAppointmentId) {
                            try {
                                const { data: { user } } = await supabase.auth.getUser()
                                if (user) {
                                    await supabase
                                        .from('appointments')
                                        .update({ patient_id: user.id })
                                        .eq('id', guestAppointmentId)
                                        .is('patient_id', null)
                                    localStorage.removeItem('premon_emergency_appointment_id')
                                    localStorage.removeItem('premon_guest_token')
                                    localStorage.removeItem('premon_guest_email')
                                    localStorage.removeItem('premon_guest_phone')
                                }
                            } catch (err) {
                                console.error('Failed to link emergency appointment:', err)
                            }
                        }
                        router.push('/patient/dashboard')
                    }}>
                        Enter Dashboard
                    </Button>
                </CardFooter>
            </Card>
        )
    }

    if (step === 'otp') {
        return (
            <div className="animate-in-fade">
                <OTPForm 
                    email={email} 
                    onVerify={handleVerifyOtp} 
                    onResend={handleResendOtp} 
                />
            </div>
        )
    }

    return (
        <Card className="w-full max-w-lg glass-panel border-none shadow-2xl rounded-[3rem] overflow-hidden p-6 animate-in-fade">
            <CardHeader className="space-y-4">
                <div className="flex justify-between items-center">
                    <span className="text-[10px] font-black text-primary uppercase tracking-[0.2em] bg-primary/10 px-3 py-1 rounded-full">
                        Step {step === 'identity' ? '01' : '02'} / 02
                    </span>
                    <div className="flex gap-1">
                        <div className={`h-1.5 w-8 rounded-full transition-all ${step === 'identity' ? 'bg-primary' : 'bg-primary/20'}`} />
                        <div className={`h-1.5 w-8 rounded-full transition-all ${step === 'terms' ? 'bg-primary' : 'bg-primary/20'}`} />
                    </div>
                </div>
                <CardTitle className="text-5xl font-black tracking-tighter text-gradient pb-2">
                    {step === 'identity' ? 'Your Identity' : 'Our Terms'}
                </CardTitle>
                <CardDescription className="font-bold text-muted-foreground/60 uppercase tracking-widest text-[10px]">
                    {step === 'identity' ? 'Join the Premon Care family today' : 'Finalize your commitment'}
                </CardDescription>
            </CardHeader>

            <CardContent className="space-y-8 pt-4 min-h-75 flex flex-col">
                {error && (
                    <div className="p-4 text-[13px] bg-destructive/5 text-destructive rounded-2xl border border-destructive/10 font-bold animate-shake text-center">
                        {error}
                    </div>
                )}

                {step === 'identity' && (
                    <div className="space-y-6">
                        <div className="space-y-3">
                            <Label htmlFor="full_name" className="text-xs font-black uppercase tracking-widest ml-1">Legal Name</Label>
                            <Input
                                id="full_name"
                                placeholder="Full Name"
                                className="h-14 rounded-2xl bg-background/50 border-border/50 font-bold focus:ring-primary/20 transition-all"
                                value={fullName}
                                onChange={(e) => setFullName(e.target.value)}
                                aria-required="true"
                                aria-label="Legal Name"
                            />
                        </div>
                        <div className="space-y-3">
                            <Label htmlFor="email" className="text-xs font-black uppercase tracking-widest ml-1">Email Address</Label>
                            <Input
                                id="email"
                                type="email"
                                placeholder="name@provider.com"
                                className="h-14 rounded-2xl bg-background/50 border-border/50 font-bold focus:ring-primary/20 transition-all"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                aria-required="true"
                                aria-label="Email Address"
                            />
                        </div>
                        <div className="space-y-3">
                            <Label htmlFor="password" className="text-xs font-black uppercase tracking-widest ml-1">Password</Label>
                            <div className="relative">
                                <Input
                                    id="password"
                                    type={showPassword ? "text" : "password"}
                                    placeholder="••••••••"
                                    className="h-14 rounded-2xl bg-background/50 border-border/50 font-bold focus:ring-primary/20 transition-all pr-12"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    aria-required="true"
                                    aria-label="Secure Password"
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    className="absolute right-4 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
                                    aria-label={showPassword ? "Hide password" : "Show password"}
                                >
                                    {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                                </button>
                            </div>
                        </div>
                    </div>
                )}

                {step === 'terms' && (
                    <div className="space-y-6">
                        <div className="bg-slate-50 p-6 rounded-3xl border border-slate-100 max-h-62.5 overflow-y-auto text-xs font-medium text-slate-600 leading-relaxed custom-scrollbar" tabIndex={0} aria-label="Terms of Service, Privacy Policy, and Non-Disclosure Agreement details">
                            <p className="font-black text-slate-900 mb-2 uppercase tracking-widest">1. Commitment to Quality & Terms</p>
                            <p className="mb-4">Premoncare connects you with top-tier healthcare professionals. By using our platform, you agree to provide accurate medical information, treat practitioners with respect, and adhere to our payment policies.</p>
                            <p className="font-black text-slate-900 mb-2 uppercase tracking-widest">2. HIPAA Privacy Policy & Data Sovereignty</p>
                            <p className="mb-4">Your medical records are encrypted end-to-end (AES-256). We strictly adhere to HIPAA and local data protection regulations. We do not share your private data with third parties without explicit consent, except under critical life-saving emergency workflows.</p>
                            <p className="font-black text-slate-900 mb-2 uppercase tracking-widest">3. Reciprocal Non-Disclosure Agreement (NDA)</p>
                            <p className="mb-4">To ensure patient privacy and clinical confidentiality, you enter into a binding reciprocal NDA with the platform and your medical consultant. You agree not to record, capture, or stream any portion of your telehealth video consultations, audio calls, or chat history without direct written authorization from the platform and the practitioner.</p>
                            <p className="font-black text-slate-900 mb-2 uppercase tracking-widest">4. Payment & Refund Policies</p>
                            <p>Consultations are billed per session or minute. If any disputes arise regarding manual payment uploads, administrative mediation resolutions are final and binding.</p>
                        </div>
                        <div className="flex items-center gap-4 px-2">
                            <div 
                                onClick={() => setAgreed(!agreed)}
                                onKeyDown={(e) => {
                                    if (e.key === ' ' || e.key === 'Enter') {
                                        e.preventDefault()
                                        setAgreed(!agreed)
                                    }
                                }}
                                role="checkbox"
                                aria-checked={agreed}
                                tabIndex={0}
                                aria-label="I agree to the Terms & Conditions, HIPAA Privacy Policy, and Non-Disclosure Agreement (NDA)"
                                className={`w-8 h-8 rounded-xl border-2 flex items-center justify-center cursor-pointer transition-all focus:outline-none focus:ring-2 focus:ring-primary/40 ${agreed ? 'bg-primary border-primary text-white' : 'bg-white border-slate-200'}`}
                            >
                                {agreed && <CheckCircle2 className="h-5 w-5" />}
                            </div>
                            <span className="text-xs font-black uppercase tracking-widest text-slate-500">I agree to the Terms, HIPAA Privacy Policy & NDA</span>
                        </div>
                    </div>
                )}
            </CardContent>

            <CardFooter className="flex flex-col gap-4 pt-10 pb-6 border-t border-border/50">
                <div className="flex w-full gap-4">
                    {step !== 'identity' && (
                        <Button 
                            variant="outline" 
                            onClick={handleBack}
                            className="h-16 rounded-[2rem] px-8 font-black uppercase tracking-widest text-[10px] border-slate-100 hover:bg-slate-50"
                        >
                            <ChevronLeft className="mr-2 h-4 w-4" />
                            Back
                        </Button>
                    )}
                    <Button
                        onClick={handleNext}
                        disabled={loading}
                        className="flex-1 rounded-[2rem] h-16 bg-primary hover:bg-primary/90 font-black uppercase tracking-[0.2em] text-sm shadow-xl shadow-primary/30"
                    >
                        {loading ? <Loader2 className="h-6 w-6 animate-spin" /> : (
                            <>
                                {step === 'terms' ? 'Complete & Verify' : 'Continue'}
                                <ArrowRight className="ml-2 h-5 w-5" />
                            </>
                        )}
                    </Button>
                </div>
                {step === 'identity' && (
                    <p className="text-center text-[10px] font-black uppercase tracking-widest text-muted-foreground/40 pt-4">
                        Already part of the family? <Link href="/login" className="text-primary hover:underline">Sign In</Link>
                    </p>
                )}
            </CardFooter>
        </Card>
    )
}
