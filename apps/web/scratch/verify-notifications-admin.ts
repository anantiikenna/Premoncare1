import { createClient } from '@supabase/supabase-js';
import { sendNotification } from '../src/lib/notification-service';
import * as dotenv from 'dotenv';
import path from 'path';

// Load .env from root
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

async function testNotificationFlow() {
  console.log('🚀 Starting Admin Notification Verification...');
  
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  // 1. Find a test user
  const { data: profile } = await supabase
    .from('profiles')
    .select('id, full_name, fcm_token')
    .limit(1)
    .single();

  if (!profile) {
    console.error('❌ No profile found to test with.');
    return;
  }

  console.log(`👤 Testing with user: ${profile.full_name} (${profile.id})`);

  // 2. Trigger notification
  // Note: We are simulating the "server-side" environment here
  const result = await sendNotification({
    user_id: profile.id,
    title: 'Final System Check',
    message: 'The notification system has been fully unified and hardened.',
    type: 'system',
    link: '/dashboard',
  });

  console.log('✅ Result:', JSON.stringify(result, null, 2));

  if (result?.dbId) {
    console.log('⏳ Checking DB status update...');
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    const { data: notification } = await supabase
      .from('notifications')
      .select('fcm_status')
      .eq('id', result.dbId)
      .single();
      
    console.log(`📊 Delivery Status: [${notification?.fcm_status}]`);
    console.log('✨ Verification Complete.');
  }
}

testNotificationFlow().catch(console.error);
