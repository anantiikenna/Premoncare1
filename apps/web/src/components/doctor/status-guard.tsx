'use client'

import { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { CheckCircle, AlertCircle, ShieldAlert, DollarSign, Loader2, MessageSquare, ArrowRight } from 'lucide-react'
import { createClient } from '@/lib/supabase'
import { toast } from 'sonner'
import Link from 'next/link'
import { useRouter } from 'next/navigation'

interface DoctorStatusGuardProps {
    profile: any
    children: React.ReactNode
}

export function DoctorStatusGuard({ profile, children }: DoctorStatusGuardProps) {
    const [loading, setLoading] = useState(false)
    const [durationMonths, setDurationMonths] = useState(1)
    const supabase = createClient()
    const router = useRouter()

    const isVerified = profile?.verification_status === 'approved'
    const isSubscribed = profile?.subscription_status === 'active'
    const hasProposedFee = profile?.fee_status === 'awaiting_doctor_approval'
    const negotiatedFee = profile?.negotiated_fee

    const handleProceedToPayment = async () => {
        const totalAmount = (negotiatedFee * durationMonths).toFixed(2)
        // Redirect to payment dashboard with the total amount and duration
        router.push(`/patient/payments?amount=${totalAmount}&duration=${durationMonths}&type=subscription`)
    }

    // 1. Not Verified
    if (!isVerified) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[70vh] p-8 text-center animate-in fade-in zoom-in duration-500">
                <div className="relative mb-8">
                    <div className="absolute inset-0 bg-primary/20 blur-3xl rounded-full scale-150 animate-pulse" />
                    <div className="relative bg-white dark:bg-slate-900 p-8 rounded-3xl shadow-2xl border border-primary/10">
                        <ShieldAlert className="h-16 w-16 text-primary" />
                    </div>
                </div>
                
                <h2 className="text-4xl font-black text-slate-900 dark:text-white mb-4 tracking-tight">Professional Verification</h2>
                <div className="flex items-center gap-2 justify-center mb-6">
                    <Badge variant="secondary" className="bg-amber-100 text-amber-700 hover:bg-amber-100 border-amber-200 px-4 py-1 rounded-full text-sm font-bold animate-bounce">
                        Action Required: Document Review
                    </Badge>
                </div>
                
                <p className="text-slate-600 dark:text-slate-400 max-w-xl mb-10 text-lg leading-relaxed">
                    Our medical board is currently reviewing your professional credentials. To maintain high healthcare standards, this manual process typically takes 24-48 hours.
                </p>
                
                <div className="grid gap-4 w-full max-w-md">
                    <div className="grid grid-cols-2 gap-4">
                        <Link href="/doctor/profile" className="w-full">
                            <Button variant="outline" className="w-full rounded-2xl h-14 font-bold shadow-sm transition-all hover:bg-primary hover:text-white hover:border-primary">
                                Edit Profile
                            </Button>
                        </Link>
                        <Link href="/doctor/messages" className="w-full">
                            <Button variant="ghost" className="w-full rounded-2xl h-14 flex items-center justify-center gap-2 font-bold hover:bg-slate-100">
                                <MessageSquare className="h-5 w-5" />
                                Support
                            </Button>
                        </Link>
                    </div>
                    <div className="p-4 bg-slate-50 dark:bg-slate-800/50 rounded-2xl border border-slate-200 dark:border-slate-800 text-xs text-slate-500 text-left">
                        <p className="font-bold mb-1 flex items-center gap-1.5"><AlertCircle className="h-3 w-3" /> Note to Candidates</p>
                        Verification is a one-time process. Once approved, you can toggle between Patient and Doctor portals immediately.
                    </div>
                </div>
            </div>
        )
    }

    // 2. Verified but Unsubscribed (Locked Features)
    if (!isSubscribed) {
        return (
            <div className="max-w-5xl mx-auto space-y-10 py-12 animate-in fade-in slide-in-from-bottom-4 duration-700">
                <header className="text-center space-y-3">
                    <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-green-50 text-green-700 border border-green-200 text-sm font-bold mb-2">
                        <CheckCircle className="h-4 w-4" /> Professional Credentials Verified
                    </div>
                    <h1 className="text-4xl font-black text-slate-900 dark:text-white tracking-tight">Activate Practitioner Dashboard</h1>
                    <p className="text-slate-500 text-lg max-w-2xl mx-auto">
                        Your documents are approved. Finalize your platform agreement to unlock patient bookings and scheduling tools.
                    </p>
                </header>

                <div className="grid lg:grid-cols-3 gap-8">
                    <Card className="lg:col-span-2 border-primary/20 shadow-2xl shadow-primary/5 overflow-hidden rounded-3xl">
                        <CardHeader className="bg-slate-50 dark:bg-slate-900 border-b p-8">
                            <div className="flex items-center justify-between">
                                <div className="space-y-1">
                                    <CardTitle className="text-2xl font-black">Subscription Setup</CardTitle>
                                    <CardDescription>Select your preferred billing cycle.</CardDescription>
                                </div>
                                <div className="p-3 bg-primary/10 rounded-2xl">
                                    <DollarSign className="h-6 w-6 text-primary" />
                                </div>
                            </div>
                        </CardHeader>
                        <CardContent className="p-8 space-y-8">
                            {!hasProposedFee && !negotiatedFee ? (
                                <div className="text-center py-12 space-y-6">
                                    <div className="bg-primary/5 p-8 rounded-full w-24 h-24 flex items-center justify-center mx-auto ring-8 ring-primary/5">
                                        <MessageSquare className="h-10 w-10 text-primary" />
                                    </div>
                                    <div className="space-y-2">
                                        <h3 className="text-xl font-bold text-slate-900">Negotiation in Progress</h3>
                                        <p className="text-slate-500 max-w-sm mx-auto">
                                            Please message the platform administrator to agree on your personalized monthly platform fee.
                                        </p>
                                    </div>
                                    <Link href="/doctor/messages">
                                        <Button className="rounded-2xl h-14 px-10 bg-primary hover:bg-primary/90 shadow-xl shadow-primary/20 font-bold text-lg group">
                                            Open Negotiation Chat
                                            <ArrowRight className="ml-2 h-5 w-5 transition-transform group-hover:translate-x-1" />
                                        </Button>
                                    </Link>
                                </div>
                            ) : (
                                <div className="space-y-8 animate-in fade-in duration-500">
                                    <div className="bg-primary/5 p-8 rounded-3xl border border-primary/10 text-center relative overflow-hidden group">
                                        <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
                                            <ShieldAlert className="h-24 w-24 -rotate-12" />
                                        </div>
                                        <p className="text-xs text-primary uppercase tracking-[0.2em] font-black mb-2">Current Negotiated Fee</p>
                                        <div className="text-6xl font-black text-slate-900 dark:text-white tracking-tighter">
                                            ₦{negotiatedFee}<span className="text-xl font-medium text-slate-400 tracking-normal">/mo</span>
                                        </div>
                                        <div className="mt-4 flex justify-center">
                                            <Badge variant="secondary" className="bg-white dark:bg-slate-800 shadow-sm border px-3">Standard Practitioner Agreement</Badge>
                                        </div>
                                    </div>

                                    <div className="space-y-4">
                                        <div className="flex items-center justify-between">
                                            <h4 className="font-bold text-slate-700">Duration Selection</h4>
                                            <span className="text-xs text-slate-400 font-medium">Automatic renewal enabled</span>
                                        </div>
                                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                                            {[1, 3, 6, 12].map(m => (
                                                <button
                                                    key={m}
                                                    onClick={() => setDurationMonths(m)}
                                                    className={`relative p-5 rounded-2xl border-2 transition-all group ${
                                                        durationMonths === m 
                                                        ? 'border-primary bg-primary/5 ring-4 ring-primary/5' 
                                                        : 'border-slate-100 hover:border-slate-200 bg-white'
                                                    }`}
                                                >
                                                    <div className={`text-sm font-black mb-1 ${durationMonths === m ? 'text-primary' : 'text-slate-600'}`}>
                                                        {m === 12 ? '1 Year' : `${m} Month${m > 1 ? 's' : ''}`}
                                                    </div>
                                                    <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">
                                                        ₦{(negotiatedFee * m).toFixed(0)}
                                                    </div>
                                                    {m >= 6 && (
                                                        <Badge className="absolute -top-2 -right-2 bg-green-500 hover:bg-green-600 text-[9px] h-4">Value</Badge>
                                                    )}
                                                </button>
                                            ))}
                                        </div>
                                    </div>
                                    
                                    <div className="p-6 bg-slate-900 rounded-3xl text-white shadow-xl shadow-slate-900/10">
                                        <div className="flex items-center justify-between mb-4 border-b border-white/10 pb-4">
                                            <span className="text-slate-400 font-medium">Selected Plan:</span>
                                            <span className="font-bold">{durationMonths} Month{durationMonths > 1 ? 's' : ''} Access</span>
                                        </div>
                                        <div className="flex items-center justify-between">
                                            <div className="space-y-0.5">
                                                <span className="text-slate-400 text-sm font-medium">Total Activation Fee:</span>
                                                <div className="text-3xl font-black">₦{(negotiatedFee * durationMonths).toFixed(2)}</div>
                                            </div>
                                            <Button 
                                                className="h-16 px-8 rounded-2xl bg-primary hover:bg-primary/90 text-white font-black text-lg group shadow-2xl shadow-primary/40 transition-all hover:scale-[1.02]"
                                                onClick={handleProceedToPayment}
                                                disabled={loading}
                                            >
                                                {loading ? <Loader2 className="h-6 w-6 animate-spin" /> : (
                                                    <>
                                                        Pay & Activate
                                                        <ArrowRight className="ml-2 h-5 w-5 transition-transform group-hover:translate-x-1" />
                                                    </>
                                                )}
                                            </Button>
                                        </div>
                                    </div>
                                </div>
                            )}
                        </CardContent>
                    </Card>

                    <div className="space-y-6">
                        <Card className="border-0 bg-slate-50 dark:bg-slate-900/50 rounded-3xl p-6">
                            <h3 className="font-bold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
                                <ShieldAlert className="h-5 w-5 text-primary" /> Professional Policy
                            </h3>
                            <ul className="space-y-4">
                                <li className="flex gap-3">
                                    <div className="mt-1 bg-primary/20 p-1 rounded-full h-fit"><CheckCircle className="h-3 w-3 text-primary" /></div>
                                    <p className="text-sm text-slate-600 leading-relaxed font-medium">Verified practitioners agree to 99% uptime availability for confirmed appointments.</p>
                                </li>
                                <li className="flex gap-3">
                                    <div className="mt-1 bg-primary/20 p-1 rounded-full h-fit"><CheckCircle className="h-3 w-3 text-primary" /></div>
                                    <p className="text-sm text-slate-600 leading-relaxed font-medium">Platform fees are non-refundable and are used for medical infrastructure maintenance.</p>
                                </li>
                            </ul>
                        </Card>

                        <div className="p-8 rounded-3xl border-2 border-dashed border-slate-200 text-center space-y-4">
                            <div className="bg-white p-4 rounded-2xl shadow-sm border w-fit mx-auto">
                                <MessageSquare className="h-6 w-6 text-slate-400" />
                            </div>
                            <div className="space-y-1">
                                <h4 className="font-bold text-slate-900">Custom Agreement?</h4>
                                <p className="text-xs text-slate-500 leading-relaxed">Reach out if you need a specialized clinic or hospital-wide subscription model.</p>
                            </div>
                            <Link href="/doctor/messages" className="block">
                                <Button variant="link" className="text-primary font-bold">Contact Administration</Button>
                            </Link>
                        </div>
                    </div>
                </div>
            </div>
        )
    }

    return <>{children}</>
}
