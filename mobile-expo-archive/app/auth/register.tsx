import { useState } from 'react'
import { View, Text, StyleSheet, TextInput, TouchableOpacity, SafeAreaView, KeyboardAvoidingView, Platform, ActivityIndicator, Alert, ScrollView } from 'react-native'
import { useRouter } from 'expo-router'
import { supabase } from '../../lib/supabase'

export default function RegisterScreen() {
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [fullName, setFullName] = useState('')
    const [loading, setLoading] = useState(false)
    const router = useRouter()

    async function signUpWithEmail() {
        if (!email || !password || !fullName) {
            Alert.alert('Error', 'Please fill in all fields')
            return
        }
        setLoading(true)
        
        // Register user
        const { data, error } = await supabase.auth.signUp({
            email,
            password,
            options: {
                data: {
                    full_name: fullName,
                }
            }
        })

        if (error) {
            Alert.alert('Registration Failed', error.message)
            setLoading(false)
        } else {
            Alert.alert('Success', 'Please check your email for verification link!')
            router.replace('/auth/login')
            setLoading(false)
        }
    }

    return (
        <SafeAreaView style={styles.container}>
            <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.keyboardView}>
                <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scrollContent}>
                    <View style={styles.header}>
                        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
                            <Text style={styles.backText}>✕ Cancel</Text>
                        </TouchableOpacity>
                        <Text style={styles.title}>Create Account</Text>
                        <Text style={styles.subtitle}>Join Premon Care for premium healthcare services.</Text>
                    </View>

                    <View style={styles.formContainer}>
                        <View style={styles.inputGroup}>
                            <Text style={styles.label}>Full Name</Text>
                            <TextInput
                                style={styles.input}
                                onChangeText={setFullName}
                                value={fullName}
                                placeholder="John Doe"
                                autoCapitalize="words"
                            />
                        </View>

                        <View style={styles.inputGroup}>
                            <Text style={styles.label}>Email Address</Text>
                            <TextInput
                                style={styles.input}
                                onChangeText={setEmail}
                                value={email}
                                placeholder="patient@example.com"
                                autoCapitalize="none"
                                keyboardType="email-address"
                            />
                        </View>

                        <View style={styles.inputGroup}>
                            <Text style={styles.label}>Password</Text>
                            <TextInput
                                style={styles.input}
                                onChangeText={setPassword}
                                value={password}
                                secureTextEntry={true}
                                placeholder="••••••••"
                            />
                        </View>

                        <TouchableOpacity 
                            style={[styles.primaryButton, loading && styles.disabledButton]} 
                            onPress={signUpWithEmail}
                            disabled={loading}
                        >
                            {loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.primaryButtonText}>Sign Up</Text>}
                        </TouchableOpacity>
                        
                        <View style={styles.ssoFallback}>
                            <Text style={styles.ssoText}>Or register with</Text>
                            <View style={styles.ssoRow}>
                                <TouchableOpacity style={styles.ssoBtn} onPress={() => Alert.alert('Google Signup Pending')}>
                                    <Text style={styles.ssoBtnText}>G Google</Text>
                                </TouchableOpacity>
                            </View>
                        </View>
                    </View>

                    <View style={styles.footer}>
                        <Text style={styles.footerText}>Already have an account? </Text>
                        <TouchableOpacity onPress={() => router.push('/auth/login')}>
                            <Text style={styles.footerLink}>Sign In</Text>
                        </TouchableOpacity>
                    </View>
                </ScrollView>
            </KeyboardAvoidingView>
        </SafeAreaView>
    )
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#ffffff',
    },
    keyboardView: {
        flex: 1,
    },
    scrollContent: {
        padding: 24,
        flexGrow: 1,
        justifyContent: 'center',
    },
    header: {
        marginBottom: 32,
        marginTop: 20,
    },
    backButton: {
        marginBottom: 16,
        alignSelf: 'flex-start',
        paddingVertical: 8,
        paddingHorizontal: 16,
        backgroundColor: '#f1f5f9',
        borderRadius: 20,
    },
    backText: {
        color: '#475569',
        fontSize: 14,
        fontWeight: '700',
    },
    title: {
        fontSize: 32,
        fontWeight: '800',
        color: '#0f172a',
        marginBottom: 8,
        letterSpacing: -0.5,
    },
    subtitle: {
        fontSize: 16,
        color: '#64748b',
        fontWeight: '500',
    },
    formContainer: {
        gap: 20,
    },
    inputGroup: {
        gap: 8,
    },
    label: {
        fontSize: 14,
        fontWeight: '700',
        color: '#334155',
    },
    input: {
        borderWidth: 1,
        borderColor: '#e2e8f0',
        padding: 16,
        borderRadius: 12,
        fontSize: 16,
        backgroundColor: '#f8fafc',
    },
    primaryButton: {
        backgroundColor: '#000000',
        padding: 18,
        borderRadius: 12,
        alignItems: 'center',
        marginTop: 8,
    },
    primaryButtonText: {
        color: '#ffffff',
        fontSize: 16,
        fontWeight: '700',
    },
    disabledButton: {
        opacity: 0.7,
    },
    ssoFallback: {
        marginTop: 24,
        alignItems: 'center',
        borderTopWidth: 1,
        borderTopColor: '#f1f5f9',
        paddingTop: 24,
    },
    ssoText: {
        color: '#94a3b8',
        fontSize: 14,
        fontWeight: '600',
        marginBottom: 16,
    },
    ssoRow: {
        flexDirection: 'row',
        gap: 12,
        width: '100%',
    },
    ssoBtn: {
        flex: 1,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 14,
        borderWidth: 1,
        borderColor: '#e2e8f0',
        borderRadius: 12,
    },
    ssoBtnText: {
        fontWeight: '700',
        fontSize: 16,
        color: '#0f172a',
    },
    footer: {
        flexDirection: 'row',
        justifyContent: 'center',
        marginTop: 32,
        marginBottom: 20,
    },
    footerText: {
        color: '#64748b',
        fontSize: 15,
    },
    footerLink: {
        color: '#2563eb',
        fontSize: 15,
        fontWeight: '700',
    },
})
