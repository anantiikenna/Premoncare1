-- ============================================================
-- LIVE MIGRATION: Emergency Handshake Flow
-- Run this in your Supabase SQL Editor
-- Each statement runs independently — safe to re-run
-- ============================================================

-- 1. Add missing columns (safe if already exists)
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS is_emergency boolean DEFAULT false;
ALTER TABLE public.appointments ADD COLUMN IF NOT EXISTS total_amount numeric DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS payment_instructions text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS address text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_emergency boolean DEFAULT false;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS rejection_reason text;

-- 2. Update status check constraint for emergency flow
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
    'ongoing'
  ));

-- 3. Performance indexes
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_status
  ON public.appointments (doctor_id, status);

CREATE INDEX IF NOT EXISTS idx_appointments_emergency_requests
  ON public.appointments (doctor_id, created_at DESC)
  WHERE status = 'emergency_request';

-- 4. Realtime publication (skip if already added)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename = 'appointments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.appointments;
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
  INSERT INTO public.profiles (id, email, full_name, role, requested_role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
    COALESCE(NEW.raw_user_meta_data ->> 'requested_role', 'patient')::user_role,
    COALESCE(NEW.raw_user_meta_data ->> 'requested_role', 'patient')::user_role
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
-- ============================================================
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

CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages (sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages (receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages (created_at DESC);

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
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON public.profiles;

CREATE POLICY "Anyone can view profiles"
  ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can update any profile"
  ON public.profiles FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

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

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Authenticated users can create notifications" ON public.notifications;
DROP POLICY IF EXISTS "Admins can view all notifications" ON public.notifications;

CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Authenticated users can create notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

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
DROP POLICY IF EXISTS "Admins can update system settings" ON public.system_settings;

CREATE POLICY "Anyone can view system settings"
  ON public.system_settings FOR SELECT USING (true);

CREATE POLICY "Admins can update system settings"
  ON public.system_settings FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
