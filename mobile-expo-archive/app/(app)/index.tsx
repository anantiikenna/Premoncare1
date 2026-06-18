import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert } from 'react-native'
import { useRouter } from 'expo-router'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../lib/auth-provider'

export default function DashboardScreen() {
    const { user } = useAuth()
    const router = useRouter()

    async function handleSignOut() {
        const { error } = await supabase.auth.signOut()
        if (error) {
            Alert.alert('Sign out error', error.message)
        }
    }

    return (
        <ScrollView style={styles.container} contentContainerStyle={styles.content}>
            <View style={styles.greetingSection}>
                <Text style={styles.greetingTitle}>Welcome Back,</Text>
                <Text style={styles.greetingEmail}>{user?.email}</Text>
            </View>

            <View style={styles.cardContainer}>
                <TouchableOpacity style={styles.card} onPress={() => router.push('/(app)/doctors')}>
                    <View style={[styles.cardIcon, { backgroundColor: '#eff6ff' }]}>
                        <Text style={styles.cardEmoji}>🏥</Text>
                    </View>
                    <View style={styles.cardTextContainer}>
                        <Text style={styles.cardTitle}>Find a Doctor</Text>
                        <Text style={styles.cardSubtitle}>Browse verified practitioners</Text>
                    </View>
                </TouchableOpacity>

                <TouchableOpacity style={styles.card} onPress={() => router.push('/(app)/vault')}>
                    <View style={[styles.cardIcon, { backgroundColor: '#f0fdf4' }]}>
                        <Text style={styles.cardEmoji}>🔒</Text>
                    </View>
                    <View style={styles.cardTextContainer}>
                        <Text style={styles.cardTitle}>Medical Vault</Text>
                        <Text style={styles.cardSubtitle}>Your secure health records</Text>
                    </View>
                </TouchableOpacity>
                
                <TouchableOpacity style={styles.card} onPress={() => Alert.alert('Prescriptions coming!')}>
                    <View style={[styles.cardIcon, { backgroundColor: '#fef2f2' }]}>
                        <Text style={styles.cardEmoji}>💊</Text>
                    </View>
                    <View style={styles.cardTextContainer}>
                        <Text style={styles.cardTitle}>Prescriptions</Text>
                        <Text style={styles.cardSubtitle}>View your active meds</Text>
                    </View>
                </TouchableOpacity>
            </View>

            <View style={styles.logoutWrapper}>
                <TouchableOpacity style={styles.logoutButton} onPress={handleSignOut}>
                    <Text style={styles.logoutButtonText}>Sign Out Securely</Text>
                </TouchableOpacity>
            </View>
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
    greetingSection: {
        marginBottom: 32,
    },
    greetingTitle: {
        fontSize: 16,
        color: '#64748b',
        fontWeight: '600',
    },
    greetingEmail: {
        fontSize: 24,
        fontWeight: '800',
        color: '#0f172a',
    },
    cardContainer: {
        gap: 16,
    },
    card: {
        backgroundColor: '#ffffff',
        borderRadius: 16,
        padding: 16,
        flexDirection: 'row',
        alignItems: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 8,
        elevation: 2,
    },
    cardIcon: {
        width: 56,
        height: 56,
        borderRadius: 12,
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
        fontSize: 16,
        fontWeight: '700',
        color: '#0f172a',
        marginBottom: 2,
    },
    cardSubtitle: {
        fontSize: 14,
        color: '#64748b',
    },
    logoutWrapper: {
        marginTop: 48,
    },
    logoutButton: {
        borderWidth: 1,
        borderColor: '#e2e8f0',
        padding: 16,
        borderRadius: 12,
        alignItems: 'center',
    },
    logoutButtonText: {
        color: '#ef4444',
        fontWeight: '700',
        fontSize: 16,
    },
})
