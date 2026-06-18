import { useState, useEffect, useCallback } from 'react'
import { View, Text, StyleSheet, FlatList, TouchableOpacity, ActivityIndicator, RefreshControl } from 'react-native'
import { useAuth } from '../../lib/auth-provider'
import { getUserNotifications, markNotificationAsRead, markAllNotificationsAsRead } from '../../lib/queries'
import { formatDistanceToNow } from 'date-fns'

export default function DoctorNotificationsScreen() {
    const { user, refreshUnreadCount } = useAuth()
    const [notifications, setNotifications] = useState<any[]>([])
    const [loading, setLoading] = useState(true)
    const [refreshing, setRefreshing] = useState(false)

    const fetchNotifications = useCallback(async () => {
        if (!user) return
        const { data, error } = await getUserNotifications(user.id)
        if (data) {
            setNotifications(data)
        }
        setLoading(false)
        setRefreshing(false)
    }, [user])

    useEffect(() => {
        fetchNotifications()
    }, [fetchNotifications])

    const onRefresh = () => {
        setRefreshing(true)
        fetchNotifications()
    }

    const handleMarkAsRead = async (id: string) => {
        await markNotificationAsRead(id)
        setNotifications(prev => prev.map(n => n.id === id ? { ...n, is_read: true } : n))
        refreshUnreadCount()
    }

    const handleMarkAllRead = async () => {
        if (!user) return
        await markAllNotificationsAsRead(user.id)
        setNotifications(prev => prev.map(n => ({ ...n, is_read: true })))
        refreshUnreadCount()
    }

    const getIcon = (type: string) => {
        switch (type) {
            case 'appointment': return '🏥'
            case 'payment': return '💰'
            case 'admin_message': return '⚖️'
            case 'system': return '🔧'
            case 'message': return '💬'
            default: return '📢'
        }
    }

    const renderNotification = ({ item }: { item: any }) => (
        <TouchableOpacity 
            style={[styles.card, !item.is_read && styles.unreadCard]} 
            onPress={() => !item.is_read && handleMarkAsRead(item.id)}
            disabled={item.is_read}
        >
            <View style={styles.cardHeader}>
                <View style={styles.iconContainer}>
                    <Text style={styles.icon}>{getIcon(item.type)}</Text>
                </View>
                <View style={styles.textContainer}>
                    <Text style={[styles.title, !item.is_read && styles.unreadTitle]}>{item.title}</Text>
                    <Text style={styles.time}>{formatDistanceToNow(new Date(item.created_at), { addSuffix: true })}</Text>
                </View>
                {!item.is_read && <View style={styles.unreadDot} />}
            </View>
            <Text style={styles.message} numberOfLines={3}>{item.message}</Text>
        </TouchableOpacity>
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
            <View style={styles.header}>
                <Text style={styles.headerTitle}>Practitioner Alerts</Text>
                {notifications.some(n => !n.is_read) && (
                    <TouchableOpacity onPress={handleMarkAllRead}>
                        <Text style={styles.markAllText}>Clear All</Text>
                    </TouchableOpacity>
                )}
            </View>
            <FlatList
                data={notifications}
                keyExtractor={(item) => item.id}
                renderItem={renderNotification}
                contentContainerStyle={styles.list}
                refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
                ListEmptyComponent={
                    <View style={styles.emptyContainer}>
                        <Text style={styles.emptyText}>No priority notifications found. All patients are currently in active care.</Text>
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
    },
    header: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingHorizontal: 24,
        paddingVertical: 16,
        backgroundColor: '#ffffff',
        borderBottomWidth: 1,
        borderBottomColor: '#f1f5f9',
    },
    headerTitle: {
        fontSize: 18,
        fontWeight: '900',
        color: '#0f172a',
        letterSpacing: -0.5,
    },
    markAllText: {
        fontSize: 12,
        fontWeight: '800',
        color: '#2563eb',
        textTransform: 'uppercase',
        letterSpacing: 1,
    },
    list: {
        padding: 16,
    },
    card: {
        backgroundColor: '#ffffff',
        padding: 16,
        borderRadius: 20,
        marginBottom: 12,
        borderWidth: 1,
        borderColor: '#f1f5f9',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.05,
        shadowRadius: 10,
        elevation: 2,
    },
    unreadCard: {
        backgroundColor: '#fff7ed',
        borderColor: '#ffedd5',
    },
    cardHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: 8,
    },
    iconContainer: {
        width: 44,
        height: 44,
        borderRadius: 12,
        backgroundColor: '#f1f5f9',
        alignItems: 'center',
        justifyContent: 'center',
        marginRight: 12,
    },
    icon: {
        fontSize: 24,
    },
    textContainer: {
        flex: 1,
    },
    title: {
        fontSize: 15,
        fontWeight: '700',
        color: '#475569',
    },
    unreadTitle: {
        color: '#7c2d12',
        fontWeight: '900',
    },
    time: {
        fontSize: 11,
        color: '#94a3b8',
        fontWeight: '600',
        marginTop: 2,
    },
    unreadDot: {
        width: 10,
        height: 10,
        borderRadius: 5,
        backgroundColor: '#f97316',
    },
    message: {
        fontSize: 14,
        color: '#64748b',
        lineHeight: 20,
        fontWeight: '500',
    },
    emptyContainer: {
        padding: 60,
        alignItems: 'center',
    },
    emptyText: {
        fontSize: 16,
        color: '#94a3b8',
        textAlign: 'center',
        fontWeight: '600',
        lineHeight: 24,
    }
})
