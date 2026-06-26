import { NotificationPayload } from './types';
import { createClient } from './supabase-server';
import { sendNotification as sendPush } from './notification-service';
import { sendEmail, templates } from './email-service';

/**
 * Centrally dispatches a notification to the database, push, and email channels.
 * This ensures that:
 * 1. The database record is created directly via Supabase (no self-referential HTTP).
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
    const { userId, title, message, type, link, sendEmail: shouldEmail, emailTemplate, emailData } = payload;

    try {
        const supabase = await createClient();

        // 1. Insert notification record directly (bypasses RLS since this runs server-side)
        const { error: insertError } = await supabase
            .from('notifications')
            .insert({
                user_id: userId,
                title,
                message,
                type,
                link: link || null,
            });

        if (insertError) {
            console.error('[Notification Dispatch] DB insert failed:', insertError);
            return { success: false, error: insertError.message };
        }

        // 2. Send push notification (non-blocking)
        let pushResult = null;
        try {
            pushResult = await sendPush({
                user_id: userId,
                title,
                message,
                type,
                link,
            });
        } catch (pushError) {
            console.error('[Notification Dispatch] Push failed:', pushError);
        }

        // 3. Optional: Send email
        let emailResult = null;
        if (shouldEmail && emailTemplate && emailData) {
            try {
                const { data: profile } = await supabase
                    .from('profiles')
                    .select('email, full_name, email_alerts_enabled')
                    .eq('id', userId)
                    .single();

                if (profile?.email && profile.email_alerts_enabled !== false) {
                    let emailContent = null;
                    if (emailTemplate === 'paymentApproval') {
                        emailContent = templates.paymentApproval(profile.full_name, emailData.amount as number, emailData.status as string);
                    } else if (emailTemplate === 'doctorAppointment') {
                        emailContent = templates.doctorAppointment(profile.full_name, emailData.patientName as string, emailData.date as string, emailData.duration as number);
                    }

                    if (emailContent) {
                        emailResult = await sendEmail({
                            to: profile.email,
                            subject: emailContent.subject,
                            html: emailContent.html,
                        });
                    }
                }
            } catch (emailError) {
                console.error('[Notification Dispatch] Email failed:', emailError);
            }
        }

        return { success: true, push: pushResult, email: emailResult };
    } catch (err) {
        console.error('[Notification Dispatch Error]:', err);
        return { success: false, error: err };
    }
}
