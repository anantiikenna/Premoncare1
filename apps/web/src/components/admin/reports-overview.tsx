'use client'

import { useState, useEffect } from 'react'
import { getAdminReports } from '@/lib/queries-client'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Label } from '@/components/ui/label'
import { Loader2, Settings2, Save, Bell, Mail, Banknote, TrendingUp, Clock, CheckCircle2, Stethoscope, Calendar, Users, FileText } from 'lucide-react'
import { format } from 'date-fns'

export function AdminReportsOverview() {
    const [loading, setLoading] = useState(true)
    const [reports, setReports] = useState<any>(null)

    useEffect(() => {
        getAdminReports().then(data => {
            setReports(data)
            setLoading(false)
        })
    }, [])

    if (loading) return (
        <div className="flex justify-center py-20">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
    )
    if (!reports) return <div className="text-center text-muted-foreground py-20">Could not load report data.</div>

    const getStatusBadge = (status: string) => {
        const cls: Record<string, string> = {
            approved: 'text-green-700 bg-green-50 border-green-200',
            pending: 'text-amber-700 bg-amber-50 border-amber-200',
            rejected: 'text-red-700 bg-red-50 border-red-200',
        }
        return <Badge variant="outline" className={`capitalize ${cls[status] || ''}`}>{status}</Badge>
    }

    return (
        <div className="space-y-8">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">Comprehensive Reports</h1>
                <p className="text-muted-foreground">Full financial, clinical, and operational overview of the platform.</p>
            </div>

            {/* Revenue KPI Cards */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                {[
                    {
                        title: 'Total Revenue', value: `₦${reports.totalRevenue.toFixed(2)}`,
                        icon: Banknote, color: 'text-green-600', bg: 'bg-green-100',
                        sub: 'From approved payments'
                    },
                    {
                        title: 'Pending Revenue', value: `₦${reports.pendingRevenue.toFixed(2)}`,
                        icon: Clock, color: 'text-amber-600', bg: 'bg-amber-100',
                        sub: 'Awaiting approval'
                    },
                    {
                        title: 'Total Appointments', value: reports.allAppointments.length,
                        icon: Calendar, color: 'text-blue-600', bg: 'bg-blue-100',
                        sub: 'All time'
                    },
                    {
                        title: 'Approval Rate', value: reports.totalPayments > 0
                            ? `${Math.round((reports.approvedPayments / reports.totalPayments) * 100)}%`
                            : 'N/A',
                        icon: CheckCircle2, color: 'text-purple-600', bg: 'bg-purple-100',
                        sub: `${reports.approvedPayments} of ${reports.totalPayments} payments`
                    },
                ].map(item => (
                    <Card key={item.title} className="hover:shadow-md transition-shadow">
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                            <CardTitle className="text-sm font-medium">{item.title}</CardTitle>
                            <div className={`${item.bg} p-2 rounded-lg`}>
                                <item.icon className={`h-4 w-4 ${item.color}`} />
                            </div>
                        </CardHeader>
                        <CardContent>
                            <div className="text-2xl font-bold">{item.value}</div>
                            <p className="text-xs text-muted-foreground mt-1">{item.sub}</p>
                        </CardContent>
                    </Card>
                ))}
            </div>

            {/* Tabbed Reports */}
            <Tabs defaultValue="doctors">
                <TabsList className="w-full justify-start overflow-x-auto flex-nowrap h-auto py-2 [&::-webkit-scrollbar]:hidden mb-4">
                    <TabsTrigger value="doctors" className="gap-1.5">
                        <Stethoscope className="h-3.5 w-3.5" /> Doctor Activity
                    </TabsTrigger>
                    <TabsTrigger value="payments" className="gap-1.5">
                        <Banknote className="h-3.5 w-3.5" /> Payment Ledger
                    </TabsTrigger>
                    <TabsTrigger value="appointments" className="gap-1.5">
                        <Calendar className="h-3.5 w-3.5" /> All Appointments
                    </TabsTrigger>
                </TabsList>

                {/* Doctor Activity */}
                <TabsContent value="doctors" className="mt-4">
                    <Card>
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <Users className="h-5 w-5 text-primary" /> Doctor Performance
                            </CardTitle>
                            <CardDescription>Breakdown of appointment activity per doctor</CardDescription>
                        </CardHeader>
                        <CardContent className="p-0">
                            <div className="overflow-x-auto">
                                <Table>
                                    <TableHeader>
                                        <TableRow className="bg-muted/50">
                                            <TableHead>Doctor</TableHead>
                                            <TableHead>Specialty</TableHead>
                                            <TableHead className="text-center">Total Appts</TableHead>
                                            <TableHead className="text-center">Completed</TableHead>
                                            <TableHead className="text-center">Pending</TableHead>
                                            <TableHead className="text-center">Cancelled</TableHead>
                                            <TableHead className="text-center">Unique Patients</TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {reports.doctorActivity.length === 0 ? (
                                            <TableRow>
                                                <TableCell colSpan={7} className="text-center py-8 text-muted-foreground">
                                                    No appointment data yet
                                                </TableCell>
                                            </TableRow>
                                        ) : reports.doctorActivity
                                            .sort((a: any, b: any) => b.total - a.total)
                                            .map((doc: any) => (
                                                <TableRow key={doc.id} className="hover:bg-muted/30">
                                                    <TableCell className="font-medium whitespace-nowrap">Dr. {doc.name}</TableCell>
                                                    <TableCell>
                                                        <Badge variant="outline" className="text-primary border-primary/20 bg-primary/5 whitespace-nowrap">
                                                            {doc.specialty || 'General'}
                                                        </Badge>
                                                    </TableCell>
                                                    <TableCell className="text-center font-bold">{doc.total}</TableCell>
                                                    <TableCell className="text-center text-green-600 font-semibold">{doc.completed}</TableCell>
                                                    <TableCell className="text-center text-amber-600">{doc.pending}</TableCell>
                                                    <TableCell className="text-center text-red-500">{doc.cancelled}</TableCell>
                                                    <TableCell className="text-center">{doc.uniquePatients}</TableCell>
                                                </TableRow>
                                            ))}
                                    </TableBody>
                                </Table>
                            </div>
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* Payment Ledger */}
                <TabsContent value="payments" className="mt-4">
                    <Card>
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <FileText className="h-5 w-5 text-primary" /> Full Payment Ledger
                            </CardTitle>
                            <CardDescription>All payments from all users in chronological order</CardDescription>
                        </CardHeader>
                        <CardContent className="p-0">
                            <div className="overflow-x-auto">
                                <Table>
                                    <TableHeader>
                                        <TableRow className="bg-muted/50">
                                            <TableHead className="whitespace-nowrap">Date</TableHead>
                                            <TableHead className="whitespace-nowrap">Patient</TableHead>
                                            <TableHead className="whitespace-nowrap">Amount</TableHead>
                                            <TableHead className="whitespace-nowrap">Method</TableHead>
                                            <TableHead className="whitespace-nowrap">Status</TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {reports.allPayments.length === 0 ? (
                                            <TableRow>
                                                <TableCell colSpan={5} className="text-center py-8 text-muted-foreground">No payments recorded</TableCell>
                                            </TableRow>
                                        ) : reports.allPayments.map((p: any, i: number) => {
                                            const user = (Array.isArray(p.user) ? p.user[0] : p.user) as any
                                            return (
                                                <TableRow key={i} className="hover:bg-muted/30">
                                                    <TableCell className="text-sm text-muted-foreground whitespace-nowrap">
                                                        {format(new Date(p.created_at), 'PP')}
                                                    </TableCell>
                                                    <TableCell className="font-medium whitespace-nowrap">{user?.full_name || '—'}</TableCell>
                                                    <TableCell className="font-bold">₦{Number(p.amount).toFixed(2)}</TableCell>
                                                    <TableCell>
                                                        <Badge variant="outline" className="capitalize text-xs">{p.method}</Badge>
                                                    </TableCell>
                                                    <TableCell className="whitespace-nowrap">{getStatusBadge(p.status)}</TableCell>
                                                </TableRow>
                                            )
                                        })}
                                    </TableBody>
                                </Table>
                            </div>
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* All Appointments */}
                <TabsContent value="appointments" className="mt-4">
                    <Card>
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <Calendar className="h-5 w-5 text-primary" /> All Appointments
                            </CardTitle>
                            <CardDescription>Platform-wide appointment history</CardDescription>
                        </CardHeader>
                        <CardContent className="p-0">
                            <ScrollArea className="h-[450px]">
                                <div className="overflow-x-auto">
                                    <Table>
                                        <TableHeader>
                                            <TableRow className="bg-muted/50">
                                                <TableHead className="whitespace-nowrap">Date</TableHead>
                                                <TableHead className="whitespace-nowrap">Patient</TableHead>
                                                <TableHead className="whitespace-nowrap">Doctor</TableHead>
                                                <TableHead className="whitespace-nowrap">Status</TableHead>
                                            </TableRow>
                                        </TableHeader>
                                        <TableBody>
                                            {reports.allAppointments.length === 0 ? (
                                                <TableRow>
                                                    <TableCell colSpan={4} className="text-center py-8 text-muted-foreground">No appointments yet</TableCell>
                                                </TableRow>
                                            ) : reports.allAppointments.map((apt: any, i: number) => {
                                                const doc = (Array.isArray(apt.doctor) ? apt.doctor[0] : apt.doctor) as any
                                                const pat = (Array.isArray(apt.patient) ? apt.patient[0] : apt.patient) as any
                                                return (
                                                    <TableRow key={i} className="hover:bg-muted/30">
                                                        <TableCell className="text-sm text-muted-foreground whitespace-nowrap">
                                                            {apt.created_at ? format(new Date(apt.created_at), 'PP') : '—'}
                                                        </TableCell>
                                                        <TableCell className="whitespace-nowrap">{pat?.full_name || '—'}</TableCell>
                                                        <TableCell className="whitespace-nowrap">Dr. {doc?.full_name || '—'}</TableCell>
                                                        <TableCell className="whitespace-nowrap">
                                                            {getStatusBadge(apt.status)}
                                                        </TableCell>
                                                    </TableRow>
                                                )
                                            })}
                                        </TableBody>
                                    </Table>
                                </div>
                            </ScrollArea>
                        </CardContent>
                    </Card>
                </TabsContent>
            </Tabs>
        </div>
    )
}
