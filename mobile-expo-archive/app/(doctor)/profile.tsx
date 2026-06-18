import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Alert, Image } from 'react-native'
import { useRouter } from 'expo-router'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../lib/auth-provider'

export default function DoctorProfileScreen() {
    const { user, profile, togglePortal } = useAuth()
    const router = useRouter()

    async function handleSignOut() {
        const { error } = await supabase.auth.signOut()
        if (error) {
            Alert.alert('Sign out error', error.message)
        } else {
            router.replace('/')
        }
    }

    const initials = profile?.full_name ? profile.full_name.split(' ').map((n: string) => n[0]).join('') : user?.email?.[0].toUpperCase()

    return (
        <ScrollView style={styles.container} contentContainerStyle={styles.content}>
            <View style={styles.header}>
                <View style={styles.avatarContainer}>
                    {profile?.avatar_url ? (
                        <Image source={{ uri: profile.avatar_url }} style={styles.avatar} />
                    ) : (
                        <View style={styles.initialsAvatar}>
                            <Text style={styles.initialsText}>{initials}</Text>
                        </View>
                    )}
                </View>
                <Text style={styles.name}>{profile?.full_name || 'Practitioner Name'}</Text>
                <Text style={styles.specialty}>{profile?.specialty || 'Medical Specialist'}</Text>
                
                <View style={styles.badgeContainer}>
                    <View style={[styles.badge, profile?.verification_status === 'approved' ? styles.badgeApproved : styles.badgePending]}>
                        <Text style={[styles.badgeText, profile?.verification_status === 'approved' ? styles.badgeTextApproved : styles.badgeTextPending]}>
                            {profile?.verification_status === 'approved' ? 'VERIFIED' : 'PENDING REVIEW'}
                        </Text>
                    </View>
                </View>
            </View>

            <View style={styles.section}>
                <Text style={styles.sectionTitle}>Professional Credentials</Text>
                <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>License Number</Text>
                    <Text style={styles.infoValue}>{profile?.medical_license_number || 'Not provided'}</Text>
                </View>
                <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>Years of Experience</Text>
                    <Text style={styles.infoValue}>{profile?.experience_years ? `${profile.experience_years} Years` : 'Not provided'}</Text>
                </View>
                <View style={styles.line} />
                <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>Email</Text>
                    <Text style={styles.infoValue}>{user?.email}</Text>
                </View>
            </View>

            <View style={styles.section}>
                <Text style={styles.sectionTitle}>Account Statistics</Text>
                <View style={styles.statsRow}>
                    <View style={styles.statItem}>
                        <Text style={styles.statLabel}>Subscription</Text>
                        <Text style={[styles.statValue, { color: profile?.subscription_status === 'active' ? '#166534' : '#64748b' }]}>
                            {profile?.subscription_status?.toUpperCase() || 'INACTIVE'}
                        </Text>
                    </View>
                    <View style={styles.statItem}>
                        <Text style={styles.statLabel}>Avg. Fee</Text>
                        <Text style={styles.statValue}>₦{profile?.consultation_fee || '0'}</Text>
                    </View>
                </View>
            </View>

            <TouchableOpacity 
                style={[styles.section, { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }]} 
                onPress={() => {
                    togglePortal()
                    router.replace('/')
                }}
            >
                <View>
                    <Text style={[styles.sectionTitle, { marginBottom: 4 }]}>Portal Switch</Text>
                    <Text style={{ fontSize: 16, fontWeight: '800', color: '#2563eb' }}>Switch to Patient mode</Text>
                </View>
                <Text style={{ fontSize: 24 }}>🔄</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.logoutButton} onPress={handleSignOut}>
                <Text style={styles.logoutText}>Sign Out Securely</Text>
            </TouchableOpacity>

            <Text style={styles.footerText}>Premon Care v1.0.4 • The Art of Modern Wellness</Text>
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
        paddingBottom: 40,
    },
    header: {
        alignItems: 'center',
        marginBottom: 32,
    },
    avatarContainer: {
        width: 100,
        height: 100,
        borderRadius: 50,
        backgroundColor: '#fff',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.1,
        shadowRadius: 12,
        elevation: 4,
        marginBottom: 16,
        padding: 4,
    },
    avatar: {
        width: '100%',
        height: '100%',
        borderRadius: 46,
    },
    initialsAvatar: {
        width: '100%',
        height: '100%',
        borderRadius: 46,
        backgroundColor: '#2563eb',
        alignItems: 'center',
        justifyContent: 'center',
    },
    initialsText: {
        color: '#ffffff',
        fontSize: 36,
        fontWeight: 'bold',
    },
    name: {
        fontSize: 24,
        fontWeight: '900',
        color: '#0f172a',
        letterSpacing: -0.5,
    },
    specialty: {
        fontSize: 16,
        color: '#64748b',
        fontWeight: '600',
        marginTop: 4,
    },
    badgeContainer: {
        marginTop: 12,
    },
    badge: {
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 20,
    },
    badgeApproved: {
        backgroundColor: '#dcfce7',
    },
    badgePending: {
        backgroundColor: '#fee2e2',
    },
    badgeText: {
        fontSize: 10,
        fontWeight: '900',
        letterSpacing: 1,
    },
    badgeTextApproved: {
        color: '#166534',
    },
    badgeTextPending: {
        color: '#991b1b',
    },
    section: {
        backgroundColor: '#ffffff',
        padding: 20,
        borderRadius: 24,
        marginBottom: 16,
        borderWidth: 1,
        borderColor: '#f1f5f9',
    },
    sectionTitle: {
        fontSize: 12,
        fontWeight: '900',
        color: '#94a3b8',
        textTransform: 'uppercase',
        letterSpacing: 1,
        marginBottom: 16,
    },
    infoRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingVertical: 4,
    },
    infoLabel: {
        fontSize: 14,
        color: '#64748b',
        fontWeight: '500',
    },
    infoValue: {
        fontSize: 15,
        fontWeight: '700',
        color: '#0f172a',
    },
    line: {
        height: 1,
        backgroundColor: '#f1f5f9',
        marginVertical: 12,
    },
    statsRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
    },
    statItem: {
        flex: 1,
    },
    statLabel: {
        fontSize: 11,
        color: '#64748b',
        fontWeight: '700',
        marginBottom: 4,
    },
    statValue: {
        fontSize: 18,
        fontWeight: '900',
        color: '#0f172a',
    },
    logoutButton: {
        marginTop: 24,
        padding: 18,
        borderRadius: 20,
        backgroundColor: '#fee2e2',
        alignItems: 'center',
    },
    logoutText: {
        color: '#ef4444',
        fontSize: 16,
        fontWeight: '800',
    },
    footerText: {
        textAlign: 'center',
        marginTop: 40,
        fontSize: 10,
        color: '#94a3b8',
        fontWeight: '800',
        textTransform: 'uppercase',
        letterSpacing: 2,
    }
})
