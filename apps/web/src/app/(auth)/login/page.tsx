import { LoginForm } from '@/components/auth/login-form'
import Link from 'next/link'
import Image from 'next/image'
import { ArrowLeft, ShieldCheck } from 'lucide-react'

export default function LoginPage() {
    return (
        <div className="flex min-h-screen w-full bg-background overflow-hidden font-sans">
            {/* Left Panel: Branding & Form */}
            <div className="flex-1 flex flex-col items-center justify-center p-8 lg:p-20 relative">
                <Link 
                    href="/" 
                    className="absolute top-8 left-8 flex items-center gap-2 font-black text-muted-foreground/60 hover:text-primary transition-all text-xs uppercase tracking-widest glass-panel px-6 py-3 rounded-2xl border-none shadow-sm"
                >
                    <ArrowLeft className="h-4 w-4" />
                    Return to Homepage
                </Link>

                <div className="w-full max-w-md space-y-8 animate-in-fade">
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
                        <div className="flex items-center gap-2 text-primary">
                            <ShieldCheck className="h-5 w-5" />
                            <span className="text-[10px] font-black uppercase tracking-[0.3em]">Secure Verification Protocol</span>
                        </div>
                    </div>
                    <LoginForm />
                </div>

                <div className="absolute bottom-8 text-[10px] font-bold text-muted-foreground/40 uppercase tracking-widest">
                    &copy; 2026 Premon Care &middot; Encryption Active
                </div>
            </div>

            {/* Right Panel: High-Impact Visual */}
            <div className="hidden lg:block flex-1 relative bg-slate-900 overflow-hidden">
                <Image 
                    src="/adv_health_screening_1775233986455.png" 
                    alt="Premon Care Advanced Tech" 
                    fill 
                    className="object-cover opacity-80 mix-blend-luminosity hover:mix-blend-normal transition-all duration-1000 scale-105 hover:scale-100"
                />
                <div className="absolute inset-0 bg-linear-to-t from-slate-950 via-transparent to-transparent" />
                <div className="absolute bottom-20 left-20 right-20 space-y-6">
                    <h2 className="text-5xl font-black text-white leading-tight tracking-tighter">
                        The Edge of <br />
                        <span className="text-primary italic">Precision Medicine.</span>
                    </h2>
                    <p className="text-white/60 text-lg font-medium leading-relaxed max-w-md">
                        Our neural diagnostic protocols ensure that your health analysis is as unique as your genome. Welcome to the next generation of care.
                    </p>
                </div>
            </div>
        </div>
    )
}
