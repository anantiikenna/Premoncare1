'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Loader2, ArrowRight, Mail, CheckCircle2 } from 'lucide-react'
import Link from 'next/link'
import { getUserFacingError } from '@/lib/user-facing-errors'

export function ForgotPasswordForm() {
    const [email, setEmail] = useState('')
    const [loading, setLoading] = useState(false)
    const [submitted, setSubmitted] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const supabase = createClient()

    const handleResetRequest = async () => {
        if (!email) {
            setError('Please enter your email address')
            return
        }
        
        setLoading(true)
        setError(null)

        try {
            const { error: resetError } = await supabase.auth.resetPasswordForEmail(email, {
                redirectTo: `${window.location.origin}/reset-password`,
            })

            if (resetError) throw resetError

            setSubmitted(true)
        } catch (err: unknown) {
            console.error('Password reset request failed', err)
            setError(getUserFacingError(err, 'We could not send the reset link. Please try again.'))
        } finally {
            setLoading(false)
        }
    }

    if (submitted) {
        return (
            <Card className="w-full max-w-md glass-panel border-none shadow-2xl rounded-[3rem] p-10 text-center animate-in-fade">
                <CardHeader className="space-y-6">
                    <div className="flex justify-center">
                        <div className="h-20 w-20 rounded-3xl bg-accent/20 flex items-center justify-center text-accent">
                            <CheckCircle2 className="h-10 w-10" />
                        </div>
                    </div>
                    <CardTitle className="text-4xl font-black tracking-tighter text-gradient">Check Email</CardTitle>
                    <CardDescription className="text-sm font-bold text-muted-foreground/70 leading-relaxed uppercase tracking-widest leading-loose">
                        We have sent a password reset link to <br />
                        <strong className="text-foreground">{email}</strong>.
                    </CardDescription>
                </CardHeader>
                <CardFooter className="pt-10">
                    <Button className="w-full h-16 rounded-[2rem] text-lg font-black shadow-xl shadow-primary/30" asChild>
                        <Link href="/login">Back to Login</Link>
                    </Button>
                </CardFooter>
            </Card>
        )
    }

    return (
        <Card className="w-full max-w-lg glass-panel border-none shadow-2xl rounded-[3rem] overflow-hidden p-6 animate-in-fade">
            <CardHeader className="space-y-4">
                <div className="flex justify-between items-center">
                    <span className="text-[10px] font-black text-primary uppercase tracking-[0.2em] bg-primary/10 px-3 py-1 rounded-full">
                        Recovery
                    </span>
                </div>
                <CardTitle className="text-5xl font-black tracking-tighter text-gradient pb-2">
                    Forgot Password?
                </CardTitle>
                <CardDescription className="font-bold text-muted-foreground/60 uppercase tracking-widest text-[10px]">
                    No worries! Enter your email to receive a reset link
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-8 pt-4">
                {error && (
                    <div className="p-4 text-[13px] bg-destructive/5 text-destructive rounded-2xl border border-destructive/10 font-bold animate-shake text-center">
                        {error}
                    </div>
                )}

                <div className="space-y-3">
                    <Label htmlFor="email" className="text-xs font-black uppercase tracking-widest ml-1">Email Address</Label>
                    <div className="relative">
                        <Mail className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground/40" />
                        <Input
                            id="email"
                            type="email"
                            placeholder="name@provider.com"
                            className="h-14 rounded-2xl bg-background/50 border-border/50 font-bold pl-12 focus:ring-primary/20 transition-all"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                        />
                    </div>
                </div>
            </CardContent>
            <CardFooter className="flex flex-col gap-4 pt-10 pb-6">
                <Button
                    onClick={handleResetRequest}
                    disabled={loading}
                    className="w-full rounded-2xl h-14 px-8 bg-primary hover:bg-primary/90 font-black uppercase tracking-[0.2em] text-xs shadow-xl shadow-primary/30"
                >
                    {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : (
                        <>
                            Send Reset Link
                            <ArrowRight className="ml-2 h-4 w-4" />
                        </>
                    )}
                </Button>
                <Link href="/login" className="w-full">
                    <Button variant="ghost" className="w-full h-14 rounded-2xl font-black uppercase tracking-widest text-xs hover:bg-primary/5 text-muted-foreground hover:text-primary">
                        Return to Sign In
                    </Button>
                </Link>
            </CardFooter>
        </Card>
    )
}
