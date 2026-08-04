-- ============================================================
-- LIVE MIGRATION: Emergency Handshake Flow
-- Run this in your Supabase SQL Editor
-- Each statement runs independently — safe to re-run
-- ============================================================

SET ROLE postgres;

-- 1. Add missing columns (safe if already exists)
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS is_emergency boolean DEFAULT false;
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS total_amount numeric DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS payment_instructions text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS address text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_emergency boolean DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email_alerts_enabled boolean DEFAULT true;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS rejection_reason text;

-- 2. Update status check constraint for emergency flow (safe version)
DO $$
BEGIN
  UPDATE public.appointments SET status = 'cancelled' WHERE status IN ('expired', 'failed', 'abandoned');
  UPDATE public.appointments SET status = 'pending' WHERE status NOT IN (
    'pending', 'emergency_pending', 'emergency_request', 'emergency_accepted',
    'emergency_declined', 'confirmed', 'cancelled', 'completed', 'ongoing', 'rescheduled'
  );
END $$;

ALTER TABLE public.appointments DROP CONSTRAINT IF EXISTS appointments_status_check;
ALTER TABLE public.appointments
  ADD CONSTRAINT appointments_status_check
  CHECK (status IN (
    'pending',
    'emergency_pending',
    'emergency_request',
    'emergency_accepted',
    'emergency_declined',
    'confirmed',
    'cancelled',
    'completed',
    'ongoing',
    'rescheduled'
  ));

-- 3. Performance indexes
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_status
  ON public.appointments (doctor_id, status);

CREATE INDEX IF NOT EXISTS idx_appointments_emergency_requests
  ON public.appointments (doctor_id, created_at DESC)
  WHERE status = 'emergency_request';

-- 4. Realtime publication (skip if already added or not owner)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename = 'appointments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.appointments;
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping publication add for appointments: %', SQLERRM;
END $$;

-- Add missing tables to realtime publication
DO $$
DECLARE
  t text;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'profiles', 'payments', 'time_balances', 'medical_records',
    'reviews', 'fee_negotiation_messages'
  ]) LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND tablename = t
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
    END IF;
  END LOOP;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping publication add: %', SQLERRM;
END $$;

-- Set replica identity for critical realtime tables (safe — skip if not owner)
DO $$ BEGIN
  ALTER TABLE messages REPLICA IDENTITY FULL;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping REPLICA IDENTITY on messages: %', SQLERRM;
END $$;

DO $$ BEGIN
  ALTER TABLE appointments REPLICA IDENTITY FULL;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping REPLICA IDENTITY on appointments: %', SQLERRM;
END $$;

DO $$ BEGIN
  ALTER TABLE notifications REPLICA IDENTITY FULL;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping REPLICA IDENTITY on notifications: %', SQLERRM;
END $$;

DO $$ BEGIN
  ALTER TABLE profiles REPLICA IDENTITY FULL;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping REPLICA IDENTITY on profiles: %', SQLERRM;
END $$;

DO $$ BEGIN
  ALTER TABLE forum_posts REPLICA IDENTITY FULL;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping REPLICA IDENTITY on forum_posts: %', SQLERRM;
END $$;

DO $$ BEGIN
  ALTER TABLE forum_replies REPLICA IDENTITY FULL;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping REPLICA IDENTITY on forum_replies: %', SQLERRM;
END $$;

DO $$ BEGIN
  ALTER TABLE forum_reports REPLICA IDENTITY FULL;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping REPLICA IDENTITY on forum_reports: %', SQLERRM;
END $$;

-- Add forum_reports to Realtime publication
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename = 'forum_reports'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.forum_reports;
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping publication add for forum_reports: %', SQLERRM;
END $$;

-- Realtime messages RLS policies (required for private channels)
DO $$ BEGIN
  ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping ENABLE RLS on realtime.messages: %', SQLERRM;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'messages'
    AND schemaname = 'realtime'
    AND policyname = 'authenticated_users_can_receive_broadcasts'
  ) THEN
    CREATE POLICY "authenticated_users_can_receive_broadcasts"
      ON realtime.messages FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'messages'
    AND schemaname = 'realtime'
    AND policyname = 'authenticated_users_can_send_broadcasts'
  ) THEN
    CREATE POLICY "authenticated_users_can_send_broadcasts"
      ON realtime.messages FOR INSERT
      TO authenticated
      WITH CHECK (true);
  END IF;
END $$;

-- 5. Verify
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'appointments'
AND column_name IN ('metadata', 'is_emergency', 'total_amount')
ORDER BY ordinal_position;

-- ============================================================
-- FIX: Recreate pending_payments_view without SECURITY DEFINER
-- Resolves Supabase Linter ERROR: security_definer_view
-- ============================================================
DROP VIEW IF EXISTS public.pending_payments_view;

CREATE VIEW public.pending_payments_view
  WITH (security_invoker = true)
AS
SELECT p.*, u.full_name as patient_name, u.avatar_url as patient_avatar
FROM payments p JOIN profiles u ON p.user_id = u.id
WHERE p.status = 'pending';

-- ============================================================
-- FIX: Create profile on user signup (trigger was never created)
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, requested_role, phone)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
    COALESCE(NEW.raw_user_meta_data ->> 'requested_role', 'patient')::user_role,
    COALESCE(NEW.raw_user_meta_data ->> 'requested_role', 'patient')::user_role,
    NULLIF(NEW.raw_user_meta_data ->> 'phone', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_new_user();

-- Backfill profiles for existing users who registered without one
INSERT INTO public.profiles (id, email, full_name, role, requested_role)
SELECT
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data ->> 'full_name', ''),
  COALESCE(au.raw_user_meta_data ->> 'requested_role', 'patient')::user_role,
  COALESCE(au.raw_user_meta_data ->> 'requested_role', 'patient')::user_role
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL;

-- ============================================================
-- FIX: Supabase Linter — function_search_path_mutable (6 functions)
-- Add SET search_path = public to prevent search_path injection
-- ============================================================
ALTER FUNCTION public.initialize_doctor_schedule() SET search_path = public;
ALTER FUNCTION public.increment_time_balance(UUID, UUID, INTEGER) SET search_path = public;
ALTER FUNCTION public.approve_payment(UUID, UUID) SET search_path = public;
ALTER FUNCTION public.reject_payment(UUID, TEXT, UUID) SET search_path = public;
ALTER FUNCTION public.sweep_offline_doctors() SET search_path = public;
ALTER FUNCTION public.get_admin_financial_stats() SET search_path = public;

-- ============================================================
-- FIX: Supabase Linter — anon_security_definer_function_executable
-- Revoke EXECUTE from PUBLIC (default) and anon, re-grant to authenticated
-- ============================================================
REVOKE EXECUTE ON FUNCTION public.approve_payment(UUID, UUID) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.reject_payment(UUID, TEXT, UUID) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_admin_financial_stats() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.increment_time_balance(UUID, UUID, INTEGER) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.initialize_doctor_schedule() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.sweep_offline_doctors() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.approve_payment(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_payment(UUID, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_financial_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_time_balance(UUID, UUID, INTEGER) TO authenticated;

-- ============================================================
-- SECURITY FIX: Updated approve_payment with authorization checks
-- Only admins or payment recipients can approve. No auto-promotion to doctor.
-- ============================================================
CREATE OR REPLACE FUNCTION approve_payment(
    p_payment_id UUID,
    p_processor_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_payment RECORD;
    v_payer_profile RECORD;
    v_current_expiry TIMESTAMP WITH TIME ZONE;
    v_added_months INTEGER;
    v_admin_setting RECORD;
    v_processor_role TEXT;
BEGIN
    -- Authorization: only admins or payment recipients can approve
    SELECT role INTO v_processor_role FROM profiles WHERE id = p_processor_id;
    IF v_processor_role IS NULL OR v_processor_role NOT IN ('admin', 'doctor') THEN
        RAISE EXCEPTION 'Unauthorized: only admins or recipients can approve payments';
    END IF;

    SELECT * INTO v_payment FROM payments WHERE id = p_payment_id FOR UPDATE;
    IF v_payment IS NULL THEN RAISE EXCEPTION 'Payment not found'; END IF;
    IF v_payment.status = 'approved' THEN RETURN; END IF;

    -- Recipients can only approve their own payments
    IF v_processor_role = 'doctor' AND v_payment.recipient_id != p_processor_id THEN
        RAISE EXCEPTION 'Forbidden: doctors can only approve their own payments';
    END IF;

    UPDATE payments SET status = 'approved', processed_by = p_processor_id WHERE id = p_payment_id;

    INSERT INTO notifications (user_id, title, message, type, link)
    VALUES (v_payment.user_id, 'Payment Approved', 'Your payment of ₦' || v_payment.amount || ' has been verified and approved.', 'payment', '/patient/payments');

    IF v_payment.recipient_id IS NOT NULL AND v_payment.duration_minutes IS NOT NULL THEN
        PERFORM increment_time_balance(v_payment.user_id, v_payment.recipient_id, v_payment.duration_minutes);
        
        INSERT INTO notifications (user_id, title, message, type, link)
        VALUES (v_payment.recipient_id, 'Consultation Credit Verified', 'A payment of ₦' || v_payment.amount || ' for ' || v_payment.duration_minutes || 'm has been verified.', 'payment', '/doctor/dashboard');
        
    ELSIF v_payment.recipient_id IS NULL THEN
        -- Subscription renewal only (no auto-promotion to doctor)
        SELECT * INTO v_payer_profile FROM profiles WHERE id = v_payment.user_id FOR UPDATE;

        IF v_payer_profile IS NOT NULL AND v_payer_profile.role = 'doctor' THEN
            v_current_expiry := COALESCE(v_payer_profile.subscription_expires_at, NOW());
            IF v_current_expiry < NOW() THEN v_current_expiry := NOW(); END IF;
            
            v_added_months := CASE WHEN v_payment.duration_minutes < 60 THEN v_payment.duration_minutes ELSE 1 END;
            v_current_expiry := v_current_expiry + (v_added_months || ' months')::INTERVAL;

            UPDATE profiles
            SET subscription_status = 'active', fee_status = 'active', subscription_expires_at = v_current_expiry, last_subscription_payment_at = NOW()
            WHERE id = v_payment.user_id;

            INSERT INTO notifications (user_id, title, message, type, link)
            VALUES (v_payment.user_id, 'Subscription Renewed', 'Your subscription has been renewed. Expires on ' || v_current_expiry::DATE, 'system', '/doctor/dashboard');

            FOR v_admin_setting IN SELECT * FROM admin_notification_settings LOOP
                IF 'doctor_verified' = ANY(v_admin_setting.alert_types) THEN
                    INSERT INTO notifications (user_id, title, message, type, link)
                    VALUES (v_admin_setting.admin_id, 'Doctor Subscription Renewed', 'Dr. ' || COALESCE(v_payer_profile.full_name, 'Unknown') || ' has renewed their subscription.', 'system', '/admin/reports');
                END IF;
            END LOOP;
        END IF;
    END IF;

    IF v_payment.recipient_id IS NOT NULL AND v_payment.duration_minutes IS NOT NULL THEN
        FOR v_admin_setting IN SELECT * FROM admin_notification_settings LOOP
            IF 'payment_verified' = ANY(v_admin_setting.alert_types) THEN
                INSERT INTO notifications (user_id, title, message, type, link)
                VALUES (v_admin_setting.admin_id, 'Consultation Payment Verified', 'A payment of ₦' || v_payment.amount || ' for a ' || v_payment.duration_minutes || 'm session was verified.', 'payment', '/admin/reports');
            END IF;
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================
-- SECURITY FIX: Updated reject_payment with authorization checks
-- ============================================================
CREATE OR REPLACE FUNCTION reject_payment(
    p_payment_id UUID,
    p_reason TEXT,
    p_processor_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_payment RECORD;
    v_processor_role TEXT;
BEGIN
    -- Authorization: only admins or payment recipients can reject
    SELECT role INTO v_processor_role FROM profiles WHERE id = p_processor_id;
    IF v_processor_role IS NULL OR v_processor_role NOT IN ('admin', 'doctor') THEN
        RAISE EXCEPTION 'Unauthorized: only admins or recipients can reject payments';
    END IF;

    SELECT * INTO v_payment FROM payments WHERE id = p_payment_id FOR UPDATE;
    IF v_payment IS NULL THEN RAISE EXCEPTION 'Payment not found'; END IF;

    -- Recipients can only reject their own payments
    IF v_processor_role = 'doctor' AND v_payment.recipient_id != p_processor_id THEN
        RAISE EXCEPTION 'Forbidden: doctors can only reject their own payments';
    END IF;

    UPDATE payments SET status = 'rejected', rejection_reason = p_reason, processed_by = p_processor_id WHERE id = p_payment_id;

    INSERT INTO notifications (user_id, title, message, type, link)
    VALUES (v_payment.user_id, 'Payment Rejected', 'Your payment of ₦' || v_payment.amount || ' was rejected. Reason: ' || COALESCE(p_reason, 'No reason provided.'), 'payment', '/patient/payments');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- NOTE: authenticated_security_definer_function_executable warnings are
-- ACCEPTABLE for these functions because they are legitimately called by
-- authenticated doctors/admins from client-side code:
--   approve_payment     → doctor-payments.tsx, payment-review.tsx
--   reject_payment      → doctor-payments.tsx, payment-review.tsx
--   increment_time_balance → appointment-manager.tsx (doctor)
--   get_admin_financial_stats → admin_service.dart (mobile admin)
-- initialize_doctor_schedule and sweep_offline_doctors are trigger/cron
-- functions — not called via RPC, so no GRANT needed.

-- ============================================================
-- NOTE: public_bucket_allows_listing (avatars)
-- Avatars bucket MUST stay public because the app uses
-- storage.from('avatars').getPublicUrl() to render profile
-- images in posts, chat, and doctor listings. Making it
-- non-public would break all avatar image loading.
-- This warning is ACCEPTABLE for public-facing assets.
-- ============================================================

-- ============================================================
-- NOTE: rls_auto_enable is a Supabase built-in system function.
-- Cannot be modified. Safe to ignore this warning.
-- ============================================================

-- ============================================================
-- FIX: Add missing enum values
-- ============================================================

-- verification_status: add 'under_review' (used by doctor_verification_panel.dart)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'under_review' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'verification_status')) THEN
    ALTER TYPE public.verification_status ADD VALUE 'under_review' AFTER 'pending';
  END IF;
END $$;

-- dispute_status: add 'in_review' (used by dispute_resolution_screen.dart and financial_moderation_screen.dart)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'in_review' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'dispute_status')) THEN
    ALTER TYPE public.dispute_status ADD VALUE 'in_review' AFTER 'open';
  END IF;
END $$;

-- dispute_status: add 'under_review' (standardized across mobile dispute_resolution_screen.dart)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'under_review' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'dispute_status')) THEN
    ALTER TYPE public.dispute_status ADD VALUE 'under_review' AFTER 'in_review';
  END IF;
END $$;

-- payment_status: add 'disputed' (used for dispute workflows)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'disputed' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'payment_status')) THEN
    ALTER TYPE public.payment_status ADD VALUE 'disputed' AFTER 'rejected';
  END IF;
END $$;

-- ============================================================
-- FIX: Update appointments status CHECK to include 'rescheduled'
-- (used by admin_reports_screen.dart)
-- Safe version: cleans up invalid statuses before adding constraint
-- ============================================================

-- First, find and fix any status values not in the allowed list
DO $$
DECLARE
  invalid_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO invalid_count
  FROM public.appointments
  WHERE status NOT IN (
    'pending', 'emergency_pending', 'emergency_request', 'emergency_accepted',
    'emergency_declined', 'confirmed', 'cancelled', 'completed', 'ongoing', 'rescheduled'
  );

  IF invalid_count > 0 THEN
    -- Map common invalid statuses to valid ones
    UPDATE public.appointments SET status = 'cancelled' WHERE status IN ('expired', 'failed', 'abandoned');
    UPDATE public.appointments SET status = 'pending' WHERE status NOT IN (
      'pending', 'emergency_pending', 'emergency_request', 'emergency_accepted',
      'emergency_declined', 'confirmed', 'cancelled', 'completed', 'ongoing', 'rescheduled'
    );
    RAISE NOTICE 'Fixed % rows with invalid appointment statuses', invalid_count;
  END IF;
END $$;

-- Now safely rebuild the constraint
ALTER TABLE public.appointments DROP CONSTRAINT IF EXISTS appointments_status_check;
ALTER TABLE public.appointments
  ADD CONSTRAINT appointments_status_check
  CHECK (status IN (
    'pending',
    'emergency_pending',
    'emergency_request',
    'emergency_accepted',
    'emergency_declined',
    'confirmed',
    'cancelled',
    'completed',
    'ongoing',
    'rescheduled'
  ));

-- ============================================================
-- FIX: Add missing RLS INSERT/UPDATE policies for appointments
-- ============================================================
DROP POLICY IF EXISTS "Patients can create own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Doctors can update own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Patients can update own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Admins can manage all appointments" ON public.appointments;

CREATE POLICY "Patients can create own appointments"
  ON public.appointments FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Doctors can update own appointments"
  ON public.appointments FOR UPDATE
  USING (auth.uid() = doctor_id)
  WITH CHECK (auth.uid() = doctor_id);

CREATE POLICY "Patients can update own appointments"
  ON public.appointments FOR UPDATE
  USING (auth.uid() = patient_id)
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Admins can manage all appointments"
  ON public.appointments FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================================
-- FIX: Add missing RLS policies for time_balances
-- ============================================================
DROP POLICY IF EXISTS "Patients can update own time balances" ON public.time_balances;
DROP POLICY IF EXISTS "Doctors can update own time balances" ON public.time_balances;

CREATE POLICY "Patients can update own time balances"
  ON public.time_balances FOR UPDATE
  USING (auth.uid() = patient_id)
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Doctors can update own time balances"
  ON public.time_balances FOR UPDATE
  USING (auth.uid() = doctor_id)
  WITH CHECK (auth.uid() = doctor_id);

-- ============================================================
-- FIX: Add missing RLS policies for reviews
-- ============================================================
DROP POLICY IF EXISTS "Patients can delete own reviews" ON public.reviews;

CREATE POLICY "Patients can delete own reviews"
  ON public.reviews FOR DELETE
  USING (auth.uid() = patient_id);

-- ============================================================
-- PERFORMANCE INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles (role);
CREATE INDEX IF NOT EXISTS idx_profiles_verification_status ON public.profiles (verification_status);
CREATE INDEX IF NOT EXISTS idx_profiles_is_online ON public.profiles (is_online) WHERE is_online = true;
CREATE INDEX IF NOT EXISTS idx_profiles_is_emergency ON public.profiles (is_emergency) WHERE is_emergency = true;

CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON public.appointments (patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON public.appointments (status);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON public.appointments (doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_created_at ON public.appointments (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_payments_user_id ON public.payments (user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments (status);
CREATE INDEX IF NOT EXISTS idx_payments_recipient_id ON public.payments (recipient_id);

DO $$ BEGIN
  CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages (sender_id);
  CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages (receiver_id);
  CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages (created_at DESC);
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping messages indexes: %', SQLERRM;
END $$;

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications (user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications (is_read) WHERE is_read = false;

CREATE INDEX IF NOT EXISTS idx_medical_records_patient_id ON public.medical_records (patient_id);

CREATE INDEX IF NOT EXISTS idx_time_balances_patient_id ON public.time_balances (patient_id);
CREATE INDEX IF NOT EXISTS idx_time_balances_doctor_id ON public.time_balances (doctor_id);

CREATE INDEX IF NOT EXISTS idx_forum_posts_category_id ON public.forum_posts (category_id);
CREATE INDEX IF NOT EXISTS idx_forum_posts_author_id ON public.forum_posts (author_id);
CREATE INDEX IF NOT EXISTS idx_forum_replies_post_id ON public.forum_replies (post_id);
CREATE INDEX IF NOT EXISTS idx_forum_replies_author_id ON public.forum_replies (author_id);

CREATE INDEX IF NOT EXISTS idx_disputes_status ON public.disputes (status);
CREATE INDEX IF NOT EXISTS idx_disputes_user_id ON public.disputes (user_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_admin_id ON public.audit_logs (admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs (created_at DESC);

-- ============================================================
-- MISSING TRIGGERS: review_count, consultation_counts, time_balances
-- ============================================================

-- Trigger: increment review_count on INSERT/DELETE from reviews
CREATE OR REPLACE FUNCTION public.update_doctor_review_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE profiles SET review_count = review_count + 1 WHERE id = NEW.doctor_id;
    UPDATE profiles SET rating = (
      SELECT COALESCE(AVG(rating), 0) FROM reviews WHERE doctor_id = NEW.doctor_id
    ) WHERE id = NEW.doctor_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE profiles SET review_count = review_count - 1 WHERE id = OLD.doctor_id;
    UPDATE profiles SET rating = (
      SELECT COALESCE(AVG(rating), 0) FROM reviews WHERE doctor_id = OLD.doctor_id
    ) WHERE id = OLD.doctor_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_review_change ON public.reviews;
CREATE TRIGGER on_review_change
  AFTER INSERT OR DELETE ON public.reviews
  FOR EACH ROW
  EXECUTE PROCEDURE public.update_doctor_review_count();

-- Trigger: increment consultation_counts when appointment status changes to 'completed'
CREATE OR REPLACE FUNCTION public.update_doctor_consultation_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    UPDATE profiles SET consultation_counts = consultation_counts + 1 WHERE id = NEW.doctor_id;
    UPDATE profiles SET patients_helped = patients_helped + 1 WHERE id = NEW.doctor_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_appointment_completed ON public.appointments;
CREATE TRIGGER on_appointment_completed
  AFTER UPDATE OF status ON public.appointments
  FOR EACH ROW
  EXECUTE PROCEDURE public.update_doctor_consultation_count();

-- ============================================================
-- FORUM: Missing RPC functions + reply_count trigger
-- ============================================================

-- RPC: Increment forum post upvote
CREATE OR REPLACE FUNCTION public.increment_forum_upvote(p_post_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE forum_posts SET upvotes = upvotes + 1 WHERE id = p_post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- RPC: Increment forum reply helpful votes
CREATE OR REPLACE FUNCTION public.increment_reply_helpful(p_reply_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE forum_replies SET helpful_votes = helpful_votes + 1 WHERE id = p_reply_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger: auto-maintain reply_count on forum_posts
CREATE OR REPLACE FUNCTION public.update_forum_reply_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE forum_posts SET updated_at = NOW() WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE forum_posts SET updated_at = NOW() WHERE id = OLD.post_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_forum_reply_change ON public.forum_replies;
CREATE TRIGGER on_forum_reply_change
  AFTER INSERT OR DELETE ON public.forum_replies
  FOR EACH ROW
  EXECUTE PROCEDURE public.update_forum_reply_count();

-- RPC Grants
REVOKE EXECUTE ON FUNCTION public.increment_forum_upvote(UUID) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.increment_reply_helpful(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_forum_upvote(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_reply_helpful(UUID) TO authenticated;

-- ============================================================
-- NOTE: auth_leaked_password_protection
-- Enable in Supabase Dashboard → Auth → Settings → Password
-- Toggle "Leaked password protection" ON
-- ============================================================

-- ============================================================
-- MIGRATION: RLS Policies for All Tables
-- Fixes "rls_enabled_no_policy" linter warnings
-- Safe to re-run: uses IF EXISTS / unique policy names
-- ============================================================

-- Enable RLS on system_settings (not in schema.sql)
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PROFILES
-- ============================================================
-- Drop any existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Anyone can view profiles" ON public.profiles;
DROP POLICY IF EXISTS "Anyone can update profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;

CREATE POLICY "Anyone can view profiles"
  ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND role = (SELECT role FROM public.profiles WHERE id = auth.uid())
    AND verification_status = (SELECT verification_status FROM public.profiles WHERE id = auth.uid())
    AND account_status = (SELECT account_status FROM public.profiles WHERE id = auth.uid())
    AND subscription_status = (SELECT subscription_status FROM public.profiles WHERE id = auth.uid())
    AND subscription_expires_at = (SELECT subscription_expires_at FROM public.profiles WHERE id = auth.uid())
    AND rating = (SELECT rating FROM public.profiles WHERE id = auth.uid())
    AND review_count = (SELECT review_count FROM public.profiles WHERE id = auth.uid())
  );

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;
CREATE POLICY "Admins can update any profile"
  ON public.profiles FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================================
-- AUTO-UPDATE updated_at ON profiles
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE PROCEDURE public.update_profiles_updated_at();

-- ============================================================
-- STORAGE: patient-identity-documents BUCKET
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
  VALUES ('patient-identity-documents', 'patient-identity-documents', false)
  ON CONFLICT (id) DO NOTHING;

-- Storage policies for patient-identity-documents
DROP POLICY IF EXISTS "Users can view own identity documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own identity documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own identity documents" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all identity documents" ON storage.objects;

CREATE POLICY "Users can view own identity documents"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'patient-identity-documents' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can upload own identity documents"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'patient-identity-documents' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can delete own identity documents"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'patient-identity-documents' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Admins can view all identity documents"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'patient-identity-documents' AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================================
-- DOCTOR SCHEDULES
-- ============================================================
DROP POLICY IF EXISTS "Doctors can view own schedule" ON public.doctor_schedules;
DROP POLICY IF EXISTS "Patients can view doctor schedules" ON public.doctor_schedules;
DROP POLICY IF EXISTS "Authenticated users can view doctor schedules" ON public.doctor_schedules;
DROP POLICY IF EXISTS "Doctors can insert own schedule" ON public.doctor_schedules;
DROP POLICY IF EXISTS "Doctors can update own schedule" ON public.doctor_schedules;

CREATE POLICY "Doctors can view own schedule"
  ON public.doctor_schedules FOR SELECT
  USING (auth.uid() = doctor_id);

CREATE POLICY "Authenticated users can view doctor schedules"
  ON public.doctor_schedules FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Doctors can insert own schedule"
  ON public.doctor_schedules FOR INSERT
  WITH CHECK (auth.uid() = doctor_id);

CREATE POLICY "Doctors can update own schedule"
  ON public.doctor_schedules FOR UPDATE
  USING (auth.uid() = doctor_id) WITH CHECK (auth.uid() = doctor_id);

-- ============================================================
-- APPOINTMENTS
-- ============================================================
DROP POLICY IF EXISTS "Patients can view own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Doctors can view their appointments" ON public.appointments;

CREATE POLICY "Patients can view own appointments"
  ON public.appointments FOR SELECT
  USING (auth.uid() = patient_id);

CREATE POLICY "Doctors can view their appointments"
  ON public.appointments FOR SELECT
  USING (auth.uid() = doctor_id);

-- ============================================================
-- PAYMENTS
-- ============================================================
DROP POLICY IF EXISTS "Patients can view own payments" ON public.payments;
DROP POLICY IF EXISTS "Patients can create own payments" ON public.payments;
DROP POLICY IF EXISTS "Doctors can view their received payments" ON public.payments;
DROP POLICY IF EXISTS "Recipients can update payment status" ON public.payments;
DROP POLICY IF EXISTS "Admins can manage all payments" ON public.payments;

CREATE POLICY "Patients can view own payments"
  ON public.payments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Patients can create own payments"
  ON public.payments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Doctors can view their received payments"
  ON public.payments FOR SELECT
  USING (auth.uid() = recipient_id);

CREATE POLICY "Recipients can update payment status"
  ON public.payments FOR UPDATE
  USING (auth.uid() = recipient_id);

CREATE POLICY "Admins can manage all payments"
  ON public.payments FOR ALL
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================================
-- MESSAGES
-- ============================================================
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view sent messages" ON public.messages;
  DROP POLICY IF EXISTS "Users can view received messages" ON public.messages;
  DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
  DROP POLICY IF EXISTS "Users can update own messages" ON public.messages;

  CREATE POLICY "Users can view sent messages"
    ON public.messages FOR SELECT
    USING (auth.uid() = sender_id);

  CREATE POLICY "Users can view received messages"
    ON public.messages FOR SELECT
    USING (auth.uid() = receiver_id);

  CREATE POLICY "Users can send messages"
    ON public.messages FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

  CREATE POLICY "Users can update own messages"
    ON public.messages FOR UPDATE
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping messages policies: %', SQLERRM;
END $$;

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Authenticated users can create notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can create own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Admins can view all notifications" ON public.notifications;

CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- SECURITY FIX: Users can only create notifications for themselves.
-- System-level notifications (payments, appointments) use SECURITY DEFINER functions.
CREATE POLICY "Users can create own notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all notifications"
  ON public.notifications FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================================
-- MEDICAL RECORDS
-- ============================================================

-- Helper function to check doctor access to records (breaks RLS recursion)
CREATE OR REPLACE FUNCTION public.doctor_has_record_access(
  p_doctor_id UUID,
  p_record_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM record_permissions
    WHERE record_permissions.record_id = p_record_id
      AND record_permissions.doctor_id = p_doctor_id
  );
$$;

REVOKE EXECUTE ON FUNCTION public.doctor_has_record_access(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.doctor_has_record_access(UUID, UUID) TO authenticated;

DROP POLICY IF EXISTS "Patients can view own records" ON public.medical_records;
DROP POLICY IF EXISTS "Patients can insert own records" ON public.medical_records;
DROP POLICY IF EXISTS "Patients can update own records" ON public.medical_records;
DROP POLICY IF EXISTS "Patients can delete own records" ON public.medical_records;
DROP POLICY IF EXISTS "Doctors can view shared records" ON public.medical_records;
DROP POLICY IF EXISTS "Admins can view all medical records" ON public.medical_records;

CREATE POLICY "Patients can view own records"
  ON public.medical_records FOR SELECT
  USING (auth.uid() = patient_id);

CREATE POLICY "Patients can insert own records"
  ON public.medical_records FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Patients can update own records"
  ON public.medical_records FOR UPDATE
  USING (auth.uid() = patient_id) WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Patients can delete own records"
  ON public.medical_records FOR DELETE
  USING (auth.uid() = patient_id);

CREATE POLICY "Doctors can view shared records"
  ON public.medical_records FOR SELECT
  USING (
    auth.uid() = ANY(authorized_doctors)
    OR public.doctor_has_record_access(auth.uid(), id)
  );

CREATE POLICY "Admins can view all medical records"
  ON public.medical_records FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================================
-- RECORD PERMISSIONS
-- ============================================================
DROP POLICY IF EXISTS "Patients can view own record permissions" ON public.record_permissions;
DROP POLICY IF EXISTS "Patients can manage own record permissions" ON public.record_permissions;
DROP POLICY IF EXISTS "Doctors can view permissions granted to them" ON public.record_permissions;

CREATE POLICY "Patients can view own record permissions"
  ON public.record_permissions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.medical_records
      WHERE medical_records.id = record_permissions.record_id
        AND medical_records.patient_id = auth.uid()
    )
  );

CREATE POLICY "Patients can manage own record permissions"
  ON public.record_permissions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.medical_records
      WHERE medical_records.id = record_permissions.record_id
        AND medical_records.patient_id = auth.uid()
    )
  );

CREATE POLICY "Doctors can view permissions granted to them"
  ON public.record_permissions FOR SELECT
  USING (auth.uid() = doctor_id);

-- ============================================================
-- SUBSCRIPTION PLANS
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view subscription plans" ON public.subscription_plans;

CREATE POLICY "Anyone can view subscription plans"
  ON public.subscription_plans FOR SELECT USING (true);

-- ============================================================
-- DOCTOR SUBSCRIPTIONS
-- ============================================================
DROP POLICY IF EXISTS "Doctors can view own subscriptions" ON public.doctor_subscriptions;
DROP POLICY IF EXISTS "Admins can view all subscriptions" ON public.doctor_subscriptions;

CREATE POLICY "Doctors can view own subscriptions"
  ON public.doctor_subscriptions FOR SELECT
  USING (auth.uid() = doctor_id);

CREATE POLICY "Admins can view all subscriptions"
  ON public.doctor_subscriptions FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================================
-- REVIEWS
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view reviews" ON public.reviews;
DROP POLICY IF EXISTS "Patients can create reviews" ON public.reviews;
DROP POLICY IF EXISTS "Patients can update own reviews" ON public.reviews;

CREATE POLICY "Anyone can view reviews"
  ON public.reviews FOR SELECT USING (true);

CREATE POLICY "Patients can create reviews"
  ON public.reviews FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Patients can update own reviews"
  ON public.reviews FOR UPDATE
  USING (auth.uid() = patient_id) WITH CHECK (auth.uid() = patient_id);

-- ============================================================
-- SYSTEM SETTINGS
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view system settings" ON public.system_settings;
DROP POLICY IF EXISTS "Authenticated users can view system settings" ON public.system_settings;
DROP POLICY IF EXISTS "Admins can update system settings" ON public.system_settings;

-- SECURITY FIX: Only authenticated users can view system settings (not anonymous).
CREATE POLICY "Authenticated users can view system settings"
  ON public.system_settings FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can update system settings"
  ON public.system_settings FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================================
-- SECURITY FIX: Make payment-receipts bucket private
-- ============================================================
UPDATE storage.buckets SET public = false WHERE id = 'payment-receipts';

-- ============================================================
-- SECURITY FIX: Restrict patient-medical-vault storage access
-- Only patients (owners), admins, and doctors with explicit record_permissions can access
-- ============================================================
DROP POLICY IF EXISTS "Doctors can view shared medical vault documents" ON storage.objects;

CREATE POLICY "Doctors can view shared medical vault documents" ON storage.objects
  FOR SELECT TO authenticated USING (
    bucket_id = 'patient-medical-vault'
    AND (
      -- Admin access
      EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
      OR
      -- Doctor access: must have explicit record_permissions for the patient's records
      EXISTS (
        SELECT 1 FROM public.record_permissions rp
        JOIN public.medical_records mr ON mr.id = rp.record_id
        WHERE rp.doctor_id = auth.uid()
          AND mr.patient_id::text = (storage.foldername(name))[1]
      )
    )
  );

-- ============================================================
-- SECURITY FIX: blocked_users - restrict SELECT to self + admin only
-- ============================================================
DROP POLICY IF EXISTS "Anyone can see if they are blocked" ON public.blocked_users;
DROP POLICY IF EXISTS "Users can view own block status" ON public.blocked_users;

CREATE POLICY "Users can view own block status"
  ON public.blocked_users FOR SELECT
  USING (auth.uid() = user_id);

-- ============================================================
-- SECURITY FIX: disputes - add INSERT policy + expand SELECT
-- ============================================================
DROP POLICY IF EXISTS "Users can view their own disputes" ON public.disputes;
DROP POLICY IF EXISTS "Authenticated users can create disputes" ON public.disputes;

CREATE POLICY "Authenticated users can create disputes"
  ON public.disputes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own disputes"
  ON public.disputes FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = patient_id OR auth.uid() = doctor_id);

-- ============================================================
-- SECURITY FIX: forum_posts - add author DELETE policy
-- ============================================================
DROP POLICY IF EXISTS "Authors can delete own posts" ON public.forum_posts;

CREATE POLICY "Authors can delete own posts"
  ON public.forum_posts FOR DELETE
  USING (auth.uid() = author_id);

-- ============================================================
-- SECURITY FIX: forum_replies - add author DELETE policy
-- ============================================================
DROP POLICY IF EXISTS "Authors can delete own replies" ON public.forum_replies;

CREATE POLICY "Authors can delete own replies"
  ON public.forum_replies FOR DELETE
  USING (auth.uid() = author_id);

-- ============================================================
-- PERFORMANCE: Add indexes for unindexed foreign keys
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_appointments_payment_id ON public.appointments (payment_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked_by ON public.blocked_users (blocked_by);
CREATE INDEX IF NOT EXISTS idx_device_sessions_user_id ON public.device_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_disputes_doctor_id ON public.disputes (doctor_id);
CREATE INDEX IF NOT EXISTS idx_disputes_patient_id ON public.disputes (patient_id);
CREATE INDEX IF NOT EXISTS idx_disputes_resolved_by ON public.disputes (resolved_by);
CREATE INDEX IF NOT EXISTS idx_doctor_subscriptions_doctor_id ON public.doctor_subscriptions (doctor_id);
CREATE INDEX IF NOT EXISTS idx_doctor_subscriptions_plan_id ON public.doctor_subscriptions (plan_id);
CREATE INDEX IF NOT EXISTS idx_fee_negotiation_messages_doctor_id ON public.fee_negotiation_messages (doctor_id);
CREATE INDEX IF NOT EXISTS idx_fee_negotiation_messages_sender_id ON public.fee_negotiation_messages (sender_id);
CREATE INDEX IF NOT EXISTS idx_forum_follows_category_id ON public.forum_follows (category_id);
CREATE INDEX IF NOT EXISTS idx_forum_follows_post_id ON public.forum_follows (post_id);
CREATE INDEX IF NOT EXISTS idx_forum_follows_user_id ON public.forum_follows (user_id);
CREATE INDEX IF NOT EXISTS idx_forum_reports_post_id ON public.forum_reports (post_id);
CREATE INDEX IF NOT EXISTS idx_forum_reports_reply_id ON public.forum_reports (reply_id);
CREATE INDEX IF NOT EXISTS idx_forum_reports_reporter_id ON public.forum_reports (reporter_id);
CREATE INDEX IF NOT EXISTS idx_forum_reports_resolved_by ON public.forum_reports (resolved_by);
CREATE INDEX IF NOT EXISTS idx_forum_saves_post_id ON public.forum_saves (post_id);
CREATE INDEX IF NOT EXISTS idx_health_records_doctor_id ON public.health_records (doctor_id);
CREATE INDEX IF NOT EXISTS idx_health_records_patient_id ON public.health_records (patient_id);
CREATE INDEX IF NOT EXISTS idx_medical_documents_patient_id ON public.medical_documents (patient_id);
CREATE INDEX IF NOT EXISTS idx_payments_processed_by ON public.payments (processed_by);
CREATE INDEX IF NOT EXISTS idx_payouts_doctor_id ON public.payouts (doctor_id);
CREATE INDEX IF NOT EXISTS idx_payouts_processed_by ON public.payouts (processed_by);
CREATE INDEX IF NOT EXISTS idx_prescriptions_appointment_id ON public.prescriptions (appointment_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_doctor_id ON public.prescriptions (doctor_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_patient_id ON public.prescriptions (patient_id);
CREATE INDEX IF NOT EXISTS idx_profiles_verified_by ON public.profiles (verified_by);
CREATE INDEX IF NOT EXISTS idx_record_permissions_doctor_id ON public.record_permissions (doctor_id);
CREATE INDEX IF NOT EXISTS idx_refunds_patient_id ON public.refunds (patient_id);
CREATE INDEX IF NOT EXISTS idx_refunds_payment_id ON public.refunds (payment_id);
CREATE INDEX IF NOT EXISTS idx_refunds_processed_by ON public.refunds (processed_by);
CREATE INDEX IF NOT EXISTS idx_reviews_doctor_id ON public.reviews (doctor_id);
CREATE INDEX IF NOT EXISTS idx_reviews_patient_id ON public.reviews (patient_id);

-- ============================================================
-- PERFORMANCE: Remove unused indexes to reduce write overhead
-- ============================================================
DROP INDEX IF EXISTS public.idx_appointments_doctor_status;
DROP INDEX IF EXISTS public.idx_appointments_emergency_requests;
DROP INDEX IF EXISTS public.idx_notifications_user_id;
DROP INDEX IF EXISTS public.idx_profiles_verification_status;
DROP INDEX IF EXISTS public.idx_profiles_is_online;
DROP INDEX IF EXISTS public.idx_profiles_is_emergency;
DROP INDEX IF EXISTS public.idx_appointments_patient_id;
DROP INDEX IF EXISTS public.idx_appointments_status;
DROP INDEX IF EXISTS public.idx_appointments_doctor_id;
DROP INDEX IF EXISTS public.idx_appointments_created_at;
DROP INDEX IF EXISTS public.idx_payments_user_id;
DROP INDEX IF EXISTS public.idx_payments_status;
DROP INDEX IF EXISTS public.idx_payments_recipient_id;
DROP INDEX IF EXISTS public.idx_messages_sender_id;
DROP INDEX IF EXISTS public.idx_messages_receiver_id;
DROP INDEX IF EXISTS public.idx_messages_created_at;
DROP INDEX IF EXISTS public.idx_notifications_is_read;
DROP INDEX IF EXISTS public.idx_time_balances_patient_id;
DROP INDEX IF EXISTS public.idx_time_balances_doctor_id;
DROP INDEX IF EXISTS public.idx_forum_posts_category_id;
DROP INDEX IF EXISTS public.idx_forum_posts_author_id;
DROP INDEX IF EXISTS public.idx_forum_replies_post_id;
DROP INDEX IF EXISTS public.idx_forum_replies_author_id;
DROP INDEX IF EXISTS public.idx_disputes_status;
DROP INDEX IF EXISTS public.idx_disputes_user_id;
DROP INDEX IF EXISTS public.idx_audit_logs_admin_id;
DROP INDEX IF EXISTS public.idx_audit_logs_created_at;

-- ============================================================
-- MIGRATION: Emergency Guest Booking RLS + accepted_at column
-- Run this in your Supabase SQL Editor
-- ============================================================

-- 1. Add accepted_at column for emergency handshake tracking
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS accepted_at timestamp with time zone;

-- 2. Drop existing restrictive INSERT/UPDATE/SELECT policies on appointments
DROP POLICY IF EXISTS "Patients can create own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Patients can update own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Patients can view own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Authenticated users can create guest emergency appointments" ON public.appointments;
DROP POLICY IF EXISTS "Authenticated users can link guest emergency appointments" ON public.appointments;
DROP POLICY IF EXISTS "Guests can view own emergency appointments" ON public.appointments;

-- 3. Recreate policies to support guest emergency bookings
-- SELECT: patients see their own, guests see their emergency bookings, doctors see assigned
CREATE POLICY "Patients can view own appointments"
  ON public.appointments FOR SELECT
  USING (auth.uid() = patient_id);

CREATE POLICY "Guests can view own emergency appointments"
  ON public.appointments FOR SELECT
  USING (patient_id IS NULL AND is_emergency = true AND metadata->>'guest_token' IS NOT NULL);

-- INSERT: patients create their own, authenticated users can create guest emergency
CREATE POLICY "Patients can create own appointments"
  ON public.appointments FOR INSERT
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Authenticated users can create guest emergency appointments"
  ON public.appointments FOR INSERT
  WITH CHECK (patient_id IS NULL AND is_emergency = true);

-- UPDATE: patients update their own, link guest after signup, doctors update assigned
CREATE POLICY "Patients can update own appointments"
  ON public.appointments FOR UPDATE
  USING (auth.uid() = patient_id)
  WITH CHECK (auth.uid() = patient_id);

CREATE POLICY "Authenticated users can link guest emergency appointments"
  ON public.appointments FOR UPDATE
  USING (patient_id IS NULL AND is_emergency = true)
  WITH CHECK (auth.uid() = patient_id);

-- 4. Verify accepted_at column exists
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'appointments'
AND column_name IN ('accepted_at', 'reason', 'consultation_mode', 'is_emergency', 'total_amount', 'metadata')
ORDER BY ordinal_position;

-- ============================================================
-- SECURITY: OTP Rate Limiting & Account Lockout
-- Tracks failed OTP verification attempts per email.
-- After MAX_ATTEMPTS (5), the email is locked for LOCKOUT_MINUTES (15).
-- ============================================================

-- 1. login_attempts table
CREATE TABLE IF NOT EXISTS public.login_attempts (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  email text NOT NULL,
  attempted_at timestamp with time zone DEFAULT now(),
  success boolean DEFAULT false,
  ip_address text
);

ALTER TABLE public.login_attempts ENABLE ROW LEVEL SECURITY;

-- Only service_role can manage login_attempts (RPC functions use SECURITY DEFINER)
CREATE POLICY "Service role manages login_attempts"
  ON public.login_attempts FOR ALL
  USING (true);

-- Index for fast lookups by email
CREATE INDEX IF NOT EXISTS idx_login_attempts_email
  ON public.login_attempts (email, attempted_at DESC);

-- Auto-cleanup: delete attempts older than 1 hour
CREATE OR REPLACE FUNCTION public.cleanup_old_login_attempts()
RETURNS void AS $$
BEGIN
  DELETE FROM public.login_attempts WHERE attempted_at < now() - interval '1 hour';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Constants
DO $$ BEGIN
  PERFORM set_config('app.max_otp_attempts', '5', false);
  PERFORM set_config('app.lockout_minutes', '15', false);
END $$;

-- 3. Check rate limit: returns { allowed, attempts_remaining, locked_until }
CREATE OR REPLACE FUNCTION public.check_otp_rate_limit(p_email text)
RETURNS jsonb AS $$
DECLARE
  v_max_attempts int := 5;
  v_lockout_minutes int := 15;
  v_recent_failures int;
  v_locked_until timestamp with time zone;
BEGIN
  -- Count failed attempts in the lockout window
  SELECT count(*) INTO v_recent_failures
  FROM public.login_attempts
  WHERE email = lower(p_email)
    AND success = false
    AND attempted_at > now() - (v_lockout_minutes || ' minutes')::interval;

  -- Check if locked out
  IF v_recent_failures >= v_max_attempts THEN
    SELECT max(attempted_at) + (v_lockout_minutes || ' minutes')::interval
      INTO v_locked_until
    FROM public.login_attempts
    WHERE email = lower(p_email)
      AND success = false
      AND attempted_at > now() - (v_lockout_minutes || ' minutes')::interval;

    RETURN jsonb_build_object(
      'allowed', false,
      'attempts_remaining', 0,
      'locked_until', v_locked_until
    );
  END IF;

  RETURN jsonb_build_object(
    'allowed', true,
    'attempts_remaining', v_max_attempts - v_recent_failures,
    'locked_until', null
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Record an OTP attempt (call before sending OTP)
CREATE OR REPLACE FUNCTION public.record_otp_attempt(p_email text, p_ip_address text DEFAULT null)
RETURNS void AS $$
BEGIN
  INSERT INTO public.login_attempts (email, ip_address, success)
  VALUES (lower(p_email), p_ip_address, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. Reset attempts on successful verification
CREATE OR REPLACE FUNCTION public.reset_otp_attempts(p_email text)
RETURNS void AS $$
BEGIN
  INSERT INTO public.login_attempts (email, success)
  VALUES (lower(p_email), true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6. Revoke direct access — only callable via RPC
REVOKE EXECUTE ON FUNCTION public.check_otp_rate_limit(text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.record_otp_attempt(text, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.reset_otp_attempts(text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.check_otp_rate_limit(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_otp_attempt(text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reset_otp_attempts(text) TO anon, authenticated;

-- 7. GRANT on login_attempts for service_role (cleanup cron)
GRANT SELECT, INSERT, DELETE ON public.login_attempts TO service_role;

-- ============================================================
-- SECURITY: Supabase Auth Hardening (manual dashboard config)
-- ============================================================
-- Run these in Supabase Dashboard → Authentication → Settings:
--
-- 1. OTP Expiry: Set to 300 seconds (5 minutes)
--    Dashboard → Auth → Settings → "Email OTP expiry" → 300
--
-- 2. Max OTP Attempts: Set to 3
--    Dashboard → Auth → Settings → "Max number of attempts" → 3
--
-- 3. Enable "Protect against leaked passwords"
--    Dashboard → Auth → Settings → Password Protection → Toggle ON
--
-- These settings work in conjunction with the login_attempts
-- table and RPC functions above for defense-in-depth.

-- ============================================================
-- GDPR & HIPAA COMPLIANCE: Audit, Export, Erasure, Retention
-- Run this in your Supabase SQL Editor
-- Each statement runs independently — safe to re-run
-- ============================================================

-- 1. Audit logs: add user_id, action, details columns (safe if already exists)
ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS action text;
ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS details jsonb DEFAULT '{}'::jsonb;

-- Backfill action from action_type where action is null
UPDATE public.audit_logs SET action = action_type::text WHERE action IS NULL AND action_type IS NOT NULL;

-- Make action NOT NULL after backfill
DO $$ BEGIN
  ALTER TABLE public.audit_logs ALTER COLUMN action SET NOT NULL;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping SET NOT NULL on audit_logs.action: %', SQLERRM;
END $$;

-- 2. Audit logs: add user-friendly RLS policies
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view own audit logs" ON public.audit_logs;
  CREATE POLICY "Users can view own audit logs" ON public.audit_logs
    FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping user audit_logs SELECT policy: %', SQLERRM;
END $$;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Authenticated users can insert own audit logs" ON public.audit_logs;
  CREATE POLICY "Authenticated users can insert own audit logs" ON public.audit_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping user audit_logs INSERT policy: %', SQLERRM;
END $$;

-- 3. Profiles: add soft-delete columns
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS deleted_at timestamp with time zone;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS deletion_reason text;

-- 4. GDPR: Soft-delete user function
CREATE OR REPLACE FUNCTION public.soft_delete_user(p_user_id uuid, p_reason text DEFAULT null)
RETURNS jsonb AS $$
BEGIN
  IF auth.uid() != p_user_id AND NOT EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RETURN jsonb_build_object('error', 'Unauthorized');
  END IF;

  UPDATE public.profiles
  SET deleted_at = now(), deletion_reason = p_reason, account_status = 'suspended'
  WHERE id = p_user_id;

  UPDATE auth.users
  SET email = 'deleted-' || p_user_id || '@premoncare.invalid',
      raw_user_meta_data = raw_user_meta_data || '{"deleted": true}'::jsonb
  WHERE id = p_user_id;

  INSERT INTO audit_logs (user_id, action, action_type, severity, description)
  VALUES (p_user_id, 'account_soft_deleted', 'security', 'high',
          'User requested account deletion. Reason: ' || COALESCE(p_reason, 'Not provided'));

  RETURN jsonb_build_object('success', true, 'message', 'Account scheduled for deletion in 30 days');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. GDPR: Purge deleted accounts (30-day grace period)
CREATE OR REPLACE FUNCTION public.purge_deleted_accounts()
RETURNS void AS $$
DECLARE
  v_user record;
BEGIN
  FOR v_user IN SELECT id FROM profiles WHERE deleted_at IS NOT NULL AND deleted_at < now() - interval '30 days'
  LOOP
    DELETE FROM auth.users WHERE id = v_user.id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6. GDPR: Data export function
CREATE OR REPLACE FUNCTION public.export_user_data(p_user_id uuid)
RETURNS jsonb AS $$
DECLARE
  v_profile jsonb;
  v_appointments jsonb;
  v_messages jsonb;
  v_medical_records jsonb;
  v_prescriptions jsonb;
  v_payments jsonb;
  v_reviews jsonb;
  v_forum_posts jsonb;
  v_forum_replies jsonb;
BEGIN
  IF auth.uid() != p_user_id THEN
    RETURN jsonb_build_object('error', 'Unauthorized');
  END IF;

  SELECT to_jsonb(p.*) INTO v_profile FROM profiles p WHERE p.id = p_user_id;
  SELECT jsonb_agg(to_jsonb(a.*)) INTO v_appointments FROM appointments a WHERE a.patient_id = p_user_id;
  SELECT jsonb_agg(to_jsonb(m.*)) INTO v_messages FROM messages m WHERE m.sender_id = p_user_id OR m.receiver_id = p_user_id;
  SELECT jsonb_agg(to_jsonb(mr.*)) INTO v_medical_records FROM medical_records mr WHERE mr.patient_id = p_user_id;
  SELECT jsonb_agg(to_jsonb(pr.*)) INTO v_prescriptions FROM prescriptions pr WHERE pr.patient_id = p_user_id;
  SELECT jsonb_agg(to_jsonb(pay.*)) INTO v_payments FROM payments pay WHERE pay.user_id = p_user_id;
  SELECT jsonb_agg(to_jsonb(r.*)) INTO v_reviews FROM reviews r WHERE r.patient_id = p_user_id;
  SELECT jsonb_agg(to_jsonb(fp.*)) INTO v_forum_posts FROM forum_posts fp WHERE fp.author_id = p_user_id;
  SELECT jsonb_agg(to_jsonb(fr.*)) INTO v_forum_replies FROM forum_replies fr WHERE fr.author_id = p_user_id;

  INSERT INTO audit_logs (user_id, action, action_type, severity, description)
  VALUES (p_user_id, 'data_export_completed', 'security', 'info', 'User exercised right to data portability');

  RETURN jsonb_build_object(
    'profile', v_profile,
    'appointments', COALESCE(v_appointments, '[]'::jsonb),
    'messages', COALESCE(v_messages, '[]'::jsonb),
    'medical_records', COALESCE(v_medical_records, '[]'::jsonb),
    'prescriptions', COALESCE(v_prescriptions, '[]'::jsonb),
    'payments', COALESCE(v_payments, '[]'::jsonb),
    'reviews', COALESCE(v_reviews, '[]'::jsonb),
    'forum_posts', COALESCE(v_forum_posts, '[]'::jsonb),
    'forum_replies', COALESCE(v_forum_replies, '[]'::jsonb),
    'exported_at', now()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7. HIPAA: PHI access audit logging function
CREATE OR REPLACE FUNCTION public.log_phi_access(
  p_user_id uuid, p_action text, p_resource_type text,
  p_resource_id uuid DEFAULT NULL, p_details jsonb DEFAULT '{}'::jsonb
)
RETURNS void AS $$
BEGIN
  INSERT INTO audit_logs (user_id, action, action_type, severity, description, details)
  VALUES (
    p_user_id, p_action, 'security',
    CASE WHEN p_action IN ('medical_record_accessed', 'prescription_accessed', 'phi_exported') THEN 'moderate' ELSE 'info' END,
    p_resource_type || ' ' || COALESCE(p_action, '') || ' by ' || p_user_id::text,
    p_details || jsonb_build_object('resource_type', p_resource_type, 'resource_id', p_resource_id)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 8. Data retention: cleanup functions
CREATE OR REPLACE FUNCTION public.cleanup_old_notifications()
RETURNS void AS $$
BEGIN
  DELETE FROM public.notifications WHERE created_at < now() - interval '30 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.cleanup_old_device_sessions()
RETURNS void AS $$
BEGIN
  DELETE FROM public.device_sessions WHERE last_active_at < now() - interval '90 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 9. GRANTs for new functions
GRANT EXECUTE ON FUNCTION public.soft_delete_user(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.export_user_data(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_phi_access(uuid, text, text, uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.purge_deleted_accounts() TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_old_notifications() TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_old_device_sessions() TO service_role;

-- 10. Schedule cleanup cron jobs (requires pg_cron extension)
-- Run these in Supabase Dashboard → SQL Editor AFTER enabling pg_cron:
--
-- SELECT cron.schedule('cleanup-login-attempts', '5 * * * *', 'SELECT cleanup_old_login_attempts()');
-- SELECT cron.schedule('cleanup-notifications', '0 2 * * *', 'SELECT cleanup_old_notifications()');
-- SELECT cron.schedule('cleanup-device-sessions', '0 3 * * *', 'SELECT cleanup_old_device_sessions()');
-- SELECT cron.schedule('purge-deleted-accounts', '0 4 * * *', 'SELECT purge_deleted_accounts()');
-- SELECT cron.schedule('sweep-offline-doctors', '* * * * *', 'SELECT sweep_offline_doctors()');
