'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Loader2, CheckCircle2 } from 'lucide-react'
import { getUserFacingError } from '@/lib/user-facing-errors'

interface Patient {
    id: string
    full_name: string
}

export function RecordForm() {
    const [patients, setPatients] = useState<Patient[]>([])
    const [loading, setLoading] = useState(false)
    const [submitting, setSubmitting] = useState(false)
    const [success, setSuccess] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const router = useRouter()
    const supabase = createClient()

    const [formData, setFormData] = useState({
        patient_id: '',
        content: ''
    })

    useEffect(() => {
        async function fetchPatients() {
            setLoading(true)
            const { data, error } = await supabase
                .from('profiles')
                .select('id, full_name')
                .eq('role', 'patient')

            if (data) setPatients(data)
            setLoading(false)
        }
        fetchPatients()
    }, [supabase])

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setSubmitting(true)
        setError(null)

        try {
            const { data: { user } } = await supabase.auth.getUser()
            if (!user) throw new Error('Not authenticated')

            const { error: recordError } = await supabase
                .from('health_records')
                .insert({
                    patient_id: formData.patient_id,
                    doctor_id: user.id,
                    content: formData.content
                })

            if (recordError) throw recordError
            setSuccess(true)
        } catch (err: unknown) {
            console.error('Health record creation failed', err)
            setError(getUserFacingError(err, 'We could not save this health record. Please try again.'))
        } finally {
            setSubmitting(false)
        }
    }

    if (success) {
        return (
            <Card className="w-full max-w-md mx-auto text-center py-8">
                <CardContent className="space-y-4 pt-6">
                    <CheckCircle2 className="h-12 w-16 text-primary mx-auto" />
                    <CardTitle>Record Created!</CardTitle>
                    <CardDescription>
                        The health record has been successfully added to the patient history.
                    </CardDescription>
                    <Button onClick={() => {
                        setSuccess(false)
                        setFormData({ patient_id: '', content: '' })
                    }} className="mt-4">
                        Add Another Record
                    </Button>
                </CardContent>
            </Card>
        )
    }

    return (
        <Card className="w-full max-w-2xl mx-auto">
            <CardHeader>
                <CardTitle>Create Health Record</CardTitle>
                <CardDescription>Add a new medical entry for a patient.</CardDescription>
            </CardHeader>
            <form onSubmit={handleSubmit}>
                <CardContent className="space-y-4">
                    <div className="space-y-2">
                        <Label>Select Patient</Label>
                        {loading ? (
                            <div className="flex justify-center p-4">
                                <Loader2 className="h-6 w-6 animate-spin text-primary" />
                            </div>
                        ) : (
                            <Select
                                value={formData.patient_id}
                                onValueChange={(val) => setFormData({ ...formData, patient_id: val })}
                            >
                                <SelectTrigger>
                                    <SelectValue placeholder="Choose a patient" />
                                </SelectTrigger>
                                <SelectContent>
                                    {patients.map((patient) => (
                                        <SelectItem key={patient.id} value={patient.id}>
                                            {patient.full_name}
                                        </SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        )}
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="content">Medical Findings & Notes</Label>
                        <Textarea
                            id="content"
                            placeholder="Enter diagnosis, treatment plan, or general notes..."
                            value={formData.content}
                            onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                            rows={8}
                            required
                        />
                    </div>
                    {error && (
                        <div className="p-3 text-sm bg-destructive/10 text-destructive rounded-md border border-destructive/20 font-medium">
                            {error}
                        </div>
                    )}
                </CardContent>
                <CardFooter className="border-t pt-6">
                    <Button type="submit" className="w-full" disabled={!formData.patient_id || !formData.content || submitting}>
                        {submitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Save Health Record
                    </Button>
                </CardFooter>
            </form>
        </Card>
    )
}
