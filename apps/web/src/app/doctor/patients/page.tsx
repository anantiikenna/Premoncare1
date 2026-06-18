import { createClient } from '@/lib/supabase-server'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { 
    Users, Search, Filter, MoreHorizontal, 
    Calendar, ArrowUpRight, MessageSquare, 
    FileText, UserPlus, Star, Activity,
    ChevronRight, ListFilter
} from 'lucide-react'
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import Link from 'next/link'
import { 
    DropdownMenu, DropdownMenuContent, DropdownMenuItem, 
    DropdownMenuTrigger 
} from '@/components/ui/dropdown-menu'

export default async function MyPatientsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) return null

    // Fetch patients who have appointments with this doctor or shared records
    const { data: appointments } = await supabase
        .from('appointments')
        .select('*, patient:profiles!patient_id(full_name, avatar_url, blood_group, weight, height)')
        .eq('doctor_id', user.id)
        .order('appointment_date', { ascending: false })

    // Unique patients list
    const patientsMap = new Map()
    appointments?.forEach(apt => {
        if (!patientsMap.has(apt.patient_id)) {
            patientsMap.set(apt.patient_id, {
                ...apt.patient,
                id: apt.patient_id,
                lastVisit: apt.appointment_date,
                status: 'stable',
                adherence: '92%'
            })
        }
    })

    const patients = Array.from(patientsMap.values())

    return (
        <div className="space-y-10 pb-20 animate-in-fade">
            {/* Header Area */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div className="space-y-1">
                    <h1 className="text-4xl font-black tracking-tighter text-slate-900">
                        Patient Directory
                    </h1>
                    <p className="text-slate-500 font-medium">Manage and review your complete clinical portfolio.</p>
                </div>
                <div className="flex items-center gap-3">
                    <Button className="rounded-2xl shadow-lg shadow-primary/20 h-12 px-8 font-black uppercase tracking-widest text-[11px] gap-2">
                        <UserPlus className="h-4 w-4" />
                        Add New Case
                    </Button>
                </div>
            </div>

            {/* Portfolio Summary */}
            <div className="grid gap-6 md:grid-cols-4">
                {[
                    { label: 'Total Portfolio', val: patients.length, icon: Users, color: 'text-primary', bg: 'bg-primary/5' },
                    { label: 'Active Treatments', val: '12', icon: Activity, color: 'text-emerald-500', bg: 'bg-emerald-50' },
                    { label: 'Pending Reviews', val: '5', icon: Star, color: 'text-amber-500', bg: 'bg-amber-50' },
                    { label: 'Critical Cases', val: '0', icon: Filter, color: 'text-rose-500', bg: 'bg-rose-50' }
                ].map((stat, i) => (
                    <Card key={i} className="rounded-[2.5rem] border-slate-100 shadow-sm">
                        <CardContent className="p-8 flex items-center gap-6">
                            <div className={`${stat.bg} ${stat.color} p-4 rounded-2xl`}>
                                <stat.icon className="h-6 w-6" />
                            </div>
                            <div className="space-y-1">
                                <h3 className="text-2xl font-black tracking-tight text-slate-900">{stat.val}</h3>
                                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{stat.label}</p>
                            </div>
                        </CardContent>
                    </Card>
                ))}
            </div>

            {/* Filter & Search Bar */}
            <div className="flex items-center justify-between gap-4 bg-white p-4 rounded-[2.5rem] border border-slate-100 shadow-sm">
                <div className="flex items-center gap-2 px-2">
                    {['All Cases', 'Active', 'Stable', 'Recovered'].map((tab, i) => (
                        <Button 
                            key={i} 
                            variant={i === 0 ? "default" : "ghost"} 
                            className={`rounded-xl px-6 h-10 font-bold text-xs uppercase tracking-widest ${i === 0 ? '' : 'text-slate-500 hover:bg-slate-50'}`}
                        >
                            {tab}
                        </Button>
                    ))}
                </div>
                <div className="flex-1 max-w-sm relative group">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 group-focus-within:text-primary transition-colors" />
                    <Input className="w-full pl-11 rounded-xl bg-slate-50 border-none focus-visible:ring-1 focus-visible:ring-primary h-11" placeholder="Search by name, ID or blood type..." />
                </div>
                <Button variant="outline" size="icon" className="rounded-xl border-slate-200">
                    <ListFilter className="h-4 w-4 text-slate-500" />
                </Button>
            </div>

            {/* Patients Grid */}
            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                {patients.map((patient) => (
                    <Link key={patient.id} href={`/doctor/patients/${patient.id}`}>
                        <Card className="rounded-[3rem] border-slate-100 shadow-xl shadow-slate-200/40 hover:shadow-2xl transition-all group overflow-hidden bg-white/50 backdrop-blur-xl">
                            <CardHeader className="p-8 pb-0">
                                <div className="flex justify-between items-start">
                                    <Avatar className="h-20 w-20 rounded-[2rem] border-4 border-white shadow-xl ring-8 ring-primary/5">
                                        <AvatarImage src={patient.avatar_url} />
                                        <AvatarFallback className="text-2xl font-black">{patient.full_name?.charAt(0)}</AvatarFallback>
                                    </Avatar>
                                    <Badge className="bg-emerald-50 text-emerald-600 border-none rounded-lg px-3 py-1 font-black text-[9px] uppercase tracking-widest">
                                        {patient.status}
                                    </Badge>
                                </div>
                                <div className="mt-6 space-y-1">
                                    <h3 className="text-xl font-black text-slate-900 group-hover:text-primary transition-colors">{patient.full_name}</h3>
                                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-[0.2em]">ID: PAT-{patient.id.slice(0, 8)}</p>
                                </div>
                            </CardHeader>
                            <CardContent className="p-8 pt-6 space-y-6">
                                <div className="grid grid-cols-3 gap-4 border-y border-slate-50 py-4">
                                    <div className="text-center">
                                        <p className="text-xs font-black text-slate-900">{patient.blood_group || 'O+'}</p>
                                        <p className="text-[9px] font-bold text-slate-400 uppercase">Blood</p>
                                    </div>
                                    <div className="text-center border-x border-slate-50">
                                        <p className="text-xs font-black text-slate-900">{patient.weight || '72'}kg</p>
                                        <p className="text-[9px] font-bold text-slate-400 uppercase">Weight</p>
                                    </div>
                                    <div className="text-center">
                                        <p className="text-xs font-black text-slate-900">{patient.adherence}</p>
                                        <p className="text-[9px] font-bold text-slate-400 uppercase">Adhere</p>
                                    </div>
                                </div>
                                <div className="flex items-center justify-between">
                                    <div className="space-y-1">
                                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Last Consult</p>
                                        <p className="text-xs font-black text-slate-900 flex items-center gap-2">
                                            <Calendar className="h-3 w-3 text-primary" />
                                            {new Date(patient.lastVisit).toLocaleDateString()}
                                        </p>
                                    </div>
                                    <div className="flex gap-2">
                                        <Button variant="ghost" size="icon" className="rounded-xl h-10 w-10 hover:bg-primary/5 hover:text-primary transition-all">
                                            <MessageSquare className="h-4 w-4" />
                                        </Button>
                                        <Button variant="ghost" size="icon" className="rounded-xl h-10 w-10 hover:bg-indigo-50 hover:text-indigo-600 transition-all">
                                            <FileText className="h-4 w-4" />
                                        </Button>
                                    </div>
                                </div>
                            </CardContent>
                        </Card>
                    </Link>
                ))}
            </div>
        </div>
    )
}
