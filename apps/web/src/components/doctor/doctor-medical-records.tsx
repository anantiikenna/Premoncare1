'use client'

import { useState, useCallback, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { Loader2, FileText, Lock, Search, Beaker, FileSignature, Stethoscope, Clock } from 'lucide-react'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { MedicalRecord } from '@/lib/types'

interface RecordWithPatient extends MedicalRecord {
    patient: { full_name: string; avatar_url: string; };
}

export function DoctorMedicalRecords() {
    const [records, setRecords] = useState<RecordWithPatient[]>([])
    const [loading, setLoading] = useState(true)
    const [searchTerm, setSearchTerm] = useState('')

    const supabase = createClient()

    const fetchRecords = useCallback(async () => {
        setLoading(true)
        try {
            // RLS automatically filters to only records this doctor is authorized to view
            const { data, error } = await supabase
                .from('medical_records')
                .select('*, patient:profiles!patient_id(full_name, avatar_url)')
                .order('created_at', { ascending: false })

            if (error) throw error
            setRecords(data as unknown as RecordWithPatient[])
        } catch (error: any) {
            toast.error('Failed to load patient records: ' + error.message)
        } finally {
            setLoading(false)
        }
    }, [supabase])

    useEffect(() => {
        fetchRecords()
    }, [fetchRecords])

    const viewRecord = async (record: RecordWithPatient) => {
        try {
            const { data, error } = await supabase.storage.from('patient-medical-vault').createSignedUrl(record.document_url, 600)
            if (error) throw error
            if (data?.signedUrl) window.open(data.signedUrl, '_blank')
        } catch (error: any) {
            toast.error('Could not decrypt patient file: ' + error.message)
        }
    }

    const getIconForType = (type: string) => {
        switch(type) {
            case 'lab_result': return <Beaker className="h-5 w-5 text-indigo-500" />
            case 'prescription': return <FileSignature className="h-5 w-5 text-amber-500" />
            default: return <Stethoscope className="h-5 w-5 text-emerald-500" />
        }
    }

    const filteredRecords = records.filter(r => 
        r.title.toLowerCase().includes(searchTerm.toLowerCase()) || 
        r.patient.full_name?.toLowerCase().includes(searchTerm.toLowerCase())
    )

    if (loading) return <div className="flex justify-center p-12"><Loader2 className="h-8 w-8 animate-spin text-primary" /></div>

    return (
        <div className="space-y-6">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div className="relative flex-1 max-w-md">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input 
                        placeholder="Search records by patient name or title..." 
                        className="pl-10 h-11"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
            </div>

            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {filteredRecords.length === 0 ? (
                    <div className="col-span-full text-center py-20 bg-muted/20 rounded-2xl border-2 border-dashed">
                        <Lock className="h-10 w-10 text-muted-foreground mx-auto mb-4 opacity-50" />
                        <h3 className="text-lg font-bold">No Authorized Records</h3>
                        <p className="text-muted-foreground mt-1 max-w-md mx-auto">Patients must explicitly share their medical history with you before documents appear in this vault.</p>
                    </div>
                ) : (
                    filteredRecords.map(record => (
                        <Card key={record.id} className="overflow-hidden border-primary/10 hover:border-primary/30 transition-colors">
                            <CardHeader className="bg-muted/30 pb-4">
                                <div className="flex justify-between items-start">
                                    <div className="flex items-center gap-3">
                                        <Avatar className="h-10 w-10 border-2 border-background">
                                            <AvatarImage src={record.patient?.avatar_url} />
                                            <AvatarFallback>{record.patient?.full_name?.charAt(0)}</AvatarFallback>
                                        </Avatar>
                                        <div>
                                            <CardTitle className="text-sm">{record.patient?.full_name}</CardTitle>
                                            <CardDescription className="text-xs flex items-center gap-1 mt-0.5"><Clock className="h-3 w-3" /> {new Date(record.created_at).toLocaleDateString()}</CardDescription>
                                        </div>
                                    </div>
                                    <div className="bg-background p-2 rounded-lg shadow-sm border">
                                        {getIconForType(record.record_type)}
                                    </div>
                                </div>
                            </CardHeader>
                            <CardContent className="pt-4 grid gap-4">
                                <div>
                                    <p className="font-semibold text-sm leading-tight mb-1">{record.title}</p>
                                    <span className="text-[10px] font-black uppercase tracking-wider text-muted-foreground">
                                        {record.record_type.replace('_', ' ')}
                                    </span>
                                </div>
                                <Button 
                                    className="w-full bg-primary/10 text-primary hover:bg-primary/20" 
                                    onClick={() => viewRecord(record)}
                                >
                                    <FileText className="h-4 w-4 mr-2" />
                                    Decrypt & View Record
                                </Button>
                            </CardContent>
                        </Card>
                    ))
                )}
            </div>
        </div>
    )
}
