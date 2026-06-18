import { Tabs, Redirect } from 'expo-router'
import { ActivityIndicator, View } from 'react-native'
import { useAuth } from '../../lib/auth-provider'

export default function AppLayout() {
    const { user, initialized, unreadCount } = useAuth()

    if (!initialized) {
        return (
            <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
                <ActivityIndicator size="large" color="#2563eb" />
            </View>
        )
    }

    if (!user) {
        // If not authenticated, force them out
        return <Redirect href="/" />
    }

    return (
        <Tabs screenOptions={{ 
            headerShown: true, 
            tabBarActiveTintColor: '#2563eb',
            tabBarInactiveTintColor: '#94a3b8',
            tabBarStyle: {
                borderTopWidth: 1,
                borderTopColor: '#f1f5f9',
                backgroundColor: '#ffffff',
                height: 60,
                paddingBottom: 8,
                paddingTop: 8,
            },
            headerStyle: {
                backgroundColor: '#ffffff',
                borderBottomWidth: 1,
                borderBottomColor: '#f1f5f9',
                shadowOpacity: 0,
                elevation: 0,
            },
            headerTitleStyle: {
                fontWeight: '800',
                color: '#0f172a',
            }
        }}>
            <Tabs.Screen 
                name="index" 
                options={{
                    title: 'Dashboard',
                    tabBarLabel: 'Home',
                }}
            />
            <Tabs.Screen 
                name="doctors" 
                options={{
                    title: 'Find Doctors',
                    tabBarLabel: 'Doctors',
                }}
            />
            <Tabs.Screen 
                name="appointments" 
                options={{
                    title: 'Appointments',
                }}
            />
            <Tabs.Screen 
                name="vault" 
                options={{
                    title: 'Medical Vault',
                    tabBarLabel: 'Vault',
                }}
            />
            <Tabs.Screen 
                name="notifications" 
                options={{
                    title: 'Alerts',
                    tabBarLabel: 'Notifications',
                    tabBarBadge: unreadCount > 0 ? unreadCount : undefined,
                }}
            />
            <Tabs.Screen 
                name="profile" 
                options={{
                    title: 'Profile',
                }}
            />
        </Tabs>
    )
}
