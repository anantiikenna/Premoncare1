import { useState, useCallback, useEffect } from 'react'
import { View, Text, StyleSheet, FlatList, ActivityIndicator, RefreshControl } from 'react-native'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../lib/auth-provider'

type Appointment = {
    id: string
    doctor_id: string
    patient_id: string
    scheduled_at: string
    status: string
    amount: number
    doctor?: {
        full_name: string
        specialty: string
    }
}

export default function AppointmentsScreen() {
    const { user } = useAuth()
    const [appointments, setAppointments] = useState<Appointment[]>([])
    const [loading, setLoading] = useState(true)
    const [refreshing, setRefreshing] = useState(false)

    const fetchAppointments = useCallback(async () => {
        if (!user) return
        try {
            const { data, error } = await supabase
                .from('appointments')
                .select('*, doctor:profiles!doctor_id(full_name, specialty)')
                .eq('patient_id', user.id)
                .order('scheduled_at', { ascending: true })

            if (error) throw error
            setAppointments(data as any[])
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

    const renderAppointment = ({ item }: { item: Appointment }) => {
        const date = new Date(item.scheduled_at)
        const isUpcoming = date > new Date()
        
        return (
            <View style={[styles.card, !isUpcoming && styles.cardPast]}>
                <View style={styles.cardHeader}>
                    <Text style={styles.doctorName}>{item.doctor?.full_name || 'Unknown Doctor'}</Text>
                    <View style={[styles.statusBadge, item.status === 'confirmed' ? styles.statusConfirmed : styles.statusPending]}>
                        <Text style={styles.statusText}>{item.status.toUpperCase()}</Text>
                    </View>
                </View>
                <Text style={styles.specialty}>{item.doctor?.specialty}</Text>
                
                <View style={styles.dateBlock}>
                    <Text style={styles.dateText}>
                        {date.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })}
                    </Text>
                    <Text style={styles.timeText}>
                        {date.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' })}
                    </Text>
                </View>
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
                keyExtractor={(item) => item.id}
                renderItem={renderAppointment}
                contentContainerStyle={styles.list}
                refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
                ListEmptyComponent={
                    <View style={styles.emptyContainer}>
                        <Text style={styles.emptyText}>You have no appointments scheduled.</Text>
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
        borderRadius: 16,
        padding: 20,
        marginBottom: 16,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 8,
        elevation: 2,
        borderLeftWidth: 4,
        borderLeftColor: '#2563eb',
    },
    cardPast: {
        opacity: 0.7,
        borderLeftColor: '#cbd5e1',
    },
    cardHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 4,
    },
    doctorName: {
        fontSize: 18,
        fontWeight: '800',
        color: '#0f172a',
    },
    statusBadge: {
        paddingHorizontal: 10,
        paddingVertical: 4,
        borderRadius: 12,
    },
    statusConfirmed: {
        backgroundColor: '#dcfce7',
    },
    statusPending: {
        backgroundColor: '#fef9c3',
    },
    statusText: {
        fontSize: 10,
        fontWeight: '800',
        color: '#0f172a',
    },
    specialty: {
        fontSize: 14,
        color: '#64748b',
        fontWeight: '500',
        marginBottom: 16,
    },
    dateBlock: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        backgroundColor: '#f1f5f9',
        padding: 12,
        borderRadius: 8,
    },
    dateText: {
        fontWeight: '700',
        color: '#334155',
    },
    timeText: {
        fontWeight: '700',
        color: '#2563eb',
    },
    emptyContainer: {
        padding: 32,
        alignItems: 'center',
    },
    emptyText: {
        color: '#64748b',
        fontSize: 15,
        textAlign: 'center',
    }
})
