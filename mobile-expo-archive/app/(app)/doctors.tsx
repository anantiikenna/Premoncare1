import { useState, useCallback, useEffect } from 'react'
import { View, Text, StyleSheet, FlatList, ActivityIndicator, Image, TouchableOpacity, RefreshControl } from 'react-native'
import { useRouter } from 'expo-router'
import { supabase } from '../../lib/supabase'

type Profile = {
    id: string
    full_name: string
    avatar_url: string
    specialty: string
    experience_years: number
    languages_spoken: string
    preferred_consultation_types: string[]
}

export default function DoctorsScreen() {
    const router = useRouter()
    const [doctors, setDoctors] = useState<Profile[]>([])
    const [loading, setLoading] = useState(true)
    const [refreshing, setRefreshing] = useState(false)

    const fetchDoctors = useCallback(async () => {
        try {
            const { data, error } = await supabase
                .from('profiles')
                .select('*')
                .eq('role', 'doctor')
                .eq('verification_status', 'approved')

            if (error) throw error
            setDoctors(data as Profile[])
        } catch (error) {
            console.error('Error fetching doctors:', error)
        } finally {
            setLoading(false)
            setRefreshing(false)
        }
    }, [])

    useEffect(() => {
        fetchDoctors()
    }, [fetchDoctors])

    const onRefresh = () => {
        setRefreshing(true)
        fetchDoctors()
    }

    const renderDoctor = ({ item }: { item: Profile }) => (
        <View style={styles.card}>
            <View style={styles.cardHeader}>
                <Image 
                    source={{ uri: item.avatar_url || 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y' }} 
                    style={styles.avatar} 
                />
                <View style={styles.infoContainer}>
                    <Text style={styles.name}>{item.full_name || 'Dr. Practitioner'}</Text>
                    <Text style={styles.specialty}>{item.specialty || 'General Practice'} • {item.experience_years || 0} Yrs Exp</Text>
                </View>
            </View>
            
            {(item.preferred_consultation_types?.length > 0) && (
                <View style={styles.badgesContainer}>
                    {item.preferred_consultation_types.map(type => (
                        <View key={type} style={styles.badge}>
                            <Text style={styles.badgeText}>{type}</Text>
                        </View>
                    ))}
                </View>
            )}

            <TouchableOpacity 
                style={styles.bookButton} 
                onPress={() => router.push(`/(app)/book/${item.id}`)}
            >
                <Text style={styles.bookButtonText}>Book Appointment</Text>
            </TouchableOpacity>
        </View>
    )

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
                data={doctors}
                keyExtractor={(item) => item.id}
                renderItem={renderDoctor}
                contentContainerStyle={styles.list}
                refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
                ListEmptyComponent={
                    <View style={styles.emptyContainer}>
                        <Text style={styles.emptyText}>No verified doctors available yet.</Text>
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
        padding: 16,
        marginBottom: 16,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 8,
        elevation: 2,
    },
    cardHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: 16,
    },
    avatar: {
        width: 60,
        height: 60,
        borderRadius: 30,
        marginRight: 16,
        backgroundColor: '#f1f5f9',
    },
    infoContainer: {
        flex: 1,
    },
    name: {
        fontSize: 18,
        fontWeight: '800',
        color: '#0f172a',
        marginBottom: 4,
    },
    specialty: {
        fontSize: 14,
        color: '#64748b',
        fontWeight: '500',
    },
    badgesContainer: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: 8,
        marginBottom: 16,
    },
    badge: {
        backgroundColor: '#eff6ff',
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 20,
    },
    badgeText: {
        color: '#2563eb',
        fontSize: 12,
        fontWeight: '700',
    },
    bookButton: {
        backgroundColor: '#000000',
        paddingVertical: 14,
        borderRadius: 12,
        alignItems: 'center',
    },
    bookButtonText: {
        color: '#ffffff',
        fontSize: 15,
        fontWeight: '700',
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
