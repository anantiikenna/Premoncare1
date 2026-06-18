'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import {
    LayoutDashboard,
    Calendar,
    FileText,
    MessageSquare,
    LogOut,
    User,
    Menu,
    X,
    HeartPulse,
    Star,
    CreditCard,
    Bell,
    Pill,
    Users,
    BarChart2,
    Sparkles,
    ShieldCheck,
    ShieldAlert,
    Gavel,
    Clock
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import { NotificationBell } from './notification-bell'
import { Badge } from '@/components/ui/badge'
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog'
import { toast } from 'sonner'

interface NavItem {
    title: string
    href: string
    icon: any
    roles: string[]
}

const navItems: NavItem[] = [
    {
        title: 'Dashboard',
        href: '/dashboard', // Will be prefixed by role in the component
        icon: LayoutDashboard,
        roles: ['patient', 'doctor', 'admin']
    },
    {
        title: 'Appointments',
        href: '/appointments',
        icon: Calendar,
        roles: ['patient', 'doctor']
    },
    {
        title: 'Medical Profile',
        href: '/medical-profile',
        icon: HeartPulse,
        roles: ['patient']
    },
    {
        title: 'Health Records',
        href: '/records',
        icon: FileText,
        roles: ['patient', 'doctor']
    },
    {
        title: 'Medical Records',
        href: '/records',
        icon: FileText,
        roles: ['patient', 'doctor']
    },
    {
        title: 'Prescriptions',
        href: '/prescriptions',
        icon: Pill,
        roles: ['patient']
    },
    {
        title: 'Credits',
        href: '/credits',
        icon: CreditCard,
        roles: ['patient']
    },
    {
        title: 'Messages',
        href: '/messages',
        icon: MessageSquare,
        roles: ['patient', 'doctor']
    },
    {
        title: 'Community',
        href: '/forum',
        icon: Users, // Need to import Users? Actually Users is already in page.tsx, let's add it here.
        roles: ['patient', 'doctor', 'admin']
    },
    {
        title: 'User Management',
        href: '/users',
        icon: Users,
        roles: ['admin']
    },
    {
        title: 'Emergency Queue',
        href: '/emergency-queue',
        icon: ShieldAlert,
        roles: ['admin']
    },
    {
        title: 'Disputes',
        href: '/disputes',
        icon: Gavel,
        roles: ['admin']
    },
    {
        title: 'Audit Logs',
        href: '/audit-timeline',
        icon: FileText,
        roles: ['admin']
    },
    {
        title: 'Doctors',
        href: '/doctors',
        icon: Users,
        roles: ['admin']
    },
    {
        title: 'Financial Audit',
        href: '/payments',
        icon: CreditCard,
        roles: ['admin']
    },
    {
        title: 'P2P Monitoring',
        href: '/p2p-monitoring',
        icon: CreditCard,
        roles: ['admin']
    },
    {
        title: 'Patient Payments',
        href: '/patient-payments',
        icon: Users,
        roles: ['doctor']
    },
    {
        title: 'Prescriptions',
        href: '/prescriptions',
        icon: Pill,
        roles: ['doctor']
    },
    {
        title: 'Availability',
        href: '/schedule',
        icon: Clock,
        roles: ['doctor']
    },
    {
        title: 'Reviews',
        href: '/reviews',
        icon: Star,
        roles: ['doctor']
    },
    {
        title: 'Notifications',
        href: '/notifications',
        icon: Bell,
        roles: ['patient', 'doctor', 'admin']
    },
    {
        title: 'Reports',
        href: '/reports',
        icon: BarChart2,
        roles: ['admin']
    },
    {
        title: 'Subscription',
        href: '/subscription',
        icon: CreditCard,
        roles: ['doctor']
    },
    {
        title: 'My Patients',
        href: '/patients',
        icon: Users,
        roles: ['doctor']
    },
    {
        title: 'Subscription Mgmt',
        href: '/subscriptions',
        icon: CreditCard,
        roles: ['admin']
    },
    {
        title: 'Profile',
        href: '/profile',
        icon: User,
        roles: ['patient', 'doctor', 'admin']
    },
    {
        title: 'Settings',
        href: '/settings',
        icon: ShieldCheck,
        roles: ['admin']
    }
]

type PortalType = 'patient' | 'doctor' | 'admin'

export function DashboardLayout({
    children,
}: {
    children: React.ReactNode
}) {
    const [userId, setUserId] = useState<string | null>(null)
    const [role, setRole] = useState<PortalType | null>(null)
    const [activePortal, setActivePortal] = useState<PortalType | null>(null)
    const [profile, setProfile] = useState<any>(null)
    const [loading, setLoading] = useState(true)
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
    const pathname = usePathname()
    const router = useRouter()
    const supabase = createClient()
    const [isSwitchDialogOpen, setIsSwitchDialogOpen] = useState(false)
    const [pendingPortal, setPendingPortal] = useState<PortalType | null>(null)

    useEffect(() => {
        async function getProfile() {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) {
                router.push('/login')
                return
            }

            const { data: profileData } = await supabase
                .from('profiles')
                .select('*')
                .eq('id', user.id)
                .single()

            setUserId(user.id)
            const dbRole = (profileData?.role || 'patient') as PortalType
            setRole(dbRole)
            setProfile(profileData)
            
            // Handle Portal Persistence
            const savedPortal = localStorage.getItem(`active_portal_${user.id}`) as PortalType
            if (savedPortal && ['patient', 'doctor', 'admin'].includes(savedPortal)) {
                setActivePortal(savedPortal)
            } else {
                setActivePortal(dbRole)
            }

            setLoading(false)
        }

        getProfile()
    }, [supabase, router])

    const handleSignOut = async () => {
        if (userId) localStorage.removeItem(`active_portal_${userId}`)
        await supabase.auth.signOut()
        router.push('/login')
        router.refresh()
    }

    const togglePortal = () => {
        if (!role || !userId) return
        
        let nextPortal: PortalType = 'patient'
        
        if (role === 'admin') {
            if (activePortal === 'admin') nextPortal = 'doctor'
            else if (activePortal === 'doctor') nextPortal = 'patient'
            else nextPortal = 'admin'
        } else if (role === 'doctor') {
            nextPortal = activePortal === 'doctor' ? 'patient' : 'doctor'
        }

        // Verification Gate for Doctor Mode
        if (nextPortal === 'doctor' && role === 'doctor' && profile?.verification_status !== 'approved') {
            toast.error('Access Denied', {
                description: 'Your practitioner application is still pending or was not approved.'
            })
            return
        }

        setPendingPortal(nextPortal)
        setIsSwitchDialogOpen(true)
    }

    const confirmPortalSwitch = () => {
        if (!pendingPortal || !userId) return
        
        setActivePortal(pendingPortal)
        localStorage.setItem(`active_portal_${userId}`, pendingPortal)
        setIsSwitchDialogOpen(false)
        router.push(`/${pendingPortal}/dashboard`)
        toast.success(`Switched to ${pendingPortal.charAt(0).toUpperCase() + pendingPortal.slice(1)} Mode`)
    }

    const getSwitchLabel = () => {
        if (role === 'admin') {
            if (activePortal === 'admin') return 'Doctor'
            if (activePortal === 'doctor') return 'Patient'
            return 'Admin'
        }
        if (role === 'doctor') {
            return activePortal === 'doctor' ? 'Patient' : 'Doctor'
        }
        return 'Patient'
    }

    if (loading) {
        return (
            <div className="flex h-screen items-center justify-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
        )
    }

    const isDoctorRestricted = (item: NavItem) => {
        if (role !== 'doctor') return false
        
        // Allowed routes for unverified/unpaid doctors
        const allowedRoutes = ['/profile', '/messages', '/notifications', '/dashboard', '/subscription']
        
        const isVerified = profile?.verification_status === 'approved'
        const isSubscribed = profile?.subscription_status === 'active'
        
        if (!isVerified || !isSubscribed) {
            return !allowedRoutes.includes(item.href)
        }
        
        return false
    }

    const filteredNavItems = navItems.filter(item => {
        const hasRole = item.roles.includes(activePortal || '')
        if (!hasRole) return false
        return !isDoctorRestricted(item)
    })

    // Link Generation Logic
    const getHref = (href: string) => {
        if (href === '/dashboard' || href === '/') {
            return `/${activePortal}/dashboard`
        }
        
        // Ensure doctors in doctor mode use doctor prefix, patients/doctors-in-patient-mode use activePortal prefix
        return `/${activePortal}${href}`
    }

    return (
        <div className="flex h-screen bg-background font-sans overflow-hidden">
            {/* Sidebar for Desktop */}
            <aside className="hidden md:flex w-72 flex-col glass-panel border-r border-border/50 bg-card/30 m-4 rounded-[2.5rem] shadow-2xl relative overflow-hidden">
                <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-primary via-accent to-primary opacity-50" />
                <div className="p-8 pb-10 flex items-center gap-3 group cursor-pointer">
                    <div className="bg-primary p-2 rounded-2xl shadow-lg shadow-primary/20 rotate-3 group-hover:rotate-0 transition-transform duration-300">
                        <HeartPulse className="h-5 w-5 text-white" />
                    </div>
                    <span className="text-xl font-black tracking-tighter text-foreground">
                        Premon <span className="text-primary italic">Care</span>
                    </span>
                </div>
                
                <nav className="flex-1 overflow-y-auto px-6 py-2 space-y-2 no-scrollbar">
                    <div className="pb-4 px-2">
                        <p className="text-[10px] font-black uppercase tracking-[0.2em] text-muted-foreground/40 mb-4">Main Menu</p>
                        <div className="space-y-1">
                            {filteredNavItems.map((item) => {
                                const href = getHref(item.href)
                                const isActive = pathname === href
                                return (
                                    <Link
                                        key={item.title}
                                        href={href}
                                        className={cn(
                                            "flex items-center gap-3 px-4 py-3 rounded-2xl transition-all text-[13px] font-bold group",
                                            isActive
                                                ? "bg-primary text-primary-foreground shadow-lg shadow-primary/20"
                                                : "text-muted-foreground hover:bg-primary/5 hover:text-primary"
                                        )}
                                    >
                                        <item.icon className={cn("h-4 w-4 transition-transform group-hover:scale-110", isActive ? "text-white" : "text-muted-foreground/60")} />
                                        {item.title}
                                    </Link>
                                )
                            })}
                        </div>
                    </div>
                </nav>

                <div className="p-6 border-t border-border/50 bg-muted/5 space-y-3">
                    {(role === 'doctor' || role === 'admin') && (
                        <Button
                            variant="outline"
                            className="w-full h-12 justify-start gap-3 rounded-2xl bg-secondary/50 border-primary/10 hover:bg-primary/10 text-primary font-black text-[11px] uppercase tracking-widest shadow-sm"
                            onClick={togglePortal}
                        >
                            <Users className="h-4 w-4" />
                            Switch to {getSwitchLabel()}
                        </Button>
                    )}
                    <Button
                        variant="ghost"
                        className="w-full h-12 justify-start gap-3 rounded-2xl text-muted-foreground hover:text-destructive hover:bg-destructive/5 font-bold text-[13px]"
                        onClick={handleSignOut}
                    >
                        <LogOut className="h-4 w-4" />
                        Sign Out
                    </Button>
                </div>
            </aside>

            {/* Desktop Header & Main Content */}
            <div className="flex flex-col flex-1 overflow-hidden lg:pr-4 lg:py-4">
                {/* Desktop Header */}
                <header className="hidden md:flex h-20 items-center justify-between glass-panel px-10 shrink-0 border-none rounded-[2rem] shadow-xl mb-4 mr-4">
                    <div className="flex flex-col">
                        <span className="text-[10px] font-black uppercase tracking-[0.3em] text-primary/60">Current View</span>
                        <h2 className="text-sm font-black text-foreground tracking-tight uppercase">
                            {pathname.split('/').slice(2).join(' / ') || 'Overview'}
                        </h2>
                    </div>
                    <div className="flex items-center gap-6">
                        {activePortal !== role && (
                            <Badge variant="outline" className="bg-accent/10 text-accent-foreground border-accent/20 px-4 py-1.5 rounded-full font-black text-[10px] uppercase tracking-widest animate-in-fade">
                                <Sparkles className="h-3 w-3 mr-2" />
                                {activePortal} Mode Enabled
                            </Badge>
                        )}
                        <div className="flex items-center gap-3">
                            {userId && <NotificationBell userId={userId} />}
                            <div className="h-10 w-10 rounded-2xl bg-primary text-white flex items-center justify-center shadow-lg shadow-primary/20 border-2 border-white cursor-pointer hover:scale-105 transition-transform">
                                <User className="h-5 w-5" />
                            </div>
                        </div>
                    </div>
                </header>

                {/* Mobile Header */}
                <header className="md:hidden flex items-center justify-between p-4 glass-panel border-none relative z-[60] m-2 rounded-2xl shadow-xl">
                    <div className="flex items-center gap-3">
                        <div className="bg-primary p-2 rounded-xl">
                            <HeartPulse className="h-5 w-5 text-white" />
                        </div>
                        <span className="text-lg font-black tracking-tighter">Premon Care</span>
                    </div>
                    <Button variant="ghost" size="icon" className="rounded-xl bg-muted/30" onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}>
                        {isMobileMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
                    </Button>
                </header>

                {/* Mobile Menu Overlay */}
                {isMobileMenuOpen && (
                    <div 
                        className="md:hidden fixed inset-0 z-50 glass-panel border-none pt-28 px-8 animate-in-fade shadow-2xl flex flex-col"
                    >
                        <nav className="space-y-4 flex-1 overflow-y-auto pb-6 no-scrollbar text-foreground">
                            <p className="text-[10px] font-black uppercase tracking-[0.3em] text-primary mb-6">Navigation Hub</p>
                            {filteredNavItems.map((item) => {
                                const href = getHref(item.href)
                                const isActive = pathname === href
                                return (
                                    <Link
                                        key={item.title}
                                        href={href}
                                        onClick={() => setIsMobileMenuOpen(false)}
                                        className={cn(
                                            "flex items-center gap-5 px-6 py-4 rounded-[1.5rem] text-lg font-black tracking-tight transition-all",
                                            isActive
                                                ? "bg-primary text-primary-foreground shadow-2xl shadow-primary/30"
                                                : "text-muted-foreground hover:bg-primary/5 hover:text-primary"
                                        )}
                                    >
                                        <item.icon className={cn("h-6 w-6", isActive ? "text-white" : "text-muted-foreground/40")} />
                                        {item.title}
                                    </Link>
                                )
                            })}
                        </nav>
                        <div className="pt-4 pb-8 mt-auto border-t border-border/50 bg-background/80 backdrop-blur-md">
                            <Button
                                variant="ghost"
                                className="w-full justify-start gap-5 px-6 py-4 text-lg font-black text-destructive hover:bg-destructive/5 rounded-[1.5rem]"
                                onClick={handleSignOut}
                            >
                                <LogOut className="h-6 w-6" />
                                Sign Out
                            </Button>
                        </div>
                    </div>
                )}

                {/* Main Content Area */}
                <main className="flex-1 overflow-y-auto p-4 lg:p-0 relative no-scrollbar">
                    {/* Background Decorative Mesh for Main Area */}
                    <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-primary/5 rounded-full blur-[120px] pointer-events-none -z-10" />
                    <div className="absolute bottom-0 left-0 w-[400px] h-[400px] bg-accent/5 rounded-full blur-[100px] pointer-events-none -z-10" />
                    
                    <div className="relative animate-in-fade lg:pr-4 pb-20 lg:pb-8 h-max min-h-full">
                        {children}
                    </div>
                </main>
            </div>

            {/* Mode Switching Confirmation Dialog */}
            <Dialog open={isSwitchDialogOpen} onOpenChange={setIsSwitchDialogOpen}>
                <DialogContent className="sm:max-w-md rounded-[2.5rem] p-0 overflow-hidden border-none shadow-2xl">
                    <DialogHeader className="p-8 pb-4 bg-primary/5 border-b border-dashed">
                        <DialogTitle className="flex items-center gap-3 text-2xl font-black tracking-tight">
                            <ShieldCheck className="h-8 w-8 text-primary" /> 
                            Identity Switch
                        </DialogTitle>
                        <DialogDescription className="text-xs font-bold uppercase tracking-widest text-muted-foreground/60 leading-loose pt-2">
                            Confirm your transition to {pendingPortal} mode. <br />Your workspace will be reconfigured.
                        </DialogDescription>
                    </DialogHeader>
                    <div className="p-8 space-y-6">
                        <div className="p-6 bg-slate-50 rounded-[2rem] border border-slate-200">
                            <p className="text-sm font-bold text-slate-600 leading-relaxed">
                                You are about to switch from <span className="text-primary font-black uppercase">{activePortal}</span> to <span className="text-primary font-black uppercase">{pendingPortal}</span> view. 
                                Some active sessions might be refreshed.
                            </p>
                        </div>
                    </div>
                    <DialogFooter className="p-8 pt-0 flex flex-col sm:flex-row gap-3">
                        <Button variant="ghost" className="flex-1 h-14 rounded-2xl font-black uppercase tracking-widest text-xs" onClick={() => setIsSwitchDialogOpen(false)}>
                            Cancel
                        </Button>
                        <Button className="flex-1 h-14 rounded-2xl bg-primary hover:bg-primary/90 font-black uppercase tracking-widest text-xs shadow-xl shadow-primary/20" onClick={confirmPortalSwitch}>
                            Confirm Switch
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    )
}

