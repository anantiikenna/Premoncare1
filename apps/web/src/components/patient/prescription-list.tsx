'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { getPatientPrescriptions } from '@/lib/queries-client'
import { Pill, Calendar, User, Clock, CheckCircle2 } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'

export function PrescriptionList({ patientId }: { patientId: string }) {
    const [prescriptions, setPrescriptions] = useState<any[]>([])
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        const fetchPrescriptions = async () => {
            const { data } = await getPatientPrescriptions(patientId)
            if (data) setPrescriptions(data)
            setLoading(false)
        }
        fetchPrescriptions()
    }, [patientId])

    if (loading) {
        return (
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {[1, 2, 3].map(i => (
                    <Card key={i} className="animate-pulse">
                        <CardHeader className="h-24 bg-accent/50 rounded-t-lg" />
                        <CardContent className="h-32 bg-accent/20 rounded-b-lg mt-2" />
                    </Card>
                ))}
            </div>
        )
    }

    if (prescriptions.length === 0) {
        return (
            <Card className="w-full text-center py-12 border-dashed">
                <CardContent className="flex flex-col items-center justify-center space-y-4">
                    <div className="h-16 w-16 bg-accent rounded-full flex items-center justify-center">
                        <CheckCircle2 className="h-8 w-8 text-muted-foreground" />
                    </div>
                    <CardTitle className="text-xl">No Prescriptions</CardTitle>
                    <CardDescription className="max-w-xs mx-auto">
                        You do not have any prescriptions on file. If a doctor prescribes medication, it will appear here.
                    </CardDescription>
                </CardContent>
            </Card>
        )
    }

    return (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {prescriptions.map(prescription => (
                <Card key={prescription.id} className="overflow-hidden border-primary/10 shadow-sm transition-all hover:shadow-md">
                    <div className="bg-primary/5 p-4 border-b flex justify-between items-start">
                        <div className="flex items-center gap-2 text-primary font-bold">
                            <Pill className="h-5 w-5" />
                            <span className="text-lg truncate">{prescription.medication_name}</span>
                        </div>
                    </div>
                    <CardContent className="p-5 space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-1">
                                <p className="text-xs text-muted-foreground uppercase font-semibold">Dosage</p>
                                <p className="font-medium">{prescription.dosage}</p>
                            </div>
                            <div className="space-y-1">
                                <p className="text-xs text-muted-foreground uppercase font-semibold">Frequency</p>
                                <p className="font-medium">{prescription.frequency}</p>
                            </div>
                            <div className="space-y-1 col-span-2">
                                <p className="text-xs text-muted-foreground uppercase font-semibold">Duration</p>
                                <p className="font-medium">{prescription.duration}</p>
                            </div>
                        </div>

                        {prescription.special_instructions && (
                            <div className="p-3 bg-accent/50 rounded-md text-sm">
                                <p className="text-xs text-muted-foreground font-semibold mb-1">Instructions</p>
                                <p>{prescription.special_instructions}</p>
                            </div>
                        )}
                    </CardContent>
                    <CardFooter className="bg-muted/30 p-4 border-t text-xs flex justify-between text-muted-foreground">
                        <div className="flex items-center gap-1">
                            <User className="h-3 w-3" /> Dr. {prescription.doctor.full_name}
                        </div>
                        <div className="flex items-center gap-1">
                            <Calendar className="h-3 w-3" /> {new Date(prescription.created_at).toLocaleDateString()}
                        </div>
                    </CardFooter>
                </Card>
            ))}
        </div>
    )
}
