import { RegisterForm } from '@/components/auth/register-form'
import Link from 'next/link'
import Image from 'next/image'
import { ArrowLeft, Sparkles } from 'lucide-react'

export default function RegisterPage() {
    return (
        <div className="flex min-h-screen w-full bg-background overflow-hidden font-sans">
            {/* Left Panel: High-Impact Visual */}
            <div className="hidden lg:block flex-1 relative bg-slate-900 overflow-hidden">
                <Image 
                    src="/medical_center_interior_1775233843959.png" 
                    alt="Premon Care Center" 
                    fill 
                    className="object-cover opacity-70 scale-110 hover:scale-100 transition-all duration-1000"
                />
                <div className="absolute inset-0 bg-linear-to-r from-slate-950/40 via-transparent to-transparent" />
                <div className="absolute bottom-20 left-20 right-20 space-y-6">
                    <div className="h-1 bg-primary w-20" />
                    <h2 className="text-6xl font-black text-white leading-tight tracking-tighter">
                        The Hub of <br />
                        <span className="text-primary italic">Modern Wellness.</span>
                    </h2>
                    <p className="text-white/60 text-lg font-medium leading-relaxed max-w-sm italic">
                        "Healthcare is no longer a reactive service, but a proactive partnership." — Join 50k+ participants in the Premon Care ecosystem.
                    </p>
                </div>
            </div>

            {/* Right Panel: Branding & Form */}
            <div className="flex-1 flex flex-col items-center justify-center p-8 lg:p-12 relative overflow-y-auto">
                <Link 
                    href="/" 
                    className="absolute top-8 right-8 flex items-center gap-2 font-black text-muted-foreground/60 hover:text-primary transition-all text-xs uppercase tracking-widest glass-panel px-6 py-3 rounded-2xl border-none shadow-sm"
                >
                    <ArrowLeft className="h-4 w-4" />
                    Return to Homepage
                </Link>

                <div className="w-full max-w-lg space-y-8 animate-in-fade py-12">
                    <div className="space-y-4">
                        <div className="flex justify-center lg:justify-start">
                            <div className="relative h-16 w-16 group">
                                <div className="absolute inset-0 bg-primary/20 blur-2xl rounded-full opacity-50" />
                                <Image 
                                    src="/logo-symbol.png" 
                                    alt="Premon Care Symbol" 
                                    fill 
                                    className="object-contain relative z-10"
                                />
                            </div>
                        </div>
                        <div className="flex items-center gap-2 text-primary ml-1">
                            <Sparkles className="h-5 w-5" />
                            <span className="text-[10px] font-black uppercase tracking-[0.3em]">Neural Enrollment Active</span>
                        </div>
                    </div>
                    <RegisterForm />
                </div>

                <div className="mt-8 text-[10px] font-bold text-muted-foreground/40 uppercase tracking-widest pb-8">
                    Secure Registration Channel &middot; v4.0.2
                </div>
            </div>
        </div>
    )
}
