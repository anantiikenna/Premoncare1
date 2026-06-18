import { sendNotification } from '../src/lib/notification-service';
import { createClient } from '../src/lib/supabase-server';

async function testNotificationFlow() {
  console.log('🚀 Starting Notification Flow Verification...');

  // 1. Find a test user (ideally one without a token first to test 'skipped')
  const supabase = await createClient();
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
  console.log(`🎫 FCM Token present: ${!!profile.fcm_token}`);

  // 2. Trigger a notification
  const result = await sendNotification({
    user_id: profile.id,
    title: 'Verification Test',
    message: 'Testing the unified notification hardening logic.',
    type: 'system',
    link: '/dashboard',
  });

  console.log('✅ sendNotification called. Result:', JSON.stringify(result, null, 2));

  if (result?.dbId) {
    // 3. Wait a moment for async status update
    console.log('⏳ Waiting for status update...');
    await new Promise(resolve => setTimeout(resolve, 2000));

    // 4. Verify DB status
    const { data: notification } = await supabase
      .from('notifications')
      .select('id, fcm_status')
      .eq('id', result.dbId)
      .single();

    console.log(`📊 Final DB Status: [${notification?.fcm_status}]`);
    
    if (profile.fcm_token) {
        if (notification?.fcm_status === 'sent' || notification?.fcm_status === 'failed') {
            console.log('✨ SUCCESS: status tracked correctly for token user.');
        } else {
            console.warn('⚠️ WARNING: status stayed pending? Check async update logic.');
        }
    } else {
        if (notification?.fcm_status === 'skipped') {
            console.log('✨ SUCCESS: status correctly marked as skipped.');
        } else {
            console.warn('⚠️ WARNING: status expected to be skipped.');
        }
    }
  } else {
    console.error('❌ No DB Record ID returned.');
  }
}

testNotificationFlow().catch(console.error);
