'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { getMedicalProfile, upsertMedicalProfile } from '@/lib/queries-client'
import { Loader2, Plus, X, AlertCircle } from 'lucide-react'

export function MedicalProfileForm({ patientId }: { patientId: string }) {
    const [loading, setLoading] = useState(true)
    const [saving, setSaving] = useState(false)
    const [profile, setProfile] = useState<any>({
        allergies: [],
        current_medications: [],
        past_medical_history: '',
        blood_type: '',
        emergency_contacts: []
    })

    // Temporary inputs for arrays
    const [newAllergy, setNewAllergy] = useState('')
    const [newMed, setNewMed] = useState('')
    const [loadingError, setLoadingError] = useState<string | null>(null)

    const supabase = createClient()

    useEffect(() => {
        const fetchProfile = async () => {
            try {
                const { data, error } = await getMedicalProfile(patientId)
                if (data) {
                    setProfile({
                        allergies: data.allergies || [],
                        current_medications: data.current_medications || [],
                        past_medical_history: data.past_medical_history || '',
                        blood_type: data.blood_type || '',
                        emergency_contacts: data.emergency_contacts || []
                    })
                }
            } catch (err: unknown) {
                setLoadingError('Could not load profile. You may need to create one.')
            } finally {
                setLoading(false)
            }
        }
        fetchProfile()
    }, [patientId])

    const handleSave = async (e?: React.FormEvent) => {
        if (e) e.preventDefault()
        setSaving(true)
        try {
            const { error } = await upsertMedicalProfile(patientId, profile)
            if (error) throw error
            toast.success('Medical profile updated successfully')
        } catch (error: unknown) {
            toast.error('Failed to update: ' + (error instanceof Error ? error.message : String(error)))
        } finally {
            setSaving(false)
        }
    }

    const addArrayItem = (field: 'allergies' | 'current_medications', value: string, setter: (val: string) => void) => {
        if (!value.trim()) return
        setProfile({
            ...profile,
            [field]: [...profile[field], value.trim()]
        })
        setter('')
    }

    const removeArrayItem = (field: 'allergies' | 'current_medications', index: number) => {
        const newArray = [...profile[field]]
        newArray.splice(index, 1)
        setProfile({
            ...profile,
            [field]: newArray
        })
    }

    const bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown']

    if (loading) return <div className="flex justify-center p-8"><Loader2 className="h-8 w-8 animate-spin" /></div>

    return (
        <Card className="w-full">
            <CardHeader>
                <CardTitle>Comprehensive Medical Profile</CardTitle>
                <CardDescription>
                    Provide your medical history to help doctors give you the best care during consultations.
                </CardDescription>
            </CardHeader>
            <CardContent>
                {loadingError && (
                    <div className="mb-6 p-4 bg-amber-50 dark:bg-amber-900/20 text-amber-800 dark:text-amber-200 rounded-md flex items-start gap-3 text-sm">
                        <AlertCircle className="h-5 w-5 shrink-0" />
                        <p>{loadingError}</p>
                    </div>
                )}
                <form onSubmit={handleSave} className="space-y-8">
                    
                    {/* Basic Medical Info */}
                    <div className="grid gap-6 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label>Blood Type</Label>
                            <Select 
                                value={profile.blood_type} 
                                onValueChange={(val) => setProfile({...profile, blood_type: val})}
                            >
                                <SelectTrigger>
                                    <SelectValue placeholder="Select Blood Type" />
                                </SelectTrigger>
                                <SelectContent>
                                    {bloodTypes.map(bt => (
                                        <SelectItem key={bt} value={bt}>{bt}</SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>
                    </div>

                    {/* Allergies */}
                    <div className="space-y-4">
                        <Label>Known Allergies</Label>
                        <div className="flex flex-wrap gap-2 mb-2">
                            {profile.allergies.map((allergy: string, i: number) => (
                                <div key={i} className="flex items-center gap-1 bg-destructive/10 text-destructive px-3 py-1 rounded-full text-sm">
                                    {allergy}
                                    <button type="button" onClick={() => removeArrayItem('allergies', i)} className="hover:text-destructive/80 cursor-pointer">
                                        <X className="h-3 w-3" />
                                    </button>
                                </div>
                            ))}
                            {profile.allergies.length === 0 && <span className="text-sm text-muted-foreground italic">No allergies listed</span>}
                        </div>
                        <div className="flex gap-2">
                            <Input 
                                placeholder="e.g. Penicillin, Peanuts" 
                                value={newAllergy}
                                onChange={(e) => setNewAllergy(e.target.value)}
                                onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addArrayItem('allergies', newAllergy, setNewAllergy) } }}
                            />
                            <Button type="button" variant="secondary" onClick={() => addArrayItem('allergies', newAllergy, setNewAllergy)}>
                                <Plus className="h-4 w-4" />
                            </Button>
                        </div>
                    </div>

                    {/* Medications */}
                    <div className="space-y-4">
                        <Label>Current Medications</Label>
                        <div className="flex flex-wrap gap-2 mb-2">
                            {profile.current_medications.map((med: string, i: number) => (
                                <div key={i} className="flex items-center gap-1 bg-primary/10 text-primary px-3 py-1 rounded-full text-sm">
                                    {med}
                                    <button type="button" onClick={() => removeArrayItem('current_medications', i)} className="hover:text-primary/80 cursor-pointer">
                                        <X className="h-3 w-3" />
                                    </button>
                                </div>
                            ))}
                            {profile.current_medications.length === 0 && <span className="text-sm text-muted-foreground italic">No current medications</span>}
                        </div>
                        <div className="flex gap-2">
                            <Input 
                                placeholder="e.g. Lisinopril 10mg daily" 
                                value={newMed}
                                onChange={(e) => setNewMed(e.target.value)}
                                onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addArrayItem('current_medications', newMed, setNewMed) } }}
                            />
                            <Button type="button" variant="secondary" onClick={() => addArrayItem('current_medications', newMed, setNewMed)}>
                                <Plus className="h-4 w-4" />
                            </Button>
                        </div>
                    </div>

                    {/* Medical History */}
                    <div className="space-y-2">
                        <Label>Past Medical & Surgical History</Label>
                        <Textarea 
                            className="min-h-[150px]"
                            placeholder="List any major past illnesses, chronic conditions, or surgeries..."
                            value={profile.past_medical_history}
                            onChange={(e) => setProfile({...profile, past_medical_history: e.target.value})}
                        />
                    </div>

                    <Button type="submit" disabled={saving} className="w-full md:w-auto">
                        {saving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Save Medical Profile
                    </Button>
                </form>
            </CardContent>
        </Card>
    )
}
