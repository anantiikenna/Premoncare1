import { useState, useEffect } from 'react'
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView, ActivityIndicator, Alert, TextInput } from 'react-native'
import { useLocalSearchParams, useRouter } from 'expo-router'
import { supabase } from '../../../lib/supabase'
import { useAuth } from '../../../lib/auth-provider'

type DoctorProfile = {
    id: string
    full_name: string
    specialty: string
    preferred_consultation_types: string[]
    negotiated_fee: number
}

// Helper to generate some dummy time slots for today
const getAvailableTimeSlots = () => {
    return ['09:00 AM', '09:30 AM', '10:00 AM', '11:00 AM', '01:00 PM', '02:30 PM', '03:00 PM', '04:30 PM']
}

export default function BookAppointmentScreen() {
    const { id } = useLocalSearchParams<{ id: string }>()
    const router = useRouter()
    const { user } = useAuth()
    
    const [doctor, setDoctor] = useState<DoctorProfile | null>(null)
    const [loading, setLoading] = useState(true)
    const [submitting, setSubmitting] = useState(false)

    // Form State
    const [selectedDate, setSelectedDate] = useState<Date>(new Date()) // Default today
    const [selectedTimeSlot, setSelectedTimeSlot] = useState<string>('')
    const [selectedMode, setSelectedMode] = useState<string>('')
    const [reason, setReason] = useState<string>('')

    useEffect(() => {
        async function fetchDoctor() {
            try {
                const { data, error } = await supabase
                    .from('profiles')
                    .select('id, full_name, specialty, preferred_consultation_types, negotiated_fee')
                    .eq('id', id)
                    .single()

                if (error) throw error
                setDoctor(data)
                
                // Pre-select the first available consultation mode
                if (data?.preferred_consultation_types?.length > 0) {
                    setSelectedMode(data.preferred_consultation_types[0])
                }
            } catch (error) {
                console.error(error)
                Alert.alert('Error', 'Could not load doctor details.')
                router.back()
            } finally {
                setLoading(false)
            }
        }
        if (id) fetchDoctor()
    }, [id])

    const handleBooking = async () => {
        if (!selectedTimeSlot) return Alert.alert('Missing Field', 'Please select a time slot.')
        if (!selectedMode) return Alert.alert('Missing Field', 'Please select a consultation modality.')
        if (!user?.id || !doctor?.id) return Alert.alert('Session Error', 'User or Doctor ID missing.')

        setSubmitting(true)

        // Convert the "09:00 AM" slot string to a full JS Date object using selectedDate as the base
        const match = selectedTimeSlot.match(/(\d+):(\d+)\s*(AM|PM)/)
        if (!match) return setSubmitting(false)

        let hours = parseInt(match[1], 10)
        const minutes = parseInt(match[2], 10)
        const modifier = match[3]

        if (modifier === 'PM' && hours < 12) hours += 12
        if (modifier === 'AM' && hours === 12) hours = 0

        const appointmentDateTime = new Date(selectedDate)
        appointmentDateTime.setHours(hours, minutes, 0, 0)

        // Convert UI labels Back to standard schema strings handling if needed
        let dbMode = selectedMode.toLowerCase()
        if (dbMode === 'in-person') dbMode = 'in_person'

        try {
            const { error } = await supabase.from('appointments').insert({
                patient_id: user.id,
                doctor_id: doctor.id,
                appointment_date: appointmentDateTime.toISOString(),
                status: 'pending',
                reason: reason || 'Routine Checkup',
                consultation_mode: dbMode,
                duration_minutes: 30
            })

            if (error) throw error
            
            Alert.alert('Success', 'Your appointment has been scheduled and is pending confirmation.')
            router.replace('/(app)/appointments')
        } catch (error: any) {
            Alert.alert('Booking Error', error.message)
            setSubmitting(false)
        }
    }

    if (loading) {
        return (
            <View style={styles.centerMode}>
                <ActivityIndicator size="large" color="#2563eb" />
            </View>
        )
    }

    const timeSlots = getAvailableTimeSlots()

    return (
        <SafeAreaView style={styles.container}>
            <View style={styles.header}>
                <TouchableOpacity onPress={() => router.back()} style={styles.headerButton}>
                    <Text style={styles.headerButtonText}>✕ Cancel</Text>
                </TouchableOpacity>
                <Text style={styles.headerTitle}>Schedule Visit</Text>
                <View style={{ width: 60 }} />
            </View>

            <ScrollView contentContainerStyle={styles.scrollContent}>
                <View style={styles.profileCard}>
                    <Text style={styles.docName}>{doctor?.full_name}</Text>
                    <Text style={styles.docSpec}>{doctor?.specialty}</Text>
                    <Text style={styles.docFee}>Consultation Fee: NGN {doctor?.negotiated_fee || 0}</Text>
                </View>

                {/* Date Selection Box (simplified logic) */}
                <View style={styles.section}>
                    <Text style={styles.sectionTitle}>Select Date</Text>
                    <View style={styles.dateDisplay}>
                        <Text style={styles.dateText}>
                            {selectedDate.toLocaleDateString(undefined, { weekday: 'long', month: 'long', day: 'numeric' })}
                        </Text>
                    </View>
                </View>

                {/* Time Slot Selection */}
                <View style={styles.section}>
                    <Text style={styles.sectionTitle}>Available Slots</Text>
                    <View style={styles.slotGrid}>
                        {timeSlots.map((slot) => {
                            const isSelected = selectedTimeSlot === slot
                            return (
                                <TouchableOpacity 
                                    key={slot} 
                                    style={[styles.slotButton, isSelected && styles.slotButtonActive]}
                                    onPress={() => setSelectedTimeSlot(slot)}
                                >
                                    <Text style={[styles.slotText, isSelected && styles.slotTextActive]}>{slot}</Text>
                                </TouchableOpacity>
                            )
                        })}
                    </View>
                </View>

                {/* Modalitiy Selection */}
                <View style={styles.section}>
                    <Text style={styles.sectionTitle}>Consultation Type</Text>
                    <View style={styles.modeRow}>
                        {doctor?.preferred_consultation_types?.map((mode) => {
                            const isSelected = selectedMode === mode
                            return (
                                <TouchableOpacity 
                                    key={mode} 
                                    style={[styles.modeButton, isSelected && styles.modeButtonActive]}
                                    onPress={() => setSelectedMode(mode)}
                                >
                                    <Text style={[styles.modeText, isSelected && styles.modeTextActive]}>
                                        {mode.charAt(0).toUpperCase() + mode.slice(1)}
                                    </Text>
                                </TouchableOpacity>
                            )
                        })}
                    </View>
                </View>

                {/* Reason */}
                <View style={[styles.section, { borderBottomWidth: 0 }]}>
                    <Text style={styles.sectionTitle}>Reason for Visit (Optional)</Text>
                    <TextInput 
                        style={styles.reasonInput}
                        placeholder="e.g. Annual checkup, flu symptoms..."
                        value={reason}
                        onChangeText={setReason}
                        multiline
                    />
                </View>

            </ScrollView>

            <View style={styles.footer}>
                <TouchableOpacity 
                    style={[styles.checkoutBtn, submitting && styles.checkoutDisabledBtn]}
                    onPress={handleBooking}
                    disabled={submitting}
                >
                    {submitting ? (
                        <ActivityIndicator color="#fff" />
                    ) : (
                        <Text style={styles.checkoutText}>Confirm Booking</Text>
                    )}
                </TouchableOpacity>
            </View>
        </SafeAreaView>
    )
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#f8fafc',
    },
    centerMode: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
    },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: 16,
        backgroundColor: '#ffffff',
        borderBottomWidth: 1,
        borderBottomColor: '#f1f5f9',
    },
    headerButton: {
        paddingVertical: 8,
        paddingHorizontal: 16,
        backgroundColor: '#f1f5f9',
        borderRadius: 20,
    },
    headerButtonText: {
        color: '#475569',
        fontSize: 14,
        fontWeight: '700',
    },
    headerTitle: {
        fontSize: 16,
        fontWeight: '700',
    },
    scrollContent: {
        paddingBottom: 40,
    },
    profileCard: {
        backgroundColor: '#ffffff',
        padding: 24,
        marginBottom: 8,
    },
    docName: {
        fontSize: 24,
        fontWeight: '800',
        color: '#0f172a',
        marginBottom: 4,
    },
    docSpec: {
        fontSize: 16,
        color: '#2563eb',
        fontWeight: '600',
        marginBottom: 12,
    },
    docFee: {
        color: '#64748b',
        fontWeight: '500',
    },
    section: {
        backgroundColor: '#ffffff',
        padding: 20,
        marginBottom: 8,
        borderBottomWidth: 1,
        borderBottomColor: '#f1f5f9',
    },
    sectionTitle: {
        fontSize: 16,
        fontWeight: '700',
        color: '#0f172a',
        marginBottom: 16,
    },
    dateDisplay: {
        backgroundColor: '#f8fafc',
        padding: 16,
        borderRadius: 12,
        alignItems: 'center',
    },
    dateText: {
        fontSize: 16,
        fontWeight: '600',
        color: '#334155',
    },
    slotGrid: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: 12,
    },
    slotButton: {
        width: '30%',
        paddingVertical: 12,
        alignItems: 'center',
        backgroundColor: '#f8fafc',
        borderRadius: 12,
        borderWidth: 1,
        borderColor: '#e2e8f0',
    },
    slotButtonActive: {
        backgroundColor: '#2563eb',
        borderColor: '#2563eb',
    },
    slotText: {
        fontWeight: '600',
        color: '#64748b',
    },
    slotTextActive: {
        color: '#ffffff',
    },
    modeRow: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: 12,
    },
    modeButton: {
        flex: 1,
        paddingVertical: 14,
        alignItems: 'center',
        backgroundColor: '#f8fafc',
        borderRadius: 12,
        borderWidth: 1,
        borderColor: '#e2e8f0',
    },
    modeButtonActive: {
        backgroundColor: '#0f172a',
        borderColor: '#0f172a',
    },
    modeText: {
        fontWeight: '700',
        color: '#64748b',
    },
    modeTextActive: {
        color: '#ffffff',
    },
    reasonInput: {
        backgroundColor: '#f8fafc',
        borderRadius: 12,
        padding: 16,
        minHeight: 100,
        textAlignVertical: 'top',
        fontSize: 15,
        borderWidth: 1,
        borderColor: '#e2e8f0',
    },
    footer: {
        backgroundColor: '#ffffff',
        padding: 24,
        borderTopWidth: 1,
        borderTopColor: '#f1f5f9',
    },
    checkoutBtn: {
        backgroundColor: '#2563eb',
        paddingVertical: 18,
        borderRadius: 16,
        alignItems: 'center',
    },
    checkoutDisabledBtn: {
        opacity: 0.7,
    },
    checkoutText: {
        color: '#ffffff',
        fontSize: 16,
        fontWeight: '800',
    }
})
