import { createClient } from '@/lib/supabase-server'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { 
    Users, Calendar, Clock, Activity, 
    FileText, Beaker, Pill, ShieldCheck,
    ArrowLeft, ChevronRight, MoreHorizontal,
    Plus, Download, ExternalLink, MessageSquare,
    Stethoscope, TrendingUp, TrendingDown, Heart,
    Thermometer, Weight
} from 'lucide-react'
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from '@/components/ui/badge'
import Link from 'next/link'
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

export default async function PatientDetailsPage({ params }: { params: { id: string } }) {
    const supabase = await createClient()
    const { id } = params

    // Fetch patient profile
    const { data: patient } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', id)
        .single()

    // Fetch medical records shared with this doctor
    const { data: records } = await supabase
        .from('medical_records')
        .select('*')
        .eq('patient_id', id)
        .order('created_at', { ascending: false })

    // Fetch appointment history
    const { data: appointments } = await supabase
        .from('appointments')
        .select('*')
        .eq('patient_id', id)
        .order('appointment_date', { ascending: false })

    if (!patient) return null

    return (
        <div className="space-y-10 pb-20 animate-in-fade">
            {/* Breadcrumbs & Header */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div className="space-y-4">
                    <Link href="/doctor/patients" className="flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-widest hover:text-primary transition-colors">
                        <ArrowLeft className="h-3 w-3" /> Back to Directory
                    </Link>
                    <div className="flex items-center gap-6">
                        <Avatar className="h-24 w-24 rounded-[2rem] border-4 border-white shadow-2xl ring-8 ring-primary/5">
                            <AvatarImage src={patient.avatar_url} />
                            <AvatarFallback className="text-3xl font-black">{patient.full_name?.charAt(0)}</AvatarFallback>
                        </Avatar>
                        <div className="space-y-1">
                            <div className="flex items-center gap-3">
                                <h1 className="text-4xl font-black tracking-tighter text-slate-900">{patient.full_name}</h1>
                                <Badge className="bg-emerald-50 text-emerald-600 border-none rounded-full px-3 py-1 text-[10px] font-black uppercase tracking-widest">Stable</Badge>
                            </div>
                            <p className="text-slate-500 font-medium flex items-center gap-4">
                                <span>ID: PAT-{patient.id.slice(0, 8)}</span>
                                <span className="h-1 w-1 rounded-full bg-slate-300" />
                                <span>{patient.blood_group || 'Not set'}</span>
                                <span className="h-1 w-1 rounded-full bg-slate-300" />
                                <span>{patient.weight || '72'}kg • {patient.height || '178'}cm</span>
                            </p>
                        </div>
                    </div>
                </div>
                <div className="flex items-center gap-3">
                    <Button variant="outline" className="rounded-2xl border-slate-200 h-12 px-6 font-black uppercase tracking-widest text-[11px] gap-2">
                        <MessageSquare className="h-4 w-4" /> Message
                    </Button>
                    <Button className="rounded-2xl shadow-lg shadow-primary/20 h-12 px-8 font-black uppercase tracking-widest text-[11px] gap-2">
                        <Plus className="h-4 w-4" /> New Consultation
                    </Button>
                </div>
            </div>

            {/* Vital Signs Grid */}
            <div className="grid gap-6 md:grid-cols-4">
                {[
                    { label: 'Heart Rate', val: '72 bpm', icon: Heart, color: 'text-rose-500', bg: 'bg-rose-50', trend: 'Normal', trendIcon: TrendingUp },
                    { label: 'Blood Pressure', val: '120/80', icon: Activity, color: 'text-primary', bg: 'bg-primary/5', trend: 'Optimal', trendIcon: ShieldCheck },
                    { label: 'Temperature', val: '36.6 °C', icon: Thermometer, color: 'text-orange-500', bg: 'bg-orange-50', trend: 'Stable', trendIcon: TrendingDown },
                    { label: 'Body Weight', val: `${patient.weight || '72'} kg`, icon: Weight, color: 'text-emerald-500', bg: 'bg-emerald-50', trend: '-2kg', trendIcon: TrendingDown }
                ].map((vital, i) => (
                    <Card key={i} className="rounded-[2.5rem] border-slate-100 shadow-sm overflow-hidden bg-white/50 backdrop-blur-xl">
                        <CardContent className="p-8 space-y-4">
                            <div className="flex items-center justify-between">
                                <div className={`${vital.bg} ${vital.color} p-4 rounded-2xl`}>
                                    <vital.icon className="h-6 w-6" />
                                </div>
                                <div className={`flex items-center gap-1 text-[10px] font-black uppercase tracking-widest ${vital.color}`}>
                                    <vital.trendIcon className="h-3 w-3" />
                                    {vital.trend}
                                </div>
                            </div>
                            <div className="space-y-1">
                                <h3 className="text-3xl font-black tracking-tight text-slate-900">{vital.val}</h3>
                                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{vital.label}</p>
                            </div>
                        </CardContent>
                    </Card>
                ))}
            </div>

            {/* Main Tabs Area */}
            <Tabs defaultValue="clinical-history" className="space-y-8">
                <div className="flex items-center justify-between bg-white p-2 rounded-[2.5rem] border border-slate-100 shadow-sm">
                    <TabsList className="bg-transparent h-12 gap-2">
                        <TabsTrigger value="clinical-history" className="rounded-2xl px-8 font-black uppercase tracking-widest text-[10px] data-[state=active]:bg-primary data-[state=active]:text-white">Clinical History</TabsTrigger>
                        <TabsTrigger value="medical-vault" className="rounded-2xl px-8 font-black uppercase tracking-widest text-[10px] data-[state=active]:bg-primary data-[state=active]:text-white">Medical Vault</TabsTrigger>
                        <TabsTrigger value="prescriptions" className="rounded-2xl px-8 font-black uppercase tracking-widest text-[10px] data-[state=active]:bg-primary data-[state=active]:text-white">Prescriptions</TabsTrigger>
                        <TabsTrigger value="analytics" className="rounded-2xl px-8 font-black uppercase tracking-widest text-[10px] data-[state=active]:bg-primary data-[state=active]:text-white">Trend Analytics</TabsTrigger>
                    </TabsList>
                    <div className="flex gap-2 pr-2">
                        <Button variant="ghost" size="icon" className="rounded-xl h-10 w-10">
                            <Download className="h-4 w-4 text-slate-400" />
                        </Button>
                        <Button variant="ghost" size="icon" className="rounded-xl h-10 w-10">
                            <MoreHorizontal className="h-4 w-4 text-slate-400" />
                        </Button>
                    </div>
                </div>

                <TabsContent value="clinical-history" className="animate-in slide-in-from-bottom-2">
                    <div className="grid gap-8 lg:grid-cols-12">
                        {/* Timeline */}
                        <div className="lg:col-span-8 space-y-6">
                            <h3 className="text-xl font-black tracking-tight text-slate-900 px-2">Timeline of Consultations</h3>
                            <div className="space-y-4">
                                {appointments?.map((apt, i) => (
                                    <div key={apt.id} className="group relative flex gap-6 p-8 rounded-[3rem] bg-white border border-slate-100 hover:border-primary/20 hover:shadow-2xl transition-all overflow-hidden">
                                        <div className="absolute left-0 top-0 h-full w-1.5 bg-primary/20 group-hover:bg-primary transition-colors" />
                                        <div className="space-y-2 shrink-0 w-24 text-center">
                                            <p className="text-2xl font-black text-slate-900">{new Date(apt.appointment_date).getDate()}</p>
                                            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{new Date(apt.appointment_date).toLocaleDateString(undefined, { month: 'short', year: 'numeric' })}</p>
                                        </div>
                                        <div className="flex-1 space-y-4">
                                            <div className="flex items-center justify-between">
                                                <Badge className="bg-slate-50 text-slate-600 border-none rounded-lg px-3 py-1 text-[9px] font-black uppercase tracking-widest">
                                                    General Consultation
                                                </Badge>
                                                <span className="text-[10px] font-bold text-slate-400 flex items-center gap-2">
                                                    <Clock className="h-3 w-3" />
                                                    {new Date(apt.appointment_date).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                </span>
                                            </div>
                                            <div className="space-y-2">
                                                <h4 className="text-lg font-black text-slate-900">Follow-up: Hypertension Management</h4>
                                                <p className="text-sm text-slate-500 leading-relaxed italic">
                                                    &ldquo;Patient reporting improved sleep cycles. Blood pressure stable at 122/82. Recommend continuing current dosage of Lisinopril.&rdquo;
                                                </p>
                                            </div>
                                            <div className="flex items-center gap-6 pt-2">
                                                <div className="flex items-center gap-2">
                                                    <div className="h-8 w-8 rounded-lg bg-emerald-50 flex items-center justify-center text-emerald-600">
                                                        <Activity className="h-4 w-4" />
                                                    </div>
                                                    <span className="text-[10px] font-black uppercase tracking-widest text-slate-600">Vitals Logged</span>
                                                </div>
                                                <div className="flex items-center gap-2">
                                                    <div className="h-8 w-8 rounded-lg bg-indigo-50 flex items-center justify-center text-indigo-600">
                                                        <FileText className="h-4 w-4" />
                                                    </div>
                                                    <span className="text-[10px] font-black uppercase tracking-widest text-slate-600">Report Linked</span>
                                                </div>
                                            </div>
                                        </div>
                                        <Button variant="ghost" size="icon" className="rounded-xl h-12 w-12 self-start opacity-0 group-hover:opacity-100 transition-opacity">
                                            <ChevronRight className="h-5 w-5 text-slate-400" />
                                        </Button>
                                    </div>
                                ))}
                            </div>
                        </div>

                        {/* Summary & Alerts */}
                        <div className="lg:col-span-4 space-y-8">
                            <Card className="rounded-[3rem] border-slate-100 shadow-2xl shadow-slate-200/40 overflow-hidden">
                                <CardHeader className="p-8 bg-slate-50/50 border-b border-dashed">
                                    <CardTitle className="text-xl font-black tracking-tight">Clinical Summary</CardTitle>
                                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">Automatic Physician Brief</p>
                                </CardHeader>
                                <CardContent className="p-8 space-y-6">
                                    <div className="space-y-4">
                                        <div className="flex items-start gap-4">
                                            <div className="h-8 w-8 rounded-lg bg-rose-50 flex items-center justify-center text-rose-500 shrink-0">
                                                <ShieldCheck className="h-4 w-4" />
                                            </div>
                                            <div className="space-y-1">
                                                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Chronic Conditions</p>
                                                <p className="text-xs font-bold text-slate-900">Type 2 Diabetes, Hypertension</p>
                                            </div>
                                        </div>
                                        <div className="flex items-start gap-4">
                                            <div className="h-8 w-8 rounded-lg bg-orange-50 flex items-center justify-center text-orange-500 shrink-0">
                                                <Pill className="h-4 w-4" />
                                            </div>
                                            <div className="space-y-1">
                                                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Allergies</p>
                                                <p className="text-xs font-bold text-slate-900">Penicillin, Peanuts</p>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="p-6 rounded-2xl bg-primary/5 border border-primary/10">
                                        <p className="text-xs font-bold text-primary italic leading-relaxed">
                                            &ldquo;Patient is highly adherent to medication but struggles with dietary restrictions during travel.&rdquo;
                                        </p>
                                    </div>
                                    <Button className="w-full rounded-2xl bg-slate-900 h-12 font-black uppercase tracking-widest text-[10px]">Update Summary</Button>
                                </CardContent>
                            </Card>

                            <div className="grid gap-4">
                                <h4 className="text-[10px] font-black text-slate-400 uppercase tracking-[0.4em] px-4">Emergency Protocol</h4>
                                <Button variant="outline" className="h-20 w-full justify-start rounded-[2.5rem] bg-rose-50 border-rose-100 hover:bg-rose-100 transition-all p-6 group border-2">
                                    <div className="h-10 w-10 rounded-xl bg-rose-500 flex items-center justify-center text-white">
                                        <Activity className="h-5 w-5" />
                                    </div>
                                    <div className="ml-4 text-left">
                                        <p className="font-black uppercase tracking-widest text-[11px] text-rose-600">Critical Care Contact</p>
                                        <p className="text-[10px] font-bold text-rose-400">Mrs. Adewole (Spouse) • +234...</p>
                                    </div>
                                </Button>
                            </div>
                        </div>
                    </div>
                </TabsContent>

                <TabsContent value="medical-vault" className="animate-in slide-in-from-bottom-2">
                    <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                        {records?.map((record) => (
                            <Card key={record.id} className="rounded-[2.5rem] border-slate-100 shadow-xl hover:shadow-2xl transition-all group overflow-hidden">
                                <CardHeader className="p-8 pb-4">
                                    <div className="flex justify-between items-start">
                                        <div className="h-14 w-14 rounded-2xl bg-primary/5 flex items-center justify-center text-primary group-hover:scale-110 transition-transform">
                                            <Beaker className="h-7 w-7" />
                                        </div>
                                        <Badge className="bg-slate-50 text-slate-400 border-none rounded-lg px-2 py-1 text-[8px] font-black uppercase tracking-widest">
                                            {record.record_type}
                                        </Badge>
                                    </div>
                                </CardHeader>
                                <CardContent className="p-8 pt-0 space-y-6">
                                    <div className="space-y-1">
                                        <h4 className="text-lg font-black text-slate-900 truncate">{record.title}</h4>
                                        <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Uploaded {new Date(record.created_at).toLocaleDateString()}</p>
                                    </div>
                                    <div className="flex gap-2">
                                        <Button className="flex-1 rounded-xl bg-primary/10 text-primary hover:bg-primary/20 font-black uppercase tracking-widest text-[9px] h-10 gap-2">
                                            <Download className="h-3.5 w-3.5" /> Download
                                        </Button>
                                        <Button variant="outline" size="icon" className="rounded-xl h-10 w-10 border-slate-100">
                                            <ExternalLink className="h-3.5 w-3.5 text-slate-400" />
                                        </Button>
                                    </div>
                                </CardContent>
                            </Card>
                        ))}
                    </div>
                </TabsContent>

                <TabsContent value="prescriptions" className="animate-in slide-in-from-bottom-2">
                    <div className="bg-white rounded-[3.5rem] border border-slate-100 shadow-2xl shadow-slate-200/40 overflow-hidden">
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="border-b border-slate-50">
                                        <th className="p-8 text-[10px] font-black uppercase tracking-widest text-slate-400">Medication</th>
                                        <th className="p-8 text-[10px] font-black uppercase tracking-widest text-slate-400">Dosage</th>
                                        <th className="p-8 text-[10px] font-black uppercase tracking-widest text-slate-400">Frequency</th>
                                        <th className="p-8 text-[10px] font-black uppercase tracking-widest text-slate-400">Status</th>
                                        <th className="p-8 text-[10px] font-black uppercase tracking-widest text-slate-400 text-right">Refills</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-50">
                                    {[
                                        { name: 'Lisinopril', dosage: '10mg Oral Tablet', frequency: 'Once Daily (AM)', status: 'active', refills: 3 },
                                        { name: 'Metformin', dosage: '500mg ER Tablet', frequency: 'Twice Daily (W/ Meal)', status: 'active', refills: 2 },
                                        { name: 'Atorvastatin', dosage: '20mg Tablet', frequency: 'Once Daily (PM)', status: 'active', refills: 5 },
                                        { name: 'Amoxicillin', dosage: '250mg Capsule', frequency: '8 Hours (7 Days)', status: 'completed', refills: 0 }
                                    ].map((med, i) => (
                                        <tr key={i} className="hover:bg-slate-50/50 transition-colors">
                                            <td className="p-8">
                                                <div className="flex items-center gap-4">
                                                    <div className="h-10 w-10 rounded-xl bg-primary/5 flex items-center justify-center text-primary">
                                                        <Pill className="h-5 w-5" />
                                                    </div>
                                                    <p className="text-sm font-black text-slate-900">{med.name}</p>
                                                </div>
                                            </td>
                                            <td className="p-8 text-sm font-bold text-slate-600">{med.dosage}</td>
                                            <td className="p-8 text-sm font-bold text-slate-600">{med.frequency}</td>
                                            <td className="p-8">
                                                <Badge className={`rounded-lg px-2 py-0.5 text-[8px] font-black uppercase tracking-widest border-none ${med.status === 'active' ? 'bg-emerald-50 text-emerald-600' : 'bg-slate-50 text-slate-400'}`}>
                                                    {med.status}
                                                </Badge>
                                            </td>
                                            <td className="p-8 text-right text-sm font-black text-slate-900">{med.refills} Left</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </TabsContent>
            </Tabs>
        </div>
    )
}
