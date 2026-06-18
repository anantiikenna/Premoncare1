import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';
import { resolve } from 'path';

// Load env vars so we can use Supabase and Firebase
dotenv.config({ path: resolve(__dirname, '../.env.local') });

const userId = process.argv[2];

if (!userId) {
  console.error('Usage: npx tsx scratch/test-notification.ts <USER_ID>');
  process.exit(1);
}

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY || '';
const supabase = createClient(supabaseUrl, supabaseKey);

async function runTest() {
  console.log(`🚀 Sending test notification to user: ${userId}...`);
  
  // 1. Fetch user's FCM token
  const { data: profile, error } = await supabase
    .from('profiles')
    .select('fcm_token')
    .eq('id', userId)
    .single();

  if (error || !profile) {
    console.error('Error fetching user profile:', error?.message || 'User not found');
    return;
  }

  if (!profile.fcm_token) {
    console.error('User does not have an FCM token. Please log in on the mobile app to sync the token.');
    return;
  }

  console.log('📌 FCM Token found:', profile.fcm_token.substring(0, 20) + '...');

  const { messaging } = await import('../src/lib/firebase-admin');

  if (!messaging) {
    console.error('Firebase Admin SDK is not initialized correctly. Check .env.local keys.');
    return;
  }

  // 2. Send via FCM
  try {
    const message = {
      notification: {
        title: 'Test Notification',
        body: 'Hello! This is a test push notification from Premon Care.',
      },
      data: {
        type: 'system',
        link: '/dashboard',
      },
      token: profile.fcm_token,
    };

    const response = await messaging.send(message);
    console.log('✅ FCM Success! Message ID:', response);
  } catch (err) {
    console.error('❌ FCM Error:', err);
  }
}

runTest().catch(console.error);
