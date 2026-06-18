import { useState, useCallback, useEffect } from 'react'
import { View, Text, StyleSheet, FlatList, ActivityIndicator, TouchableOpacity, RefreshControl, Alert } from 'react-native'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../lib/auth-provider'

type Appointment = {
    id: string
    appointment_date: string
    status: string
    reason: string
    duration_minutes: number
    consultation_mode: string | null
    patient: {
        full_name: string
    }
}

export default function DoctorScheduleScreen() {
    const { user } = useAuth()
    const [appointments, setAppointments] = useState<Appointment[]>([])
    const [loading, setLoading] = useState(true)
    const [refreshing, setRefreshing] = useState(false)

    const fetchAppointments = useCallback(async () => {
        if (!user) return
        try {
            const { data, error } = await supabase
                .from('appointments')
                .select(`
                    id,
                    appointment_date,
                    status,
                    reason,
                    duration_minutes,
                    consultation_mode,
                    profiles!appointments_patient_id_fkey(full_name)
                `)
                .eq('doctor_id', user.id)
                .order('appointment_date', { ascending: true })

            if (error) throw error

            const formatted = data?.map((appt: any) => ({
                id: appt.id,
                appointment_date: appt.appointment_date,
                status: appt.status,
                reason: appt.reason,
                duration_minutes: appt.duration_minutes,
                consultation_mode: appt.consultation_mode,
                patient: { full_name: appt.profiles?.full_name || 'Patient' }
            }))

            setAppointments(formatted as Appointment[])
        } catch (error) {
            console.error('Error fetching appointments:', error)
        } finally {
            setLoading(false)
            setRefreshing(false)
        }
    }, [user])

    useEffect(() => {
        fetchAppointments()
    }, [fetchAppointments])

    const onRefresh = () => {
        setRefreshing(true)
        fetchAppointments()
    }

    const handleUpdateStatus = async (id: string, newStatus: string) => {
        try {
            const { error } = await supabase.from('appointments').update({ status: newStatus }).eq('id', id)
            if (error) throw error
            Alert.alert('Updated', `Appointment ${newStatus}.`)
            fetchAppointments()
        } catch (error: any) {
            Alert.alert('Error', error.message)
        }
    }

    const renderAppointment = ({ item }: { item: Appointment }) => {
        const dateObj = new Date(item.appointment_date)
        const timeString = dateObj.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        const dateString = dateObj.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' })
        const modeLabel = item.consultation_mode ? item.consultation_mode.replace('_', ' ').toUpperCase() : 'STANDARD'

        return (
            <View style={styles.card}>
                <View style={styles.cardHeader}>
                    <View style={styles.timeBlock}>
                        <Text style={styles.timeText}>{timeString}</Text>
                        <Text style={styles.dateText}>{dateString}</Text>
                    </View>
                    <View style={[styles.statusBadge, item.status === 'confirmed' ? styles.statusConfirmed : styles.statusPending]}>
                        <Text style={[styles.statusText, item.status === 'confirmed' ? styles.statusTextConfirmed : styles.statusTextPending]}>
                            {item.status.toUpperCase()}
                        </Text>
                    </View>
                </View>

                <View style={styles.cardBody}>
                    <Text style={styles.patientName}>{item.patient.full_name}</Text>
                    <Text style={styles.modeText}>Mode: <Text style={{ color: '#0f172a' }}>{modeLabel}</Text></Text>
                    <Text style={styles.reasonText} numberOfLines={2}>Reason: {item.reason || 'No reason provided'}</Text>
                </View>

                {item.status === 'pending' && (
                    <View style={styles.actionRow}>
                        <TouchableOpacity style={[styles.actionBtn, styles.declineBtn]} onPress={() => handleUpdateStatus(item.id, 'cancelled')}>
                            <Text style={styles.declineText}>Decline</Text>
                        </TouchableOpacity>
                        <TouchableOpacity style={[styles.actionBtn, styles.approveBtn]} onPress={() => handleUpdateStatus(item.id, 'confirmed')}>
                            <Text style={styles.approveText}>Approve</Text>
                        </TouchableOpacity>
                    </View>
                )}
            </View>
        )
    }

    if (loading) {
        return (
            <View style={styles.centerParams}>
                <ActivityIndicator size="large" color="#2563eb" />
            </View>
        )
    }

    return (
        <View style={styles.container}>
            <FlatList
                data={appointments}
                refreshed={refreshing}
                onRefresh={onRefresh}
                keyExtractor={(item) => item.id}
                renderItem={renderAppointment}
                contentContainerStyle={styles.list}
                ListEmptyComponent={
                    <View style={styles.emptyContainer}>
                        <Text style={styles.emptyText}>You have no upcoming appointments.</Text>
                    </View>
                }
            />
        </View>
    )
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#f8fafc',
    },
    centerParams: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#f8fafc',
    },
    list: {
        padding: 16,
    },
    card: {
        backgroundColor: '#ffffff',
        borderRadius: 20,
        padding: 20,
        marginBottom: 16,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 8,
        elevation: 2,
    },
    cardHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
        borderBottomWidth: 1,
        borderBottomColor: '#f1f5f9',
        paddingBottom: 16,
        marginBottom: 16,
    },
    timeBlock: {},
    timeText: {
        fontSize: 20,
        fontWeight: '900',
        color: '#0f172a',
        marginBottom: 4,
    },
    dateText: {
        fontSize: 14,
        color: '#64748b',
        fontWeight: '500',
    },
    statusBadge: {
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 20,
    },
    statusConfirmed: {
        backgroundColor: '#dcfce7',
    },
    statusPending: {
        backgroundColor: '#fef9c3',
    },
    statusText: {
        fontSize: 10,
        fontWeight: '900',
        letterSpacing: 0.5,
    },
    statusTextConfirmed: {
        color: '#166534',
    },
    statusTextPending: {
        color: '#854d0e',
    },
    cardBody: {
        gap: 8,
    },
    patientName: {
        fontSize: 18,
        fontWeight: '700',
        color: '#0f172a',
    },
    modeText: {
        fontSize: 13,
        fontWeight: '600',
        color: '#2563eb',
    },
    reasonText: {
        fontSize: 14,
        color: '#64748b',
        lineHeight: 20,
    },
    actionRow: {
        flexDirection: 'row',
        gap: 12,
        marginTop: 20,
        paddingTop: 16,
        borderTopWidth: 1,
        borderTopColor: '#f1f5f9',
    },
    actionBtn: {
        flex: 1,
        paddingVertical: 12,
        borderRadius: 12,
        alignItems: 'center',
    },
    declineBtn: {
        backgroundColor: '#fee2e2',
    },
    declineText: {
        color: '#ef4444',
        fontWeight: '800',
    },
    approveBtn: {
        backgroundColor: '#2563eb',
    },
    approveText: {
        color: '#ffffff',
        fontWeight: '800',
    }
})
