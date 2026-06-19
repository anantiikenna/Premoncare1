'use client'

import { useState, useRef, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Loader2, ArrowRight, ShieldCheck, Timer } from 'lucide-react'
import { getUserFacingError } from '@/lib/user-facing-errors'

interface OTPFormProps {
    email?: string
    onVerify: (otp: string) => Promise<void>
    onResend: () => Promise<void>
}

export function OTPForm({ email, onVerify, onResend }: OTPFormProps) {
    const [otp, setOtp] = useState(['', '', '', '', '', '', '', ''])
    const [loading, setLoading] = useState(false)
    const [timer, setTimer] = useState(60)
    const [error, setError] = useState<string | null>(null)
    const inputRefs = useRef<(HTMLInputElement | null)[]>([])

    useEffect(() => {
        const countdown = setInterval(() => {
            setTimer((prev) => (prev > 0 ? prev - 1 : 0))
        }, 1000)
        return () => clearInterval(countdown)
    }, [])

    // Auto-focus first input on mount
    useEffect(() => {
        inputRefs.current[0]?.focus()
    }, [])

    const handleChange = (index: number, value: string) => {
        if (!/^\d*$/.test(value)) return
        
        const newOtp = [...otp]
        newOtp[index] = value.slice(-1)
        setOtp(newOtp)

        // Move to next input
        if (value && index < 7) {
            inputRefs.current[index + 1]?.focus()
        }

        // Auto-submit when all 8 digits filled
        const code = [...newOtp.slice(0, index), value.slice(-1), ...newOtp.slice(index + 1)].join('')
        if (code.length === 8) {
            handleSubmitWithCode(code)
        }
    }

    const handlePaste = (e: React.ClipboardEvent) => {
        e.preventDefault()
        const pasted = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 8)
        if (!pasted) return

        const newOtp = pasted.split('').concat(Array(8).fill('')).slice(0, 8)
        setOtp(newOtp)

        // Focus last filled input
        const lastIdx = Math.min(pasted.length, 7)
        inputRefs.current[lastIdx]?.focus()

        // Auto-submit if full code pasted
        if (pasted.length === 8) {
            handleSubmitWithCode(pasted)
        }
    }

    const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key === 'Backspace' && !otp[index] && index > 0) {
            inputRefs.current[index - 1]?.focus()
        }
    }

    const handleSubmitWithCode = async (code: string) => {
        setLoading(true)
        setError(null)
        try {
            await onVerify(code)
        } catch (err: unknown) {
            console.error('OTP verification failed', err)
            setError(getUserFacingError(err, 'That code could not be verified. Please check it and try again.'))
        } finally {
            setLoading(false)
        }
    }

    const handleSubmit = async () => {
        const code = otp.join('')
        if (code.length < 8) {
            setError('Please enter the full 8-digit code')
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
            setOtp(['', '', '', '', '', '', '', ''])
            inputRefs.current[0]?.focus()
        } catch (err: unknown) {
            console.error('OTP resend failed', err)
            setError(getUserFacingError(err, 'We could not resend the code. Please wait a moment and try again.'))
        } finally {
            setLoading(false)
        }
    }

    return (
        <Card className="w-full max-w-lg glass-panel border-none shadow-2xl rounded-[3rem] overflow-hidden p-6 animate-in-fade">
            <CardHeader className="space-y-4 text-center">
                <div className="flex justify-center">
                    <div className="bg-primary/10 p-4 rounded-3xl text-primary">
                        <ShieldCheck className="h-10 w-10" />
                    </div>
                </div>
                <CardTitle className="text-4xl font-black tracking-tighter text-gradient pb-2">
                    Verify Identity
                </CardTitle>
                <CardDescription className="font-bold text-muted-foreground/60 uppercase tracking-widest text-[10px]">
                    Enter the 8-digit code sent to your email {email && <><br /><strong className="text-foreground">{email}</strong></>}
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-8 pt-4">
                {error && (
                    <div className="p-4 text-[13px] bg-destructive/5 text-destructive rounded-2xl border border-destructive/10 font-bold animate-shake text-center">
                        {error}
                    </div>
                )}

                <div className="flex justify-center gap-2 sm:gap-4">
                    {otp.map((digit, idx) => (
                        <Input
                            key={idx}
                            ref={(el) => { inputRefs.current[idx] = el; }}
                            type="text"
                            inputMode="numeric"
                            maxLength={1}
                            className="w-10 h-14 sm:w-14 sm:h-20 text-center text-2xl font-black rounded-2xl bg-background/50 border-border/50 focus:ring-primary/20 transition-all p-0"
                            value={digit}
                            onChange={(e) => handleChange(idx, e.target.value)}
                            onKeyDown={(e) => handleKeyDown(idx, e)}
                            onPaste={idx === 0 ? handlePaste : undefined}
                        />
                    ))}
                </div>

                <div className="flex flex-col items-center gap-4">
                    <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-widest text-muted-foreground/60">
                        <Timer className="h-4 w-4" />
                        {timer > 0 ? (
                            <span>Resend in {timer}s</span>
                        ) : (
                            <Button 
                                variant="link" 
                                className="h-auto p-0 text-primary text-xs font-black uppercase tracking-widest"
                                onClick={handleResend}
                            >
                                Resend Code
                            </Button>
                        )}
                    </div>
                </div>
            </CardContent>
            <CardFooter className="pt-6 pb-6">
                <Button
                    onClick={handleSubmit}
                    disabled={loading}
                    className="w-full rounded-[2rem] h-16 bg-primary hover:bg-primary/90 font-black uppercase tracking-[0.2em] text-sm shadow-xl shadow-primary/30"
                >
                    {loading ? <Loader2 className="h-6 w-6 animate-spin" /> : (
                        <>
                            Verify & Continue
                            <ArrowRight className="ml-2 h-5 w-5" />
                        </>
                    )}
                </Button>
            </CardFooter>
        </Card>
    )
}
