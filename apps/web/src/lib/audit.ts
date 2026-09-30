import { createClient } from '@/lib/supabase'

export interface AuditLogEntry {
    actor_id: string
    action: string
    target_user_id?: string
    resource_type?: string
    resource_id?: string
    details?: Record<string, unknown>
}

export async function logAuditEvent(entry: AuditLogEntry): Promise<void> {
    try {
        const supabase = createClient()
        const { error } = await supabase.from('audit_logs').insert({
            user_id: entry.actor_id,
            action: entry.action,
            details: {
                ...(entry.details || {}),
                ...(entry.target_user_id ? { target_user_id: entry.target_user_id } : {}),
                ...(entry.resource_type ? { resource_type: entry.resource_type } : {}),
                ...(entry.resource_id ? { resource_id: entry.resource_id } : {}),
            },
        })
        if (error) console.error('Audit log failed:', error.message)
    } catch (error) {
        console.error('Audit log failed:', error)
    }
}

export async function logPHIAccess(actorId: string, targetUserId: string, resourceType: string): Promise<void> {
    await logAuditEvent({
        actor_id: actorId,
        action: 'phi_access',
        target_user_id: targetUserId,
        resource_type: resourceType,
    })
}
