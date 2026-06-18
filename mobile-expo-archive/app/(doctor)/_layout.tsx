import { Text, View } from 'react-native'
import { useAuth } from '../../lib/auth-provider'
import { Tabs, Redirect } from 'expo-router'

export default function DoctorAppLayout() {
    const { session, profile, activePortal, unreadCount, initialized } = useAuth()

    if (!initialized) return null

    // Enforce guard
    if (!session || profile?.role !== 'doctor') {
        return <Redirect href="/" />
    }

    return (
        <Tabs
            screenOptions={{
                headerShown: true,
                headerStyle: { backgroundColor: '#ffffff' },
                headerTitleStyle: { color: '#0f172a', fontWeight: '800' },
                headerShadowVisible: false,
                tabBarActiveTintColor: '#2563eb',
                tabBarInactiveTintColor: '#94a3b8',
                tabBarStyle: {
                    backgroundColor: '#ffffff',
                    borderTopWidth: 1,
                    borderTopColor: '#f1f5f9',
                    elevation: 0,
                    height: 60,
                    paddingBottom: 8,
                    paddingTop: 8,
                },
                tabBarLabelStyle: {
                    fontWeight: '700',
                    fontSize: 10,
                }
            }}
        >
            <Tabs.Screen 
                name="index" 
                options={{
                    title: 'Practitioner Hub',
                    tabBarLabel: 'Home',
                    tabBarIcon: ({ color }) => <Text style={{ color, fontSize: 20 }}>🏠</Text>
                }}
            />
            <Tabs.Screen 
                name="schedule" 
                options={{
                    title: 'My Schedule',
                    tabBarLabel: 'Roster',
                    tabBarIcon: ({ color }) => <Text style={{ color, fontSize: 20 }}>📅</Text>
                }}
            />
            <Tabs.Screen 
                name="notifications" 
                options={{
                    title: 'System Alerts',
                    tabBarLabel: 'Alerts',
                    tabBarBadge: unreadCount > 0 ? unreadCount : undefined,
                    tabBarIcon: ({ color }) => <Text style={{ color, fontSize: 20 }}>🔔</Text>
                }}
            />
            <Tabs.Screen 
                name="profile" 
                options={{
                    title: 'Settings',
                    tabBarLabel: 'Profile',
                    tabBarIcon: ({ color }) => <Text style={{ color, fontSize: 20 }}>👤</Text>
                }}
            />
        </Tabs>
    )
}
