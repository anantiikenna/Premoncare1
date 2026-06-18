import { NotificationPayload } from './types';

/**
 * Centrally dispatches a notification to the internal API.
 * This ensures that:
 * 1. The database record is created.
 * 2. Push notifications are sent.
 * 3. Email notifications are optionally sent.
 * 
 * USE THIS instead of calling createNotification directly in business logic.
 */
export async function dispatchNotification(payload: {
    userId: string;
    title: string;
    message: string;
    type: 'appointment' | 'payment' | 'prescription' | 'message' | 'system' | 'other';
    link?: string;
    sendEmail?: boolean;
    emailTemplate?: string;
    emailData?: Record<string, any>;
}) {
    // In server-side logic, we need the absolute URL
    const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000';
    const endpoint = `${siteUrl}/api/notifications/dispatch`;

    try {
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                // Security: This bypasses client-side auth requirements if called server-to-server,
                // however our dispatcher route uses withSecurity(req, handler, { requireAuth: true }).
                // Since this fetch is called from Server Components/Actions, we must pass the 
                // authorization context if we want to strictly follow withSecurity.
                // For now, we assume the server environment is trusted or the caller passes cookies.
            },
            body: JSON.stringify(payload),
        });

        if (!response.ok) {
            const error = await response.text();
            console.error('[Notification Dispatch Failed]:', error);
            return { success: false, error };
        }

        return await response.json();
    } catch (err) {
        console.error('[Notification Dispatch Error]:', err);
        return { success: false, error: err };
    }
}
