import { useState, useCallback, useEffect } from 'react'
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert, ActivityIndicator } from 'react-native'
import { useRouter } from 'expo-router'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../lib/auth-provider'

export default function DoctorDashboardScreen() {
    const { user, profile } = useAuth()
    const router = useRouter()
    const [stats, setStats] = useState({ pending: 0, confirmed: 0 })
    const [loading, setLoading] = useState(true)

    const fetchStats = useCallback(async () => {
        if (!user) return
        try {
            const { data, error } = await supabase
                .from('appointments')
                .select('status')
                .eq('doctor_id', user.id)

            if (error) throw error

            const pending = data?.filter(a => a.status === 'pending').length || 0
            const confirmed = data?.filter(a => a.status === 'confirmed').length || 0
            
            setStats({ pending, confirmed })
        } catch (error) {
            console.error('Error fetching doctor stats:', error)
        } finally {
            setLoading(false)
        }
    }, [user])

    useEffect(() => {
        fetchStats()
    }, [fetchStats])

    async function handleSignOut() {
        const { error } = await supabase.auth.signOut()
        if (error) {
            Alert.alert('Sign out error', error.message)
        } else {
            router.replace('/')
        }
    }

    if (loading) {
        return (
            <View style={styles.centerParams}>
                <ActivityIndicator size="large" color="#2563eb" />
            </View>
        )
    }

    return (
        <ScrollView style={styles.container} contentContainerStyle={styles.content}>
            <View style={styles.greetingSection}>
                <Text style={styles.greetingTitle}>Hello, Dr. {profile?.full_name?.split(' ')[0] || 'Practitioner'}</Text>
                <Text style={styles.greetingSubtitle}>Here's your schedule overview for today.</Text>
            </View>

            <View style={styles.statsContainer}>
                <View style={styles.statBox}>
                    <Text style={styles.statValue}>{stats.pending}</Text>
                    <Text style={styles.statLabel}>Pending Requests</Text>
                </View>
                <View style={[styles.statBox, { backgroundColor: '#f0fdf4', borderColor: '#dcfce7' }]}>
                    <Text style={[styles.statValue, { color: '#166534' }]}>{stats.confirmed}</Text>
                    <Text style={[styles.statLabel, { color: '#15803d' }]}>Confirmed Visits</Text>
                </View>
            </View>

            <View style={styles.cardContainer}>
                <TouchableOpacity style={styles.card} onPress={() => router.push('/(doctor)/schedule')}>
                    <View style={[styles.cardIcon, { backgroundColor: '#eff6ff' }]}>
                        <Text style={styles.cardEmoji}>📅</Text>
                    </View>
                    <View style={styles.cardTextContainer}>
                        <Text style={styles.cardTitle}>Manage Schedule</Text>
                        <Text style={styles.cardSubtitle}>Approve or decline appointments</Text>
                    </View>
                </TouchableOpacity>

                <TouchableOpacity 
                    style={styles.card} 
                    onPress={() => Alert.alert(
                        'Secure Negotiation', 
                        'Real-time fee negotiation is currently managed via the Secure Web Dashboard for enterprise protection. Mobile chat integration is arriving in the next security update.'
                    )}
                >
                    <View style={[styles.cardIcon, { backgroundColor: '#fdf4ff' }]}>
                        <Text style={styles.cardEmoji}>🛡️</Text>
                    </View>
                    <View style={styles.cardTextContainer}>
                        <Text style={styles.cardTitle}>Administration Hub</Text>
                        <Text style={styles.cardSubtitle}>Fee & Platform negotiations</Text>
                    </View>
                </TouchableOpacity>
            </View>

            <TouchableOpacity style={styles.logoutButton} onPress={handleSignOut}>
                <Text style={styles.logoutText}>Sign Out Securely</Text>
            </TouchableOpacity>
        </ScrollView>
    )
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#f8fafc',
    },
    content: {
        padding: 24,
    },
    centerParams: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#f8fafc',
    },
    greetingSection: {
        marginBottom: 32,
    },
    greetingTitle: {
        fontSize: 32,
        fontWeight: '800',
        color: '#0f172a',
        marginBottom: 8,
        letterSpacing: -0.5,
    },
    greetingSubtitle: {
        fontSize: 16,
        color: '#64748b',
        fontWeight: '500',
    },
    statsContainer: {
        flexDirection: 'row',
        gap: 16,
        marginBottom: 32,
    },
    statBox: {
        flex: 1,
        backgroundColor: '#fffbeb',
        borderColor: '#fef3c7',
        borderWidth: 1,
        padding: 20,
        borderRadius: 20,
        alignItems: 'center',
    },
    statValue: {
        fontSize: 36,
        fontWeight: '900',
        color: '#d97706',
        marginBottom: 4,
    },
    statLabel: {
        fontSize: 12,
        fontWeight: '700',
        color: '#b45309',
        textTransform: 'uppercase',
    },
    cardContainer: {
        gap: 16,
    },
    card: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: '#ffffff',
        padding: 20,
        borderRadius: 24,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.05,
        shadowRadius: 12,
        elevation: 2,
    },
    cardIcon: {
        width: 56,
        height: 56,
        borderRadius: 16,
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: 16,
    },
    cardEmoji: {
        fontSize: 24,
    },
    cardTextContainer: {
        flex: 1,
    },
    cardTitle: {
        fontSize: 18,
        fontWeight: '800',
        color: '#0f172a',
        marginBottom: 4,
    },
    cardSubtitle: {
        fontSize: 14,
        color: '#64748b',
        fontWeight: '500',
    },
    logoutButton: {
        marginTop: 40,
        padding: 16,
        borderRadius: 16,
        backgroundColor: '#fee2e2',
        alignItems: 'center',
    },
    logoutText: {
        color: '#ef4444',
        fontSize: 16,
        fontWeight: '800',
    }
})
