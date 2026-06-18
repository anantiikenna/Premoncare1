import { supabase } from './supabase'

export async function getUserNotifications(userId: string) {
    return await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
}

export async function markNotificationAsRead(id: string) {
    return await supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('id', id)
}

export async function markAllNotificationsAsRead(userId: string) {
    return await supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('user_id', userId)
        .eq('is_read', false)
}

export async function deleteNotification(id: string) {
    return await supabase
        .from('notifications')
        .delete()
        .eq('id', id)
}
