import { View, Text, StyleSheet, TouchableOpacity, Alert } from 'react-native'
import { useRouter } from 'expo-router'
import { supabase } from '../../lib/supabase'
import { useAuth } from '../../lib/auth-provider'

export default function ProfileScreen() {
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

    return (
        <View style={styles.container}>
            <View style={styles.header}>
                <View style={styles.avatarPlaceholder}>
                    <Text style={styles.avatarText}>{profile?.full_name?.[0] || user?.email?.[0].toUpperCase()}</Text>
                </View>
                <Text style={styles.title}>{profile?.full_name || 'Your Profile'}</Text>
                <Text style={styles.subtitle}>{user?.email}</Text>
            </View>

            <View style={styles.menuContainer}>
                {profile?.role === 'doctor' && (
                    <TouchableOpacity 
                        style={styles.menuItem} 
                        onPress={() => {
                            togglePortal()
                            router.replace('/')
                        }}
                    >
                        <View>
                            <Text style={styles.menuItemTitle}>Professional Mode</Text>
                            <Text style={styles.menuItemSubtitle}>Switch back to Doctor Hub</Text>
                        </View>
                        <Text style={styles.menuEmoji}>🩺</Text>
                    </TouchableOpacity>
                )}

                <TouchableOpacity style={[styles.menuItem, styles.logoutItem]} onPress={handleSignOut}>
                    <View>
                        <Text style={[styles.menuItemTitle, { color: '#ef4444' }]}>System Exit</Text>
                        <Text style={styles.menuItemSubtitle}>Sign out of Premon Care</Text>
                    </View>
                    <Text style={styles.menuEmoji}>🚪</Text>
                </TouchableOpacity>
            </View>
        </View>
    )
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#f8fafc',
    },
    header: {
        backgroundColor: '#ffffff',
        padding: 32,
        alignItems: 'center',
        borderBottomWidth: 1,
        borderBottomColor: '#f1f5f9',
    },
    avatarPlaceholder: {
        width: 80,
        height: 80,
        borderRadius: 40,
        backgroundColor: '#2563eb',
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: 16,
    },
    avatarText: {
        color: '#ffffff',
        fontSize: 32,
        fontWeight: 'bold',
    },
    title: {
        fontSize: 24,
        fontWeight: '800',
        color: '#0f172a',
        marginBottom: 4,
    },
    subtitle: {
        fontSize: 14,
        color: '#64748b',
        fontWeight: '500',
    },
    menuContainer: {
        padding: 20,
        gap: 12,
    },
    menuItem: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        backgroundColor: '#ffffff',
        padding: 20,
        borderRadius: 20,
        borderWidth: 1,
        borderColor: '#f1f5f9',
    },
    menuItemTitle: {
        fontSize: 16,
        fontWeight: '800',
        color: '#0f172a',
        marginBottom: 2,
    },
    menuItemSubtitle: {
        fontSize: 12,
        color: '#64748b',
        fontWeight: '600',
    },
    menuEmoji: {
        fontSize: 24,
    },
    logoutItem: {
        marginTop: 12,
        borderColor: '#fee2e2',
    },
})
