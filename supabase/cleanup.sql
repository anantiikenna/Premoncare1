-- ============================================================
-- Premoncare Database Cleanup Script
-- Reverse of schema.sql — tears down everything in dependency order
-- Last Updated: 2026-08-24
-- ============================================================

SET ROLE postgres;

-- ============================================================
-- 1. REMOVE TABLES FROM REALTIME PUBLICATION
-- ============================================================
DO $$ BEGIN
  alter publication supabase_realtime drop table if exists forum_follows;
  alter publication supabase_realtime drop table if exists forum_saves;
  alter publication supabase_realtime drop table if exists forum_reports;
  alter publication supabase_realtime drop table if exists forum_replies;
  alter publication supabase_realtime drop table if exists forum_posts;
  alter publication supabase_realtime drop table if exists forum_categories;
  alter publication supabase_realtime drop table if exists fee_negotiation_messages;
  alter publication supabase_realtime drop table if exists reviews;
  alter publication supabase_realtime drop table if exists medical_records;
  alter publication supabase_realtime drop table if exists time_balances;
  alter publication supabase_realtime drop table if exists payments;
  alter publication supabase_realtime drop table if exists profiles;
  alter publication supabase_realtime drop table if exists doctor_schedules;
  alter publication supabase_realtime drop table if exists notifications;
  alter publication supabase_realtime drop table if exists messages;
  alter publication supabase_realtime drop table if exists appointments;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping publication drops: %', SQLERRM;
END $$;

-- ============================================================
-- 2. DROP VIEWS
-- ============================================================
DROP VIEW IF EXISTS public.pending_payments_view;

-- ============================================================
-- 3. DROP STORAGE POLICIES
-- ============================================================
-- patient-medical-vault
DROP POLICY IF EXISTS "Patients can select their own medical vault documents" ON storage.objects;
DROP POLICY IF EXISTS "Patients can update their own medical vault documents" ON storage.objects;
DROP POLICY IF EXISTS "Patients can delete their own medical vault documents" ON storage.objects;
DROP POLICY IF EXISTS "Patients can upload their own medical vault documents" ON storage.objects;
DROP POLICY IF EXISTS "Doctors can view shared medical vault documents" ON storage.objects;

-- payment-receipts
DROP POLICY IF EXISTS "Users can select their own payment receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own payment receipts" ON storage.objects;
DROP POLICY IF EXISTS "Patients can upload their own payment receipts" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all payment receipts" ON storage.objects;
DROP POLICY IF EXISTS "Doctors can view receipts sent to them" ON storage.objects;

-- medical-documents
DROP POLICY IF EXISTS "Patients can select their own medical documents" ON storage.objects;
DROP POLICY IF EXISTS "Patients can upload their own medical documents" ON storage.objects;
DROP POLICY IF EXISTS "Patients can update their own medical documents" ON storage.objects;

-- patient-verifications
DROP POLICY IF EXISTS "Users can select their own verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Patients can upload their own verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all verification documents" ON storage.objects;

-- doctor-verifications
DROP POLICY IF EXISTS "Users can select their own professional credentials" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own professional credentials" ON storage.objects;
DROP POLICY IF EXISTS "Doctors can upload their own professional credentials" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all professional credentials" ON storage.objects;

-- doctor-identities
DROP POLICY IF EXISTS "Users can select their own identities" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own identities" ON storage.objects;
DROP POLICY IF EXISTS "Doctors can upload their own identities" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all identities" ON storage.objects;

-- avatars
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars" ON storage.objects;

-- ============================================================
-- 4. DROP STORAGE BUCKETS
-- ============================================================
DELETE FROM storage.buckets WHERE id IN (
  'avatars', 'doctor-identities', 'doctor-verifications',
  'patient-verifications', 'medical-documents', 'payment-receipts',
  'patient-medical-vault'
);

-- ============================================================
-- 5. DROP TRIGGERS
-- ============================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_doctor_promotion ON profiles;
DROP TRIGGER IF EXISTS on_review_change ON reviews;
DROP TRIGGER IF EXISTS on_appointment_completed ON appointments;

-- ============================================================
-- 6. DROP TABLES (reverse dependency order)
-- ============================================================
-- Forum ecosystem (no downstream dependents)
DROP TABLE IF EXISTS forum_follows;
DROP TABLE IF EXISTS forum_saves;
DROP TABLE IF EXISTS forum_reports;
DROP TABLE IF EXISTS forum_replies;
DROP TABLE IF EXISTS forum_posts;
DROP TABLE IF EXISTS forum_categories;

-- Moderation & disputes
DROP TABLE IF EXISTS notification_channels_config;
DROP TABLE IF EXISTS blocked_users;
DROP TABLE IF EXISTS disputes;
DROP TABLE IF EXISTS refunds;
DROP TABLE IF EXISTS payouts;

-- Security & rate limiting
DROP TABLE IF EXISTS login_attempts;
DROP TABLE IF EXISTS device_sessions;
DROP TABLE IF EXISTS audit_logs;

-- Admin
DROP TABLE IF EXISTS admin_notification_settings;

-- Medical (prescriptions depend on appointments & profiles)
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS medical_profiles;
DROP TABLE IF EXISTS record_permissions;
DROP TABLE IF EXISTS medical_documents;
DROP TABLE IF EXISTS health_records;

-- Forum RPC functions reference these, drop after tables
DROP TABLE IF EXISTS medical_records;

-- Subscriptions
DROP TABLE IF EXISTS doctor_subscriptions;
DROP TABLE IF EXISTS subscription_plans;

-- Reviews (trigger depends on this)
DROP TABLE IF EXISTS reviews;

-- Fee negotiations
DROP TABLE IF EXISTS fee_negotiation_messages;

-- Notifications
DROP TABLE IF EXISTS notifications;

-- Messaging
DROP TABLE IF EXISTS messages;

-- Payments (appointments FK references this)
DROP TABLE IF EXISTS payments;

-- Time balances
DROP TABLE IF EXISTS time_balances;

-- Appointments (FK to payments, profiles)
DROP TABLE IF EXISTS appointments;

-- Doctor schedules (FK to profiles)
DROP TABLE IF EXISTS doctor_schedules;

-- System settings
DROP TABLE IF EXISTS system_settings;

-- Profiles (core table — drop last among user data)
DROP TABLE IF EXISTS profiles;

-- ============================================================
-- 7. DROP FUNCTIONS (CASCADE removes dependent triggers)
-- ============================================================
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.initialize_doctor_schedule() CASCADE;
DROP FUNCTION IF EXISTS public.update_doctor_review_count() CASCADE;
DROP FUNCTION IF EXISTS public.update_doctor_consultation_count() CASCADE;
DROP FUNCTION IF EXISTS public.increment_forum_upvote(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.increment_reply_helpful(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.increment_time_balance(UUID, UUID, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.approve_payment(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.reject_payment(UUID, TEXT, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.sweep_offline_doctors() CASCADE;
DROP FUNCTION IF EXISTS public.soft_delete_user(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.purge_deleted_accounts() CASCADE;
DROP FUNCTION IF EXISTS public.export_user_data(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.log_phi_access(UUID, TEXT, TEXT, UUID, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.cleanup_old_notifications() CASCADE;
DROP FUNCTION IF EXISTS public.cleanup_old_device_sessions() CASCADE;
DROP FUNCTION IF EXISTS public.cleanup_old_login_attempts() CASCADE;
DROP FUNCTION IF EXISTS public.check_otp_rate_limit(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.record_otp_attempt(TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.reset_otp_attempts(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.doctor_has_record_access(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.get_admin_financial_stats() CASCADE;

-- ============================================================
-- 8. DROP ENUMS
-- ============================================================
DROP TYPE IF EXISTS dispute_status;
DROP TYPE IF EXISTS refund_status;
DROP TYPE IF EXISTS payout_status;
DROP TYPE IF EXISTS audit_severity;
DROP TYPE IF EXISTS audit_action_type;
DROP TYPE IF EXISTS record_type;
DROP TYPE IF EXISTS payment_method;
DROP TYPE IF EXISTS payment_status;
DROP TYPE IF EXISTS account_status;
DROP TYPE IF EXISTS forum_report_status;
DROP TYPE IF EXISTS forum_post_status;
DROP TYPE IF EXISTS fee_status;
DROP TYPE IF EXISTS subscription_status;
DROP TYPE IF EXISTS verification_status;
DROP TYPE IF EXISTS user_role;

-- ============================================================
-- 9. EXTENSIONS (optional — uncomment for full reset)
-- ============================================================
-- DROP EXTENSION IF EXISTS "uuid-ossp";
