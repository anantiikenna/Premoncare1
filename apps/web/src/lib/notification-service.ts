import { createClient } from './supabase-server';
import { getMessaging } from './firebase-admin';
import { NotificationPayload } from './types';
import { sendLoopsEmail } from './loops-service';
import { createClient as createSupabaseClient } from '@supabase/supabase-js';

/**
 * Send a notification to a specific user.
 * This will:
 * 1. Record the notification in the Supabase 'notifications' table.
 * 2. Attempt to send a push notification via FCM if the user has a token.
 * 3. Attempt to send an email via Loops if payload.send_email is true.
 */
export async function sendNotification(payload: NotificationPayload) {
  const supabase = await createClient();

  // 1. Record in Database
  // We include fcm_status: 'pending' to track the attempt
  const { data: dbRecord, error: dbError } = await supabase
    .from('notifications')
    .insert({
      user_id: payload.user_id,
      title: payload.title,
      message: payload.message,
      type: payload.type,
      link: payload.link,
      fcm_status: 'pending'
    })
    .select()
    .single();

  if (dbError) {
    console.error('Error saving notification to DB:', dbError);
  }

  // Helper to update status
  const updateStatus = async (status: 'sent' | 'failed' | 'skipped') => {
    if (dbRecord?.id) {
       await supabase.from('notifications').update({ fcm_status: status }).eq('id', dbRecord.id);
    }
  };

  // 2. Send Email via Loops (if requested)
  if (payload.send_email) {
    try {
        // We need the admin client to bypass RLS and read auth.users to get the email securely
        const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY
        if (!serviceKey) {
            console.error('[FATAL] SUPABASE_SERVICE_ROLE_KEY is not set. Cannot fetch user email for notification.')
            return
        }
        const supabaseAdmin = createSupabaseClient(
            process.env.NEXT_PUBLIC_SUPABASE_URL!,
            serviceKey
        );
        
        const { data: { user }, error: userError } = await supabaseAdmin.auth.admin.getUserById(payload.user_id);
        
        if (user?.email && !userError) {
            await sendLoopsEmail(user.email, payload.title, payload.message, payload.type);
        } else {
            console.error('Failed to fetch user email for notification:', userError);
        }
    } catch (e) {
        console.error('Error in Loops dispatch:', e);
    }
  }

  // 3. Send via FCM
  try {
    // Fetch user's FCM token
    const { data: profile } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', payload.user_id)
      .single();

    if (profile?.fcm_token) {
      const messaging = getMessaging();
      if (!messaging) {
        await updateStatus('skipped');
        return { success: true, dbId: dbRecord?.id };
      }

      const message = {
        notification: {
          title: payload.title,
          body: payload.message,
        },
        data: {
          type: payload.type,
          link: payload.link || '',
          db_id: dbRecord?.id || '',
        },
        token: profile.fcm_token,
      };

      const response = await messaging.send(message);
      await updateStatus('sent');
      return { success: true, messageId: response, dbId: dbRecord?.id };
    } else {
      await updateStatus('skipped');
      return { success: true, dbId: dbRecord?.id };
    }
  } catch (error) {
    console.error('FCM Error:', error);
    await updateStatus('failed');
    return { success: true, dbId: dbRecord?.id, fcmError: error };
  }
}
