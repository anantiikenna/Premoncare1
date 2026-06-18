import React, { createContext, useContext, useEffect, useState } from 'react'
import { Session, User } from '@supabase/supabase-js'
import { supabase } from './supabase'
import AsyncStorage from '@react-native-async-storage/async-storage'

type Profile = {
    id: string;
    role: string;
    verification_status: string;
    [key: string]: any;
}

type AuthContextType = {
    session: Session | null;
    user: User | null;
    profile: Profile | null;
    activePortal: 'patient' | 'doctor';
    unreadCount: number;
    initialized: boolean;
    togglePortal: () => void;
    refreshUnreadCount: () => void;
}

const AuthContext = createContext<AuthContextType>({
    session: null,
    user: null,
    profile: null,
    activePortal: 'patient',
    unreadCount: 0,
    initialized: false,
    togglePortal: () => {},
    refreshUnreadCount: () => {},
})

export function AuthProvider({ children }: { children: React.ReactNode }) {
    const [session, setSession] = useState<Session | null>(null)
    const [user, setUser] = useState<User | null>(null)
    const [profile, setProfile] = useState<Profile | null>(null)
    const [activePortal, setActivePortal] = useState<'patient' | 'doctor'>('patient')
    const [unreadCount, setUnreadCount] = useState(0)
    const [initialized, setInitialized] = useState(false)

    const fetchProfile = async (uid: string) => {
        try {
            const { data } = await supabase.from('profiles').select('*').eq('id', uid).single()
            if (data) {
                setProfile(data as Profile)
                
                // Load persisted portal choice
                const savedPortal = await AsyncStorage.getItem(`active_portal_${uid}`)
                if (savedPortal === 'patient' || savedPortal === 'doctor') {
                    setActivePortal(savedPortal)
                } else {
                    setActivePortal((data.role === 'doctor' ? 'doctor' : 'patient'))
                }
            }
        } catch (e) {
            console.error('Error fetching profile map', e)
        }
    }

    const refreshUnreadCount = async () => {
        if (!user) return
        const { data } = await supabase
            .from('notifications')
            .select('id', { count: 'exact' })
            .eq('user_id', user.id)
            .eq('is_read', false)
        
        setUnreadCount(data?.length || 0)
    }

    const togglePortal = async () => {
        const nextPortal = activePortal === 'doctor' ? 'patient' : 'doctor'
        setActivePortal(nextPortal)
        if (user) {
            await AsyncStorage.setItem(`active_portal_${user.id}`, nextPortal)
        }
    }

    useEffect(() => {
        // Initial session fetch
        supabase.auth.getSession().then(({ data: { session } }) => {
            setSession(session)
            setUser(session?.user ?? null)
            if (session?.user) {
                fetchProfile(session.user.id).then(() => {
                    refreshUnreadCount()
                    setInitialized(true)
                })
            } else {
                setInitialized(true)
            }
        })

        // Listen for auth changes
        const { data: { subscription } } = supabase.auth.onAuthStateChange(
            async (_event, session) => {
                setSession(session)
                setUser(session?.user ?? null)
                if (session?.user) {
                    await fetchProfile(session.user.id)
                    await refreshUnreadCount()
                } else {
                    setProfile(null)
                    setActivePortal('patient')
                    setUnreadCount(0)
                }
            }
        )

        return () => subscription.unsubscribe()
    }, [])

    // Real-time listener for notifications
    useEffect(() => {
        if (!user) return

        const channel = supabase
            .channel(`public:notifications:user_id=eq.${user.id}`)
            .on(
                'postgres_changes',
                {
                    event: '*',
                    schema: 'public',
                    table: 'notifications',
                    filter: `user_id=eq.${user.id}`
                },
                () => {
                    refreshUnreadCount()
                }
            )
            .subscribe()

        return () => {
            supabase.removeChannel(channel)
        }
    }, [user])

    return (
        <AuthContext.Provider value={{ session, user, profile, activePortal, unreadCount, initialized, togglePortal, refreshUnreadCount }}>
            {children}
        </AuthContext.Provider>
    )
}

export const useAuth = () => useContext(AuthContext)
