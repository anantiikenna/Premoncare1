'use client'

import { useState, useRef, useEffect } from 'react'
import { createClient } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Loader2, ArrowRight, ShieldCheck, Timer } from 'lucide-react'
import { getUserFacingError } from '@/lib/user-facing-errors'

interface OTPFormProps {
    email?: string
    onVerify: (otp: string) => Promise<void>
    onResend: () => Promise<void>
}

export function OTPForm({ email, onVerify, onResend }: OTPFormProps) {
    const [otp, setOtp] = useState<string[]>(Array(7).fill(''))
    const [loading, setLoading] = useState(false)
    const [timer, setTimer] = useState(60)
    const [error, setError] = useState<string | null>(null)
    const [focusedIndex, setFocusedIndex] = useState<number>(0)
    const [attemptsRemaining, setAttemptsRemaining] = useState<number>(5)
    const [isLocked, setIsLocked] = useState(false)
    const inputRefs = useRef<(HTMLInputElement | null)[]>([])
    const supabase = createClient()

    useEffect(() => {
        const countdown = setInterval(() => {
            setTimer((prev) => (prev > 0 ? prev - 1 : 0))
        }, 1000)
        return () => clearInterval(countdown)
    }, [])

    // Auto-focus first input on mount
    useEffect(() => {
        const timer = setTimeout(() => {
            inputRefs.current[0]?.focus()
        }, 100)
        return () => clearTimeout(timer)
    }, [])

    const focusInput = (index: number) => {
        const clamped = Math.max(0, Math.min(6, index))
        inputRefs.current[clamped]?.focus()
        setFocusedIndex(clamped)
    }

    const handleChange = (index: number, value: string) => {
        if (!/^\d*$/.test(value)) return

        const newOtp = [...otp]
        newOtp[index] = value.slice(-1)
        setOtp(newOtp)

        if (value && index < 6) {
            focusInput(index + 1)
        }

        // Auto-submit when all 7 digits filled
        const code = [...newOtp.slice(0, index), value.slice(-1), ...newOtp.slice(index + 1)].join('')
        if (code.length === 7) {
            handleSubmitWithCode(code)
        }
    }

    const handlePaste = (e: React.ClipboardEvent) => {
        e.preventDefault()
        const pasted = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 7)
        if (!pasted) return

        const newOtp = pasted.split('').concat(Array(7).fill('')).slice(0, 7)
        setOtp(newOtp)

        const lastIdx = Math.min(pasted.length, 6)
        focusInput(lastIdx)

        if (pasted.length === 7) {
            handleSubmitWithCode(pasted)
        }
    }

    const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key === 'Backspace' && !otp[index] && index > 0) {
            focusInput(index - 1)
        }
    }

    const handleSubmitWithCode = async (code: string) => {
        if (isLocked) {
            setError('Too many failed attempts. Please try again later.')
            return
        }

        setLoading(true)
        setError(null)
        try {
            await onVerify(code)
            // Reset attempts on success (non-blocking)
            if (email) {
                try { await supabase.rpc('reset_otp_attempts', { p_email: email }) } catch (_) {}
            }
        } catch (err: unknown) {
            console.error('OTP verification failed', err)
            setError(getUserFacingError(err, 'That code could not be verified. Please check it and try again.'))

            // Check rate limit after failure (non-blocking)
            if (email) {
                try {
                    const { data: limitResult } = await supabase.rpc('check_otp_rate_limit', {
                        p_email: email,
                    })
                    if (limitResult) {
                        setAttemptsRemaining(limitResult.attempts_remaining ?? 0)
                        if (!limitResult.allowed) {
                            setIsLocked(true)
                            setError('Too many failed attempts. Account temporarily locked. Please try again later.')
                        }
                    }
                } catch (_) {}
            }
        } finally {
            setLoading(false)
        }
    }

    const handleSubmit = async () => {
        const code = otp.join('')
        if (code.length < 7) {
            setError('Please enter the full 7-digit code')
            return
        }
        await handleSubmitWithCode(code)
    }

    const handleResend = async () => {
        if (timer > 0) return
        setLoading(true)
        try {
            await onResend()
            setTimer(60)
            setOtp(Array(7).fill(''))
            focusInput(0)
        } catch (err: unknown) {
            console.error('OTP resend failed', err)
            setError(getUserFacingError(err, 'We could not resend the code. Please wait a moment and try again.'))
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="w-full max-w-md mx-auto">
            <Card className="glass-panel border-none shadow-2xl rounded-3xl overflow-hidden animate-in-fade">
                <CardHeader className="space-y-4 text-center pb-2">
                    <div className="flex justify-center">
                        <div className="bg-primary/10 p-4 rounded-2xl text-primary">
                            <ShieldCheck className="h-10 w-10" />
                        </div>
                    </div>
                    <CardTitle className="text-3xl font-black tracking-tight text-gradient">
                        Verify Identity
                    </CardTitle>
                    <CardDescription className="text-sm text-muted-foreground/70 leading-relaxed">
                        Enter the 7-digit code sent to your email
                        {email && (
                            <span className="block mt-1 font-semibold text-foreground">{email}</span>
                        )}
                    </CardDescription>
                </CardHeader>

                <CardContent className="space-y-6 px-6">
                    {error && (
                        <div className="p-3 text-sm bg-destructive/10 text-destructive rounded-xl border border-destructive/20 font-semibold text-center animate-shake">
                            {error}
                        </div>
                    )}

                    {!isLocked && attemptsRemaining < 5 && (
                        <div className="text-center text-xs font-bold text-muted-foreground">
                            {attemptsRemaining} attempt{attemptsRemaining !== 1 ? 's' : ''} remaining
                        </div>
                    )}

                    {/* OTP Input Grid */}
                    <div className="flex justify-center gap-1.5 sm:gap-2">
                        {otp.map((digit, idx) => (
                            <input
                                key={idx}
                                ref={(el) => { inputRefs.current[idx] = el; }}
                                type="text"
                                inputMode="numeric"
                                autoComplete="one-time-code"
                                maxLength={1}
                                value={digit}
                                onChange={(e) => handleChange(idx, e.target.value)}
                                onKeyDown={(e) => handleKeyDown(idx, e)}
                                onPaste={idx === 0 ? handlePaste : undefined}
                                onFocus={() => setFocusedIndex(idx)}
                                className={`
                                    w-10 h-[3.25rem] sm:w-11 sm:h-[3.5rem] md:w-12 md:h-[4rem]
                                    text-center text-lg sm:text-xl font-bold
                                    rounded-xl border-2 transition-all duration-200
                                    outline-none
                                    ${digit
                                        ? 'border-primary bg-primary/5 text-foreground'
                                        : focusedIndex === idx
                                            ? 'border-primary bg-primary/5 shadow-[0_0_0_3px_rgba(15,98,254,0.1)]'
                                            : 'border-slate-200 bg-white hover:border-slate-300'
                                    }
                                `}
                            />
                        ))}
                    </div>

                    {/* Timer / Resend */}
                    <div className="flex items-center justify-center gap-2 text-sm text-muted-foreground">
                        <Timer className="h-4 w-4" />
                        {timer > 0 ? (
                            <span>
                                Resend in{' '}
                                <span className={`font-bold tabular-nums ${timer <= 10 ? 'text-destructive' : 'text-foreground'}`}>
                                    {Math.floor(timer / 60)}:{String(timer % 60).padStart(2, '0')}
                                </span>
                            </span>
                        ) : (
                            <button
                                onClick={handleResend}
                                className="text-primary font-bold hover:underline cursor-pointer"
                            >
                                Resend Code
                            </button>
                        )}
                    </div>
                </CardContent>

                <CardFooter className="px-6 pb-6 pt-2">
                    <Button
                        onClick={handleSubmit}
                        disabled={loading}
                        className="w-full h-13 rounded-2xl font-bold text-sm tracking-wide shadow-lg shadow-primary/20"
                    >
                        {loading ? (
                            <Loader2 className="h-5 w-5 animate-spin" />
                        ) : (
                            <>
                                Verify & Continue
                                <ArrowRight className="ml-2 h-4 w-4" />
                            </>
                        )}
                    </Button>
                </CardFooter>
            </Card>
        </div>
    )
}
