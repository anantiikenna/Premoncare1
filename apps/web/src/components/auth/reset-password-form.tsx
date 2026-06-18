'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Loader2, ArrowRight, Lock, CheckCircle2, XCircle } from 'lucide-react'
import { toast } from 'sonner'
import { getUserFacingError } from '@/lib/user-facing-errors'

export function ResetPasswordForm() {
    const [password, setPassword] = useState('')
    const [confirmPassword, setConfirmPassword] = useState('')
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const router = useRouter()
    const supabase = createClient()

    // Password requirements
    const requirements = [
        { label: 'At least 8 characters', test: (p: string) => p.length >= 8 },
        { label: 'One uppercase letter', test: (p: string) => /[A-Z]/.test(p) },
        { label: 'One lowercase letter', test: (p: string) => /[a-z]/.test(p) },
        { label: 'One number', test: (p: string) => /[0-9]/.test(p) },
        { label: 'One special character', test: (p: string) => /[!@#$%^&*(),.?":{}|<>]/.test(p) },
    ]

    const handleReset = async () => {
        if (!password || !confirmPassword) {
            setError('Please fill in all fields')
            return
        }

        if (password !== confirmPassword) {
            setError('Passwords do not match')
            return
        }

        const failedReqs = requirements.filter(r => !r.test(password))
        if (failedReqs.length > 0) {
            setError('Please meet all password requirements')
            return
        }
        
        setLoading(true)
        setError(null)

        try {
            const { error: resetError } = await supabase.auth.updateUser({
                password: password
            })

            if (resetError) throw resetError

            toast.success('Password updated successfully')
            router.push('/login')
        } catch (err: unknown) {
            console.error('Password update failed', err)
            setError(getUserFacingError(err, 'We could not update your password. Please try again.'))
        } finally {
            setLoading(false)
        }
    }

    return (
        <Card className="w-full max-w-lg glass-panel border-none shadow-2xl rounded-[3rem] overflow-hidden p-6 animate-in-fade">
            <CardHeader className="space-y-4">
                <div className="flex justify-between items-center">
                    <span className="text-[10px] font-black text-primary uppercase tracking-[0.2em] bg-primary/10 px-3 py-1 rounded-full">
                        Secure Reset
                    </span>
                </div>
                <CardTitle className="text-5xl font-black tracking-tighter text-gradient pb-2">
                    New Password
                </CardTitle>
                <CardDescription className="font-bold text-muted-foreground/60 uppercase tracking-widest text-[10px]">
                    Create a strong, unique password for your account
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-8 pt-4">
                {error && (
                    <div className="p-4 text-[13px] bg-destructive/5 text-destructive rounded-2xl border border-destructive/10 font-bold animate-shake text-center">
                        {error}
                    </div>
                )}

                <div className="space-y-6">
                    <div className="space-y-3">
                        <Label htmlFor="password" className="text-xs font-black uppercase tracking-widest ml-1">New Password</Label>
                        <div className="relative">
                            <Lock className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground/40" />
                            <Input
                                id="password"
                                type="password"
                                placeholder="••••••••"
                                className="h-14 rounded-2xl bg-background/50 border-border/50 font-bold pl-12 focus:ring-primary/20 transition-all"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                            />
                        </div>
                        
                        {/* Strength Indicator */}
                        <div className="grid grid-cols-1 gap-2 pt-2">
                            {requirements.map((req, idx) => (
                                <div key={idx} className="flex items-center gap-2">
                                    {req.test(password) ? (
                                        <CheckCircle2 className="h-3 w-3 text-green-500" />
                                    ) : (
                                        <XCircle className="h-3 w-3 text-muted-foreground/20" />
                                    )}
                                    <span className={`text-[10px] font-bold uppercase tracking-wider ${req.test(password) ? 'text-green-600' : 'text-muted-foreground/40'}`}>
                                        {req.label}
                                    </span>
                                </div>
                            ))}
                        </div>
                    </div>

                    <div className="space-y-3">
                        <Label htmlFor="confirmPassword" className="text-xs font-black uppercase tracking-widest ml-1">Confirm Password</Label>
                        <div className="relative">
                            <Lock className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground/40" />
                            <Input
                                id="confirmPassword"
                                type="password"
                                placeholder="••••••••"
                                className="h-14 rounded-2xl bg-background/50 border-border/50 font-bold pl-12 focus:ring-primary/20 transition-all"
                                value={confirmPassword}
                                onChange={(e) => setConfirmPassword(e.target.value)}
                            />
                        </div>
                    </div>
                </div>
            </CardContent>
            <CardFooter className="pt-10 pb-6">
                <Button
                    onClick={handleReset}
                    disabled={loading}
                    className="w-full rounded-2xl h-14 px-8 bg-primary hover:bg-primary/90 font-black uppercase tracking-[0.2em] text-xs shadow-xl shadow-primary/30"
                >
                    {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : (
                        <>
                            Update Password
                            <ArrowRight className="ml-2 h-4 w-4" />
                        </>
                    )}
                </Button>
            </CardFooter>
        </Card>
    )
}
