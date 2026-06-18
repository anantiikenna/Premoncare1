import { useEffect } from 'react'
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ActivityIndicator } from 'react-native'
import { useRouter } from 'expo-router'
import { useAuth } from '../lib/auth-provider'

export default function LandingScreen() {
    const router = useRouter()
    const { user, activePortal, initialized } = useAuth()

    useEffect(() => {
        if (initialized && user) {
            if (activePortal === 'doctor') {
                router.replace('/(doctor)')
            } else {
                router.replace('/(app)') 
            }
        }
    }, [user, activePortal, initialized])

    if (!initialized) {
        return (
            <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
                <ActivityIndicator size="large" color="#2563eb" />
            </View>
        )
    }

    return (
        <SafeAreaView style={styles.container}>
            <View style={styles.header}>
                <View style={styles.logoContainer}>
                    <Text style={styles.logoText}>Premon</Text>
                    <View style={styles.logoDot} />
                </View>
                <Text style={styles.subtitle}>Premium Healthcare at Your Fingertips</Text>
            </View>

            <View style={styles.footer}>
                <TouchableOpacity style={styles.loginButton} onPress={() => router.push('/auth/login')}>
                    <Text style={styles.loginButtonText}>Sign In</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.registerButton} onPress={() => router.push('/auth/register')}>
                    <Text style={styles.registerButtonText}>Create Account</Text>
                </TouchableOpacity>
            </View>
        </SafeAreaView>
    )
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#ffffff',
        justifyContent: 'space-between',
        padding: 24,
    },
    header: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
    },
    logoContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: 16,
    },
    logoText: {
        fontSize: 48,
        fontWeight: '900',
        color: '#000000',
        letterSpacing: -1.5,
    },
    logoDot: {
        width: 12,
        height: 12,
        borderRadius: 6,
        backgroundColor: '#2563eb', // Primary Blue
        marginLeft: 4,
        marginTop: 20,
    },
    subtitle: {
        fontSize: 16,
        color: '#64748b',
        fontWeight: '500',
        textAlign: 'center',
        paddingHorizontal: 32,
    },
    footer: {
        paddingBottom: 24,
        gap: 16,
    },
    loginButton: {
        backgroundColor: '#000000',
        paddingVertical: 18,
        borderRadius: 16,
        alignItems: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.1,
        shadowRadius: 8,
        elevation: 3,
    },
    loginButtonText: {
        color: '#ffffff',
        fontSize: 16,
        fontWeight: '700',
    },
    registerButton: {
        backgroundColor: '#f1f5f9',
        paddingVertical: 18,
        borderRadius: 16,
        alignItems: 'center',
    },
    registerButtonText: {
        color: '#0f172a',
        fontSize: 16,
        fontWeight: '700',
    },
})
