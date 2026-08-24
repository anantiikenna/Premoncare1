-- Premon Care Unified Database Schema
-- Last Updated: 2026-07-31
-- Includes: Profiles, Medical Vault, Subscriptions, Appointments, Real-time Messaging, and Doctor Scheduling.

SET ROLE postgres;

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Create Enums
create type user_role as enum ('patient', 'doctor', 'admin');
create type verification_status as enum ('unsubmitted', 'pending', 'under_review', 'approved', 'rejected');
create type subscription_status as enum ('inactive', 'active', 'expiring_soon', 'expired', 'overdue', 'suspended');
create type fee_status as enum ('none', 'awaiting_admin_proposal', 'awaiting_doctor_approval', 'active');
create type forum_post_status as enum ('approved', 'pending', 'rejected');
create type forum_report_status as enum ('pending', 'reviewed', 'action_taken', 'dismissed');
create type account_status as enum ('active', 'suspended', 'banned');
create type payment_status as enum ('pending', 'approved', 'rejected', 'disputed');
create type payment_method as enum ('digital', 'manual');
create type record_type as enum ('lab_result', 'prescription', 'imaging', 'immunization', 'clinical_note', 'other');
create type audit_action_type as enum ('verification', 'financial', 'security', 'system');
create type audit_severity as enum ('info', 'moderate', 'high');
create type payout_status as enum ('pending', 'approved', 'rejected', 'failed');
create type refund_status as enum ('pending', 'approved', 'rejected');
create type dispute_status as enum ('open', 'in_review', 'under_review', 'resolved', 'dismissed');

-- Profiles table
create table profiles (
  id uuid references auth.users on delete cascade not null primary key,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  email text,
  username text unique,
  full_name text,
  avatar_url text,
  title text,
  role user_role default 'patient'::user_role,
  verification_status verification_status default 'unsubmitted',
  verification_document_url text,
  requested_role user_role default 'patient'::user_role,
  account_status account_status default 'active'::account_status,
  
  -- Doctor specific fields
  specialty text,
  experience_years integer,
  clinic_address text,
  consultation_fee numeric default 0,
  video_fee numeric default 7500,
  in_person_fee numeric default 10000,
  rating numeric(3,2) default 0.00,
  review_count integer default 0,
  consultation_counts integer default 0,
  verified_medical_answers integer default 0,
  helpful_votes integer default 0,
  patients_helped integer default 0,
  about_text text,
  specializations_list text[] default '{}'::text[],
  education jsonb default '[]'::jsonb,
  is_online boolean default false,
  last_seen timestamp with time zone default now(),
  
  -- Subscription & Fee Negotiation
  negotiated_fee numeric default 0,
  fee_status fee_status default 'none'::fee_status,
  subscription_status subscription_status default 'inactive'::subscription_status,
  subscription_expires_at timestamp with time zone,
  last_subscription_payment_at timestamp with time zone,
  verified_by uuid references profiles(id),
  hourly_rate numeric default 0,
  email_alerts_enabled boolean default true,
  payment_instructions text,
  identity_document_url text,
  identity_document_front_url text,
  identity_document_back_url text,
  identity_type text,
  live_selfie_url text,
  medical_license_number text,
  languages_spoken text,
  address_document_url text,
  preferred_consultation_types text[] default '{}'::text[],
  fcm_token text,
  is_guest boolean default false,
  rejection_reason text,
  dob date,
  gender text,
  blood_group text,
  next_of_kin_name text,
  next_of_kin_phone text,
  emergency_contact_name text,
  emergency_contact_phone text,
  address text,
  phone text,
  is_emergency boolean default false,
  
  -- Privacy & Security
  biometric_enabled boolean default false,
  two_factor_enabled boolean default false,
  medical_records_shared_by_default boolean default false,
  
  -- GDPR: Soft delete
  deleted_at timestamp with time zone,
  deletion_reason text
);

-- Doctor Schedules (Flexible JSONB structure)
create table doctor_schedules (
  id uuid default uuid_generate_v4() primary key,
  doctor_id uuid references profiles(id) on delete cascade not null unique,
  weekly_hours jsonb default $json$
  [
    {"day": "Monday", "enabled": true, "start": "08:00", "end": "18:00"},
    {"day": "Tuesday", "enabled": true, "start": "08:00", "end": "18:00"},
    {"day": "Wednesday", "enabled": true, "start": "08:00", "end": "18:00"},
    {"day": "Thursday", "enabled": true, "start": "08:00", "end": "18:00"},
    {"day": "Friday", "enabled": true, "start": "08:00", "end": "17:00"},
    {"day": "Saturday", "enabled": false, "start": "09:00", "end": "13:00"},
    {"day": "Sunday", "enabled": false, "start": "00:00", "end": "00:00"}
  ]
  $json$::jsonb,
  break_times jsonb default '[]'::jsonb,
  vacation_mode boolean default false,
  emergency_availability boolean default false,
  auto_accept boolean default false,
  timezone text default 'Africa/Lagos',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- System Settings
create table system_settings (
  id text primary key default 'default',
  auto_approve_enabled boolean default false,
  auto_approve_delay_minutes integer default 0,
  payment_methods_allowed text default 'both' check (payment_methods_allowed in ('both', 'digital', 'manual')),
  digital_gateway text default 'dodo' check (digital_gateway in ('dodo', 'paystack')),
  allow_doctor_pricing boolean default true,
  base_consultation_fee numeric default 0,
  manual_payment_instructions text default 'Please upload your payment receipt below.',
  updated_at timestamp with time zone default now()
);

insert into system_settings (id, auto_approve_enabled, auto_approve_delay_minutes, payment_methods_allowed, digital_gateway, allow_doctor_pricing, base_consultation_fee, manual_payment_instructions)
values ('default', false, 0, 'both', 'dodo', true, 0, 'Bank Transfer: [Naira Merchant Bank / 1234567890]. Please upload your subscription payment receipt below.')
on conflict (id) do nothing;

-- Appointments
create table appointments (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  patient_id uuid references profiles(id) on delete set null,
  doctor_id uuid references profiles(id) on delete cascade not null,
  appointment_date timestamp with time zone not null,
  status text default 'pending' check (status in ('pending', 'emergency_pending', 'emergency_request', 'emergency_accepted', 'emergency_declined', 'confirmed', 'cancelled', 'completed', 'ongoing', 'rescheduled')),
  reason text,
  consultation_mode text check (consultation_mode in ('video', 'audio', 'text', 'in_person')),
  duration_minutes integer default 15,
  is_emergency boolean default false,
  total_amount numeric default 0,
  metadata jsonb default '{}'::jsonb,
  payment_id uuid, -- Will link to payments table
  is_doctor_approved boolean default false,
  is_patient_approved boolean default true,
  accepted_at timestamp with time zone,
  meeting_link text,
  reminder_sent boolean default false
);

-- Payments
create table payments (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  user_id uuid references profiles(id) on delete cascade not null,
  amount numeric not null,
  status payment_status default 'pending',
  method payment_method not null,
  receipt_url text,
  transaction_id text,
  processed_by uuid references profiles(id) on delete set null,
  recipient_id uuid references profiles(id) on delete set null,
  duration_minutes integer,
  rejection_reason text
);

alter table appointments add foreign key (payment_id) references payments(id) on delete set null;

-- Consultation Credits / Time Balances
create table time_balances (
  patient_id uuid references profiles(id) on delete cascade not null,
  doctor_id uuid references profiles(id) on delete cascade not null,
  minutes_remaining integer not null default 0,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  primary key (patient_id, doctor_id)
);

-- Messaging
create table messages (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  sender_id uuid references profiles(id) on delete cascade not null,
  receiver_id uuid references profiles(id) on delete cascade not null,
  content text not null,
  is_read boolean default false,
  attachments jsonb default '[]'::jsonb,
  type text default 'text' check (type in ('text', 'attachment', 'audio', 'location')),
  metadata jsonb default '{}'::jsonb
);

-- Notifications
create table notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references profiles(id) on delete cascade not null,
  title text not null,
  message text not null,
  type text check (type in ('appointment', 'payment', 'prescription', 'message', 'admin_message', 'system', 'appointment_proposal', 'other')) default 'other',
  is_read boolean default false,
  link text,
  fcm_status text default 'pending',
  created_at timestamp with time zone default now()
);

-- Health Records & Medical Vault
create table medical_records (
  id uuid default uuid_generate_v4() primary key,
  patient_id uuid references profiles(id) on delete cascade not null,
  title text not null,
  description text,
  record_type record_type not null default 'other'::record_type,
  document_url text not null,
  authorized_doctors uuid[] default '{}'::uuid[],
  created_at timestamp with time zone default now()
);

create table health_records (
  id uuid default uuid_generate_v4() primary key,
  patient_id uuid references profiles(id) on delete cascade not null,
  doctor_id uuid references profiles(id) on delete set null,
  content text not null,
  created_at timestamp with time zone default now()
);

create table medical_documents (
  id uuid default uuid_generate_v4() primary key,
  patient_id uuid references profiles(id) on delete cascade not null,
  title text not null,
  file_url text not null,
  file_type text,
  status text default 'active' check (status in ('active', 'archived', 'deleted')),
  created_at timestamp with time zone default now()
);

create table fee_negotiation_messages (
  id uuid default uuid_generate_v4() primary key,
  doctor_id uuid references profiles(id) on delete cascade not null,
  sender_id uuid references profiles(id) on delete set null,
  sender_role text not null check (sender_role in ('doctor', 'admin')),
  message text not null,
  created_at timestamp with time zone default now()
);

create table record_permissions (
  id uuid default uuid_generate_v4() primary key,
  record_id uuid references medical_records(id) on delete cascade not null,
  doctor_id uuid references profiles(id) on delete cascade not null,
  granted_at timestamp with time zone default now(),
  unique(record_id, doctor_id)
);

create table medical_profiles (
  id uuid references profiles(id) on delete cascade not null primary key,
  blood_group text,
  genotype text,
  allergies text,
  chronic_conditions text,
  emergency_contact_name text,
  emergency_contact_phone text,
  updated_at timestamp with time zone default now()
);

create table prescriptions (
  id uuid default uuid_generate_v4() primary key,
  appointment_id uuid references appointments(id) on delete set null,
  patient_id uuid references profiles(id) on delete cascade not null,
  doctor_id uuid references profiles(id) on delete cascade not null,
  medication_name text not null,
  dosage text not null,
  frequency text not null,
  duration text not null,
  instructions text,
  special_instructions text,
  created_at timestamp with time zone default now()
);

create table admin_notification_settings (
  admin_id uuid references profiles(id) on delete cascade not null primary key,
  alert_types text[] default '{}'::text[],
  updated_at timestamp with time zone default now()
);

alter table medical_profiles enable row level security;
alter table prescriptions enable row level security;
alter table admin_notification_settings enable row level security;
alter table health_records enable row level security;
alter table medical_documents enable row level security;
alter table fee_negotiation_messages enable row level security;

create policy "Patients can manage their medical profiles" on medical_profiles for all using (auth.uid() = id);
create policy "Patients can view their prescriptions" on prescriptions for select using (auth.uid() = patient_id);
create policy "Doctors can insert prescriptions" on prescriptions for insert with check (auth.uid() = doctor_id);
create policy "Doctors can view prescriptions" on prescriptions for select using (auth.uid() = doctor_id);
create policy "Admins can manage notification settings" on admin_notification_settings for all using (auth.uid() = admin_id);
create policy "Patients and doctors can view health records" on health_records for select using (auth.uid() = patient_id or auth.uid() = doctor_id);
create policy "Doctors can create health records" on health_records for insert with check (auth.uid() = doctor_id);
create policy "Patients can view their medical documents" on medical_documents for select using (auth.uid() = patient_id);
create policy "Patients can upload their medical documents" on medical_documents for insert with check (auth.uid() = patient_id);
create policy "Doctors and admins can view fee negotiations" on fee_negotiation_messages for select using (
  auth.uid() = doctor_id or exists (select 1 from profiles where id = auth.uid() and role = 'admin')
);
create policy "Doctors and admins can send fee negotiation messages" on fee_negotiation_messages for insert with check (
  auth.uid() = sender_id and (auth.uid() = doctor_id or exists (select 1 from profiles where id = auth.uid() and role = 'admin'))
);

-- Forum tables are defined in the FORUM ECOSYSTEM section below (line ~635+)

-- Subscription Plans
create table subscription_plans (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  description text,
  price decimal(12,2) not null,
  duration_months integer not null,
  features text[] default '{}'::text[],
  is_active boolean default true,
  created_at timestamp with time zone default now()
);

create table doctor_subscriptions (
  id uuid default uuid_generate_v4() primary key,
  doctor_id uuid references profiles(id) on delete cascade not null,
  plan_id uuid references subscription_plans(id) on delete set null,
  status subscription_status default 'active'::subscription_status,
  start_date timestamp with time zone default now(),
  expiry_date timestamp with time zone not null,
  last_payment_date timestamp with time zone,
  last_payment_amount decimal(12,2),
  auto_renew boolean default true,
  created_at timestamp with time zone default now()
);

-- Reviews
create table reviews (
  id uuid default uuid_generate_v4() primary key,
  appointment_id uuid references appointments(id) unique not null,
  patient_id uuid references profiles(id) on delete cascade not null,
  doctor_id uuid references profiles(id) on delete cascade not null,
  rating integer not null check (rating >= 1 and rating <= 5),
  comment text,
  created_at timestamp with time zone default now()
);

-- ============================================================
-- RLS POLICIES
-- ============================================================

alter table profiles enable row level security;
alter table doctor_schedules enable row level security;
alter table appointments enable row level security;
alter table payments enable row level security;
alter table time_balances enable row level security;

create policy "Patients can view their own time balances"
  on time_balances for select
  using (auth.uid() = patient_id);

create policy "Doctors can view their patients' time balances"
  on time_balances for select
  using (auth.uid() = doctor_id);
alter table messages enable row level security;
alter table notifications enable row level security;
alter table medical_records enable row level security;
alter table record_permissions enable row level security;
-- Forum RLS is enabled in the FORUM ECOSYSTEM section below
alter table subscription_plans enable row level security;
alter table doctor_subscriptions enable row level security;
alter table reviews enable row level security;
alter table system_settings enable row level security;

-- ============================================================
-- PROFILES
-- ============================================================
-- Anyone can read profiles (doctor listings, messaging lookups)
create policy "Anyone can view profiles"
  on profiles for select
  using (true);

-- Users can update their own profile
create policy "Users can update own profile"
  on profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Users can insert their own profile (via trigger, but policy needed for safety)
create policy "Users can insert own profile"
  on profiles for insert
  with check (auth.uid() = id);

-- Admins can update any profile (suspend, verify, etc.)
create policy "Admins can update any profile"
  on profiles for update
  using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- ============================================================
-- DOCTOR SCHEDULES
-- ============================================================
-- Doctors can view their own schedule
create policy "Doctors can view own schedule"
  on doctor_schedules for select
  using (auth.uid() = doctor_id);

-- Any authenticated user can view schedules (for booking)
create policy "Authenticated users can view doctor schedules"
  on doctor_schedules for select
  using (auth.role() = 'authenticated');

-- Doctors can insert their own schedule (for upsert)
create policy "Doctors can insert own schedule"
  on doctor_schedules for insert
  with check (auth.uid() = doctor_id);

-- Doctors can update their own schedule
create policy "Doctors can update own schedule"
  on doctor_schedules for update
  using (auth.uid() = doctor_id)
  with check (auth.uid() = doctor_id);

-- ============================================================
-- APPOINTMENTS
-- ============================================================
-- Patients can view their own appointments
create policy "Patients can view own appointments"
  on appointments for select
  using (auth.uid() = patient_id);

-- Guests can view emergency appointments where patient_id is null
create policy "Guests can view own emergency appointments"
  on appointments for select
  using (patient_id IS NULL AND is_emergency = true AND metadata->>'guest_token' IS NOT NULL);

-- Doctors can view appointments assigned to them
create policy "Doctors can view their appointments"
  on appointments for select
  using (auth.uid() = doctor_id);

-- Patients can create their own appointments
create policy "Patients can create own appointments"
  on appointments for insert
  with check (auth.uid() = patient_id);

-- Allow authenticated users to insert guest emergency appointments (patient_id IS NULL)
create policy "Authenticated users can create guest emergency appointments"
  on appointments for insert
  with check (patient_id IS NULL AND is_emergency = true);

-- Patients can update their own appointments (link patient_id, etc.)
create policy "Patients can update own appointments"
  on appointments for update
  using (auth.uid() = patient_id)
  with check (auth.uid() = patient_id);

-- Allow linking guest appointments after account creation
create policy "Authenticated users can link guest emergency appointments"
  on appointments for update
  using (patient_id IS NULL AND is_emergency = true)
  with check (auth.uid() = patient_id);

-- Doctors can update appointments assigned to them
create policy "Doctors can update own appointments"
  on appointments for update
  using (auth.uid() = doctor_id)
  with check (auth.uid() = doctor_id);

-- Admins can manage all appointments
create policy "Admins can manage all appointments"
  on appointments for all
  using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- ============================================================
-- PAYMENTS
-- ============================================================
-- Patients can view their own payments
create policy "Patients can view own payments"
  on payments for select
  using (auth.uid() = user_id);

-- Patients can create payments for themselves
create policy "Patients can create own payments"
  on payments for insert
  with check (auth.uid() = user_id);

-- Doctors can view payments where they are the recipient
create policy "Doctors can view their received payments"
  on payments for select
  using (auth.uid() = recipient_id);

-- Recipients (doctors) can update payment status (approve/reject)
create policy "Recipients can update payment status"
  on payments for update
  using (auth.uid() = recipient_id);

-- Admins can view and manage all payments
create policy "Admins can manage all payments"
  on payments for all
  using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- ============================================================
-- TIME BALANCES
-- ============================================================
-- (policies defined above near the time_balances enable)

-- ============================================================
-- MESSAGES
-- ============================================================
-- Users can view messages they sent
create policy "Users can view sent messages"
  on messages for select
  using (auth.uid() = sender_id);

-- Users can view messages they received
create policy "Users can view received messages"
  on messages for select
  using (auth.uid() = receiver_id);

-- Users can send messages
create policy "Users can send messages"
  on messages for insert
  with check (auth.uid() = sender_id);

-- Users can update their own messages (mark read)
create policy "Users can update own messages"
  on messages for update
  using (auth.uid() = sender_id or auth.uid() = receiver_id);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
-- Users can view their own notifications
create policy "Users can view own notifications"
  on notifications for select
  using (auth.uid() = user_id);

-- Users can update their own notifications (mark read)
create policy "Users can update own notifications"
  on notifications for update
  using (auth.uid() = user_id);

-- Users can only create notifications for themselves (or use SECURITY DEFINER functions for system-level notifications)
create policy "Users can create own notifications"
  on notifications for insert
  with check (auth.uid() = user_id);

-- System-level notifications bypass RLS via SECURITY DEFINER functions (e.g., approve_payment, reject_payment)

-- Admins can view all notifications (for admin panel)
create policy "Admins can view all notifications"
  on notifications for select
  using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

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

-- Patients can view their own records
create policy "Patients can view own records"
  on medical_records for select
  using (auth.uid() = patient_id);

-- Patients can upload their own records
create policy "Patients can insert own records"
  on medical_records for insert
  with check (auth.uid() = patient_id);

-- Patients can update their own records
create policy "Patients can update own records"
  on medical_records for update
  using (auth.uid() = patient_id)
  with check (auth.uid() = patient_id);

-- Patients can delete their own records
create policy "Patients can delete own records"
  on medical_records for delete
  using (auth.uid() = patient_id);

-- Doctors can view records shared via authorized_doctors array OR record_permissions
-- Uses SECURITY DEFINER function to break circular RLS dependency
drop policy if exists "Doctors can view shared records" on public.medical_records;

create policy "Doctors can view shared records"
  on medical_records for select
  using (
    auth.uid() = ANY(authorized_doctors)
    or public.doctor_has_record_access(auth.uid(), id)
  );

-- Admins can view all medical records (for admin stats)
create policy "Admins can view all medical records"
  on medical_records for select
  using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- ============================================================
-- RECORD PERMISSIONS
-- ============================================================
-- Patients can view permissions on their own records
create policy "Patients can view own record permissions"
  on record_permissions for select
  using (
    exists (
      select 1 from medical_records
      where medical_records.id = record_permissions.record_id
        and medical_records.patient_id = auth.uid()
    )
  );

-- Patients can manage permissions on their own records
create policy "Patients can manage own record permissions"
  on record_permissions for all
  using (
    exists (
      select 1 from medical_records
      where medical_records.id = record_permissions.record_id
        and medical_records.patient_id = auth.uid()
    )
  );

-- Doctors can view permissions granted to them
create policy "Doctors can view permissions granted to them"
  on record_permissions for select
  using (auth.uid() = doctor_id);

-- ============================================================
-- SUBSCRIPTION PLANS
-- ============================================================
-- Anyone can view active subscription plans
create policy "Anyone can view subscription plans"
  on subscription_plans for select
  using (true);

-- ============================================================
-- DOCTOR SUBSCRIPTIONS
-- ============================================================
-- Doctors can view their own subscriptions
create policy "Doctors can view own subscriptions"
  on doctor_subscriptions for select
  using (auth.uid() = doctor_id);

-- Admins can view all subscriptions
create policy "Admins can view all subscriptions"
  on doctor_subscriptions for select
  using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- ============================================================
-- REVIEWS
-- ============================================================
-- Anyone can view reviews
create policy "Anyone can view reviews"
  on reviews for select
  using (true);

-- Patients can create reviews for their completed appointments
create policy "Patients can create reviews"
  on reviews for insert
  with check (auth.uid() = patient_id);

-- Patients can update their own reviews
create policy "Patients can update own reviews"
  on reviews for update
  using (auth.uid() = patient_id)
  with check (auth.uid() = patient_id);

-- ============================================================
-- SYSTEM SETTINGS
-- ============================================================
-- SECURITY FIX: Only authenticated users can view system settings (not anonymous)
create policy "Authenticated users can view system settings"
  on system_settings for select
  using (auth.role() = 'authenticated');

-- Admins can update system settings
create policy "Admins can update system settings"
  on system_settings for update
  using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Function to auto-create profile on user signup
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

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_new_user();

-- Function to handle schedule initialization on profile promotion
CREATE OR REPLACE FUNCTION public.initialize_doctor_schedule()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'doctor' AND (OLD.role IS NULL OR OLD.role != 'doctor') THEN
    INSERT INTO doctor_schedules (doctor_id)
    VALUES (NEW.id)
    ON CONFLICT (doctor_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_doctor_promotion
  AFTER UPDATE OF role ON profiles
  FOR EACH ROW
  EXECUTE PROCEDURE public.initialize_doctor_schedule();

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

CREATE TRIGGER on_appointment_completed
  AFTER UPDATE OF status ON public.appointments
  FOR EACH ROW
  EXECUTE PROCEDURE public.update_doctor_consultation_count();

-- Forum: RPC functions for upvotes and helpful votes
CREATE OR REPLACE FUNCTION public.increment_forum_upvote(p_post_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE forum_posts SET upvotes = upvotes + 1 WHERE id = p_post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.increment_reply_helpful(p_reply_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE forum_replies SET helpful_votes = helpful_votes + 1 WHERE id = p_reply_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION increment_time_balance(
    p_patient_id UUID,
    p_doctor_id UUID,
    p_minutes INTEGER
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO time_balances (patient_id, doctor_id, minutes_remaining)
    VALUES (p_patient_id, p_doctor_id, p_minutes)
    ON CONFLICT (patient_id, doctor_id)
    DO UPDATE SET 
        minutes_remaining = time_balances.minutes_remaining + p_minutes,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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

CREATE OR REPLACE FUNCTION public.sweep_offline_doctors() 
RETURNS void AS $$
BEGIN
    UPDATE public.profiles SET is_online = false 
    WHERE role = 'doctor' AND is_online = true AND last_seen < now() - interval '2 minutes';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================
-- GDPR: RIGHT TO ERASURE (SOFT DELETE + PURGE)
-- ============================================================

-- Soft-delete: marks profile and related data for deletion
CREATE OR REPLACE FUNCTION public.soft_delete_user(p_user_id uuid, p_reason text DEFAULT null)
RETURNS jsonb AS $$
BEGIN
  -- Only the user themselves or an admin can trigger
  IF auth.uid() != p_user_id AND NOT EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RETURN jsonb_build_object('error', 'Unauthorized');
  END IF;

  -- Mark profile as soft-deleted
  UPDATE public.profiles
  SET deleted_at = now(),
      deletion_reason = p_reason,
      account_status = 'suspended'
  WHERE id = p_user_id;

  -- Anonymize the auth email to prevent re-use
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

-- Purge: permanently deletes accounts soft-deleted 30+ days ago
CREATE OR REPLACE FUNCTION public.purge_deleted_accounts()
RETURNS void AS $$
DECLARE
  v_user record;
BEGIN
  FOR v_user IN
    SELECT id FROM profiles
    WHERE deleted_at IS NOT NULL AND deleted_at < now() - interval '30 days'
  LOOP
    -- Delete from auth (cascades to profiles via FK)
    DELETE FROM auth.users WHERE id = v_user.id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================
-- GDPR: RIGHT TO DATA PORTABILITY (EXPORT)
-- ============================================================

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
  -- Only the user themselves can export
  IF auth.uid() != p_user_id THEN
    RETURN jsonb_build_object('error', 'Unauthorized');
  END IF;

  SELECT to_jsonb(p.*) INTO v_profile
  FROM profiles p WHERE p.id = p_user_id;

  SELECT jsonb_agg(to_jsonb(a.*)) INTO v_appointments
  FROM appointments a WHERE a.patient_id = p_user_id;

  SELECT jsonb_agg(to_jsonb(m.*)) INTO v_messages
  FROM messages m WHERE m.sender_id = p_user_id OR m.receiver_id = p_user_id;

  SELECT jsonb_agg(to_jsonb(mr.*)) INTO v_medical_records
  FROM medical_records mr WHERE mr.patient_id = p_user_id;

  SELECT jsonb_agg(to_jsonb(pr.*)) INTO v_prescriptions
  FROM prescriptions pr WHERE pr.patient_id = p_user_id;

  SELECT jsonb_agg(to_jsonb(pay.*)) INTO v_payments
  FROM payments pay WHERE pay.user_id = p_user_id;

  SELECT jsonb_agg(to_jsonb(r.*)) INTO v_reviews
  FROM reviews r WHERE r.patient_id = p_user_id;

  SELECT jsonb_agg(to_jsonb(fp.*)) INTO v_forum_posts
  FROM forum_posts fp WHERE fp.author_id = p_user_id;

  SELECT jsonb_agg(to_jsonb(fr.*)) INTO v_forum_replies
  FROM forum_replies fr WHERE fr.author_id = p_user_id;

  INSERT INTO audit_logs (user_id, action, action_type, severity, description)
  VALUES (p_user_id, 'data_export_completed', 'security', 'info',
          'User exercised right to data portability');

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

-- ============================================================
-- HIPAA: PHI ACCESS AUDIT LOGGING
-- ============================================================

CREATE OR REPLACE FUNCTION public.log_phi_access(
  p_user_id uuid,
  p_action text,
  p_resource_type text,
  p_resource_id uuid DEFAULT NULL,
  p_details jsonb DEFAULT '{}'::jsonb
)
RETURNS void AS $$
BEGIN
  INSERT INTO audit_logs (user_id, action, action_type, severity, description, details)
  VALUES (
    p_user_id,
    p_action,
    'security',
    CASE
      WHEN p_action IN ('medical_record_accessed', 'prescription_accessed', 'phi_exported') THEN 'moderate'
      ELSE 'info'
    END,
    p_resource_type || ' ' || COALESCE(p_action, '') || ' by ' || p_user_id::text,
    p_details || jsonb_build_object('resource_type', p_resource_type, 'resource_id', p_resource_id)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================
-- DATA RETENTION: AUTO-CLEANUP FUNCTIONS
-- ============================================================

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

-- ============================================================
-- OTP RATE LIMITING FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION public.cleanup_old_login_attempts()
RETURNS void AS $$
BEGIN
    DELETE FROM public.login_attempts WHERE attempted_at < now() - interval '1 hour';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.check_otp_rate_limit(p_email text)
RETURNS jsonb AS $$
DECLARE
    v_max_attempts int := 5;
    v_lockout_minutes int := 15;
    v_recent_failures int;
    v_locked_until timestamp with time zone;
BEGIN
    SELECT count(*) INTO v_recent_failures
    FROM public.login_attempts
    WHERE email = lower(p_email)
        AND success = false
        AND attempted_at > now() - (v_lockout_minutes || ' minutes')::interval;

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

CREATE OR REPLACE FUNCTION public.record_otp_attempt(p_email text, p_ip_address text DEFAULT null)
RETURNS void AS $$
BEGIN
    INSERT INTO public.login_attempts (email, ip_address, success)
    VALUES (lower(p_email), p_ip_address, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.reset_otp_attempts(p_email text)
RETURNS void AS $$
BEGIN
    INSERT INTO public.login_attempts (email, success)
    VALUES (lower(p_email), true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE EXECUTE ON FUNCTION public.check_otp_rate_limit(text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.record_otp_attempt(text, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.reset_otp_attempts(text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.check_otp_rate_limit(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_otp_attempt(text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reset_otp_attempts(text) TO anon, authenticated;

-- GDPR function GRANTs
GRANT EXECUTE ON FUNCTION public.soft_delete_user(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.export_user_data(uuid) TO authenticated;

-- HIPAA audit function GRANTs
GRANT EXECUTE ON FUNCTION public.log_phi_access(uuid, text, text, uuid, jsonb) TO authenticated;

-- Data retention function GRANTs (service_role only — for cron jobs)
GRANT EXECUTE ON FUNCTION public.purge_deleted_accounts() TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_old_notifications() TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_old_device_sessions() TO service_role;

-- ============================================================
-- REALTIME
-- ============================================================
DO $$ BEGIN
  alter publication supabase_realtime add table appointments;
  alter publication supabase_realtime add table messages;
  alter publication supabase_realtime add table notifications;
  alter publication supabase_realtime add table doctor_schedules;
  alter publication supabase_realtime add table profiles;
  alter publication supabase_realtime add table payments;
  alter publication supabase_realtime add table time_balances;
  alter publication supabase_realtime add table medical_records;
  alter publication supabase_realtime add table reviews;
  alter publication supabase_realtime add table fee_negotiation_messages;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping publication adds: %', SQLERRM;
END $$;

-- Replica Identity for Real-time (safe — skip if not table owner)
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

-- Realtime messages RLS policies (required for private channels)
DO $$ BEGIN
  ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

  CREATE POLICY "authenticated_users_can_receive_broadcasts"
    ON realtime.messages FOR SELECT
    TO authenticated
    USING (true);

  CREATE POLICY "authenticated_users_can_send_broadcasts"
    ON realtime.messages FOR INSERT
    TO authenticated
    WITH CHECK (true);
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping realtime.messages RLS: %', SQLERRM;
END $$;

-- ============================================================
-- AUDIT & SECURITY
-- ============================================================
create table audit_logs (
    id uuid default uuid_generate_v4() primary key,
    created_at timestamp with time zone default now(),
    user_id uuid references profiles(id) on delete set null,
    admin_id uuid references profiles(id) on delete set null,
    action text not null,
    action_type audit_action_type default 'system',
    severity audit_severity not null default 'info',
    description text,
    details jsonb default '{}'::jsonb,
    metadata jsonb default '{}'::jsonb
);

alter table audit_logs enable row level security;

create policy "Admins can view audit logs" on audit_logs
    for select using (
        exists (
            select 1 from profiles
            where id = auth.uid() and role = 'admin'
        )
    );

create policy "Users can view own audit logs" on audit_logs
    for select using (
        auth.uid() = user_id
    );

create policy "Admins can insert audit logs" on audit_logs
    for insert with check (
        exists (
            select 1 from profiles
            where id = auth.uid() and role = 'admin'
        )
    );

create policy "Authenticated users can insert own audit logs" on audit_logs
    for insert with check (
        auth.uid() = user_id
    );

create table device_sessions (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) on delete cascade not null,
    device_name text not null,
    ip_address text,
    location text,
    last_active_at timestamp with time zone default now(),
    is_current boolean default false,
    created_at timestamp with time zone default now()
);

alter table device_sessions enable row level security;

create policy "Users can view their own device sessions" on device_sessions
    for select using (auth.uid() = user_id);

create policy "Users can delete their own device sessions" on device_sessions
    for delete using (auth.uid() = user_id);

-- ============================================================
-- OTP RATE LIMITING & ACCOUNT LOCKOUT
-- ============================================================

create table login_attempts (
    id uuid default uuid_generate_v4() primary key,
    email text not null,
    attempted_at timestamp with time zone default now(),
    success boolean default false,
    ip_address text
);

alter table login_attempts enable row level security;

create policy "Service role manages login_attempts"
    on login_attempts for all
    using (true);

create index if not exists idx_login_attempts_email
    on login_attempts (email, attempted_at desc);


-- ============================================================
-- MODERATION, PAYOUTS & DISPUTES SYSTEM
-- ============================================================

-- 1. Payouts System
create table payouts (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  doctor_id uuid references profiles(id) not null,
  amount numeric not null,
  status payout_status default 'pending',
  transaction_count integer default 0,
  due_date timestamp with time zone,
  processed_at timestamp with time zone,
  processed_by uuid references profiles(id),
  rejection_reason text
);

alter table payouts enable row level security;

create policy "Admins can manage payouts"
  on payouts for all
  using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

create policy "Doctors can view their own payouts"
  on payouts for select
  using (auth.uid() = doctor_id);

DROP VIEW IF EXISTS public.pending_payments_view;

CREATE VIEW pending_payments_view
  WITH (security_invoker = true)
AS
SELECT p.*, u.full_name as patient_name, u.avatar_url as patient_avatar
FROM payments p JOIN profiles u ON p.user_id = u.id WHERE p.status = 'pending';

-- 2. Refunds System
create table refunds (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  payment_id uuid references payments(id) not null,
  patient_id uuid references profiles(id) not null,
  amount numeric not null,
  reason text,
  status refund_status default 'pending',
  processed_at timestamp with time zone,
  processed_by uuid references profiles(id)
);

alter table refunds enable row level security;

create policy "Admins can manage refunds"
  on refunds for all
  using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

create policy "Users can view their own refunds"
  on refunds for select
  using (auth.uid() = patient_id);

-- 3. Disputes System
create table disputes (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  transaction_id text not null,
  user_id uuid references profiles(id) not null,
  patient_id uuid references profiles(id),
  doctor_id uuid references profiles(id),
  amount numeric,
  risk_level text check (risk_level in ('low', 'medium', 'high')) default 'low',
  category text check (category in ('payment', 'consultation', 'refund', 'fraud', 'behavior', 'other')) default 'other',
  title text not null,
  description text,
  status dispute_status default 'open',
  resolution_notes text,
  resolved_at timestamp with time zone,
  resolved_by uuid references profiles(id)
);

alter table disputes enable row level security;

create policy "Admins can manage disputes"
  on disputes for all
  using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

-- SECURITY FIX: Users (patients/doctors) can create disputes
create policy "Authenticated users can create disputes"
  on disputes for insert
  with check (auth.uid() = user_id);

-- SECURITY FIX: Users can view disputes where they are user, patient, or doctor
create policy "Users can view their own disputes"
  on disputes for select
  using (auth.uid() = user_id OR auth.uid() = patient_id OR auth.uid() = doctor_id);

-- 4. Blocked Users System
create table blocked_users (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  user_id uuid references profiles(id) not null unique,
  reason text,
  blocked_by uuid references profiles(id) not null
);

alter table blocked_users enable row level security;

create policy "Admins can manage blocked users"
  on blocked_users for all
  using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

-- SECURITY FIX: Users can only see their own block status (not other users' blocks)
create policy "Users can view own block status"
  on blocked_users for select
  using (auth.uid() = user_id);

-- 5. Notification Config System
create table notification_channels_config (
  id text primary key,
  is_enabled boolean default true,
  config jsonb default '{}'::jsonb,
  updated_at timestamp with time zone default now()
);

alter table notification_channels_config enable row level security;

create policy "Admins can manage channel config"
  on notification_channels_config for all
  using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

create policy "Anyone can view channel config"
  on notification_channels_config for select
  using (true);

-- 6. Analytics Helper Functions
create or replace function get_admin_financial_stats()
returns json
AS $$
declare
  total_revenue numeric;
  total_payouts numeric;
  pending_payouts numeric;
  total_refunds numeric;
begin
  select coalesce(sum(amount), 0) into total_revenue from payments where status = 'approved';
  select coalesce(sum(amount), 0) into total_payouts from payouts where status = 'approved';
  select coalesce(sum(amount), 0) into pending_payouts from payouts where status = 'pending';
  select coalesce(sum(amount), 0) into total_refunds from refunds where status = 'approved';

  return json_build_object(
    'total_revenue', total_revenue,
    'total_payouts', total_payouts,
    'pending_payouts', pending_payouts,
    'total_refunds', total_refunds
  );
end;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- ============================================================
-- DATA API GRANTS (Supabase May 30 Update Compliance)
-- ============================================================

-- profiles
GRANT SELECT ON public.profiles TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO service_role;

-- doctor_schedules
GRANT SELECT ON public.doctor_schedules TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.doctor_schedules TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.doctor_schedules TO service_role;

-- system_settings
GRANT SELECT ON public.system_settings TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.system_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.system_settings TO service_role;

-- appointments
GRANT SELECT ON public.appointments TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.appointments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.appointments TO service_role;

-- payments
GRANT SELECT ON public.payments TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.payments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.payments TO service_role;

-- time_balances
GRANT SELECT ON public.time_balances TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.time_balances TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.time_balances TO service_role;

-- messages
GRANT SELECT ON public.messages TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.messages TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.messages TO service_role;

-- notifications
GRANT SELECT ON public.notifications TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO service_role;

-- medical_records
GRANT SELECT ON public.medical_records TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.medical_records TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.medical_records TO service_role;

-- health_records
GRANT SELECT ON public.health_records TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.health_records TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.health_records TO service_role;

-- medical_documents
GRANT SELECT ON public.medical_documents TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.medical_documents TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.medical_documents TO service_role;

-- fee_negotiation_messages
GRANT SELECT ON public.fee_negotiation_messages TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.fee_negotiation_messages TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.fee_negotiation_messages TO service_role;

-- record_permissions
GRANT SELECT ON public.record_permissions TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.record_permissions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.record_permissions TO service_role;

-- medical_profiles
GRANT SELECT ON public.medical_profiles TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.medical_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.medical_profiles TO service_role;

-- prescriptions
GRANT SELECT ON public.prescriptions TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.prescriptions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.prescriptions TO service_role;

-- admin_notification_settings
GRANT SELECT ON public.admin_notification_settings TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.admin_notification_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.admin_notification_settings TO service_role;

-- pending_payments_view
GRANT SELECT ON public.pending_payments_view TO anon;
GRANT SELECT ON public.pending_payments_view TO authenticated;
GRANT SELECT ON public.pending_payments_view TO service_role;

-- Revoke EXECUTE from PUBLIC (default), re-grant to authenticated only
REVOKE EXECUTE ON FUNCTION public.approve_payment(UUID, UUID) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.reject_payment(UUID, TEXT, UUID) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_admin_financial_stats() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.increment_time_balance(UUID, UUID, INTEGER) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.initialize_doctor_schedule() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.sweep_offline_doctors() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.doctor_has_record_access(UUID, UUID) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.doctor_has_record_access(UUID, UUID) TO authenticated;

GRANT EXECUTE ON FUNCTION public.approve_payment(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_payment(UUID, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_financial_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_time_balance(UUID, UUID, INTEGER) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.increment_forum_upvote(UUID) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.increment_reply_helpful(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_forum_upvote(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_reply_helpful(UUID) TO authenticated;

-- SECURITY: Explicit REVOKE from anon for all SECURITY DEFINER functions
-- (Supabase grants anon EXECUTE by default; REVOKE FROM PUBLIC is insufficient)
-- Only check_otp_rate_limit, record_otp_attempt, reset_otp_attempts
-- are callable by anon (pre-auth login flow).
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon;
REVOKE EXECUTE ON FUNCTION public.initialize_doctor_schedule() FROM anon;
REVOKE EXECUTE ON FUNCTION public.update_doctor_review_count() FROM anon;
REVOKE EXECUTE ON FUNCTION public.update_doctor_consultation_count() FROM anon;
REVOKE EXECUTE ON FUNCTION public.increment_forum_upvote(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.increment_reply_helpful(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.sweep_offline_doctors() FROM anon;
REVOKE EXECUTE ON FUNCTION public.doctor_has_record_access(UUID, UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.approve_payment(UUID, UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.reject_payment(UUID, TEXT, UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_admin_financial_stats() FROM anon;
REVOKE EXECUTE ON FUNCTION public.increment_time_balance(UUID, UUID, INTEGER) FROM anon;

-- SECURITY: Explicit REVOKE from authenticated for admin/service-only functions
-- These functions have internal auth checks but should not be callable by
-- arbitrary authenticated users.
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.initialize_doctor_schedule() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.update_doctor_review_count() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.update_doctor_consultation_count() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.sweep_offline_doctors() FROM authenticated;

-- forum_posts & forum_replies grants are in the FORUM ECOSYSTEM section below

-- subscription_plans
GRANT SELECT ON public.subscription_plans TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.subscription_plans TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.subscription_plans TO service_role;

-- doctor_subscriptions
GRANT SELECT ON public.doctor_subscriptions TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.doctor_subscriptions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.doctor_subscriptions TO service_role;

-- reviews
GRANT SELECT ON public.reviews TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.reviews TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.reviews TO service_role;

-- audit_logs
GRANT SELECT ON public.audit_logs TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.audit_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.audit_logs TO service_role;

-- device_sessions
GRANT SELECT ON public.device_sessions TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.device_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.device_sessions TO service_role;

-- login_attempts
GRANT SELECT, INSERT, DELETE ON public.login_attempts TO service_role;

-- payouts
GRANT SELECT ON public.payouts TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.payouts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.payouts TO service_role;

-- refunds
GRANT SELECT ON public.refunds TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.refunds TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.refunds TO service_role;

-- disputes
GRANT SELECT ON public.disputes TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.disputes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.disputes TO service_role;

-- blocked_users
GRANT SELECT ON public.blocked_users TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.blocked_users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.blocked_users TO service_role;

-- notification_channels_config
GRANT SELECT ON public.notification_channels_config TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notification_channels_config TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notification_channels_config TO service_role;

-- ----------------------------------------------------------------------------
-- FORUM ECOSYSTEM
-- ----------------------------------------------------------------------------

create table forum_categories (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  name text not null,
  description text,
  icon_name text,
  is_active boolean default true
);

create table forum_posts (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  author_id uuid references profiles(id) on delete cascade not null,
  category_id uuid references forum_categories(id) on delete set null,
  title text not null,
  content text not null,
  attachments text[],
  is_anonymous boolean default false,
  is_ask_doctor_queue boolean default false,
  status forum_post_status default 'approved'::forum_post_status,
  upvotes integer default 0,
  view_count integer default 0
);

create table forum_replies (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  post_id uuid references forum_posts(id) on delete cascade not null,
  author_id uuid references profiles(id) on delete cascade not null,
  content text not null,
  attachments text[],
  is_anonymous boolean default false,
  replied_as_doctor boolean default false, -- Core Dual Identity Tracker
  helpful_votes integer default 0,
  is_accepted_answer boolean default false,
  status forum_post_status default 'approved'::forum_post_status
);

create table forum_reports (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  reporter_id uuid references profiles(id) on delete cascade not null,
  post_id uuid references forum_posts(id) on delete cascade,
  reply_id uuid references forum_replies(id) on delete cascade,
  reason text not null,
  status forum_report_status default 'pending'::forum_report_status,
  resolved_at timestamp with time zone,
  resolved_by uuid references profiles(id)
);

create table forum_saves (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  user_id uuid references profiles(id) on delete cascade not null,
  post_id uuid references forum_posts(id) on delete cascade not null,
  unique(user_id, post_id)
);

create table forum_follows (
  id uuid default uuid_generate_v4() primary key,
  created_at timestamp with time zone default now(),
  user_id uuid references profiles(id) on delete cascade not null,
  post_id uuid references forum_posts(id) on delete cascade,
  category_id uuid references forum_categories(id) on delete cascade,
  check ((post_id is not null and category_id is null) or (post_id is null and category_id is not null))
);

-- FORUM GRANTS
GRANT SELECT ON public.forum_categories TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_categories TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_categories TO service_role;

GRANT SELECT ON public.forum_posts TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_posts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_posts TO service_role;

GRANT SELECT ON public.forum_replies TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_replies TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_replies TO service_role;

GRANT SELECT ON public.forum_reports TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_reports TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_reports TO service_role;

GRANT SELECT ON public.forum_saves TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_saves TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_saves TO service_role;

GRANT SELECT ON public.forum_follows TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_follows TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.forum_follows TO service_role;

-- FORUM RLS
alter table forum_categories enable row level security;
alter table forum_posts enable row level security;
alter table forum_replies enable row level security;
alter table forum_reports enable row level security;
alter table forum_saves enable row level security;
alter table forum_follows enable row level security;

DO $$ BEGIN
  alter publication supabase_realtime add table forum_posts;
  alter publication supabase_realtime add table forum_replies;
  alter publication supabase_realtime add table forum_reports;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping forum publication adds: %', SQLERRM;
END $$;

DO $$ BEGIN
  ALTER TABLE forum_reports REPLICA IDENTITY FULL;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping REPLICA IDENTITY on forum_reports: %', SQLERRM;
END $$;

-- ── forum_categories ──
create policy "Anyone can view active categories"
  on forum_categories for select
  using (is_active = true);

create policy "Admins can manage categories"
  on forum_categories for all
  using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

-- ── forum_posts ──
create policy "Anyone can read approved posts"
  on forum_posts for select
  using (status = 'approved' or auth.uid() = author_id);

create policy "Authenticated users can create posts"
  on forum_posts for insert
  with check (auth.uid() = author_id);

create policy "Authors can update own posts"
  on forum_posts for update
  using (auth.uid() = author_id);

-- SECURITY FIX: Authors can delete their own posts
create policy "Authors can delete own posts"
  on forum_posts for delete
  using (auth.uid() = author_id);

create policy "Admins can moderate all posts"
  on forum_posts for all
  using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

-- ── forum_replies ──
create policy "Anyone can read approved replies"
  on forum_replies for select
  using (status = 'approved' or auth.uid() = author_id);

create policy "Authenticated users can create replies"
  on forum_replies for insert
  with check (auth.uid() = author_id);

create policy "Authors can update own replies"
  on forum_replies for update
  using (auth.uid() = author_id);

-- SECURITY FIX: Authors can delete their own replies
create policy "Authors can delete own replies"
  on forum_replies for delete
  using (auth.uid() = author_id);

create policy "Admins can moderate all replies"
  on forum_replies for all
  using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

-- ── forum_reports ──
create policy "Authenticated users can create reports"
  on forum_reports for insert
  with check (auth.uid() = reporter_id);

create policy "Users can view own reports"
  on forum_reports for select
  using (auth.uid() = reporter_id);

create policy "Admins can manage all reports"
  on forum_reports for all
  using (exists (select 1 from profiles where id = auth.uid() and role = 'admin'));

-- ── forum_saves ──
create policy "Users can manage own saves"
  on forum_saves for all
  using (auth.uid() = user_id);

-- ── forum_follows ──
create policy "Users can manage own follows"
  on forum_follows for all
  using (auth.uid() = user_id);

-- ============================================================
-- STORAGE BUCKETS & POLICIES
-- ============================================================

INSERT INTO storage.buckets (id, name, public) VALUES 
  ('avatars', 'avatars', true),
  ('doctor-identities', 'doctor-identities', false),
  ('doctor-verifications', 'doctor-verifications', false),
  ('patient-verifications', 'patient-verifications', false),
  ('medical-documents', 'medical-documents', false),
  ('payment-receipts', 'payment-receipts', false),
  ('patient-medical-vault', 'patient-medical-vault', false)
ON CONFLICT (id) DO NOTHING;

-- avatars
CREATE POLICY "Anyone can view avatars" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'avatars');
CREATE POLICY "Users can upload their own avatars" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Users can update their own avatars" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- doctor-identities
CREATE POLICY "Users can select their own identities" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'doctor-identities' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Users can update their own identities" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'doctor-identities' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Doctors can upload their own identities" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'doctor-identities' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Admins can view all identities" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'doctor-identities' AND exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- doctor-verifications
CREATE POLICY "Users can select their own professional credentials" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'doctor-verifications' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Users can update their own professional credentials" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'doctor-verifications' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Doctors can upload their own professional credentials" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'doctor-verifications' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Admins can view all professional credentials" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'doctor-verifications' AND exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- patient-verifications
CREATE POLICY "Users can select their own verification documents" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'patient-verifications' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Users can update their own verification documents" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'patient-verifications' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Patients can upload their own verification documents" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'patient-verifications' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Admins can view all verification documents" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'patient-verifications' AND exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- medical-documents
CREATE POLICY "Patients can select their own medical documents" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'medical-documents' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Patients can upload their own medical documents" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'medical-documents' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Patients can update their own medical documents" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'medical-documents' AND (storage.foldername(name))[1] = auth.uid()::text);

-- payment-receipts
CREATE POLICY "Users can select their own payment receipts" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'payment-receipts' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Users can update their own payment receipts" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'payment-receipts' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Patients can upload their own payment receipts" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'payment-receipts' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Admins can view all payment receipts" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'payment-receipts' AND exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

CREATE POLICY "Doctors can view receipts sent to them" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'payment-receipts' AND exists (select 1 from public.payments where payments.receipt_url LIKE '%' || name || '%' AND payments.recipient_id = auth.uid()));

-- patient-medical-vault
CREATE POLICY "Patients can select their own medical vault documents" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'patient-medical-vault' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Patients can update their own medical vault documents" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'patient-medical-vault' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Patients can delete their own medical vault documents" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'patient-medical-vault' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Patients can upload their own medical vault documents" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'patient-medical-vault' AND (storage.foldername(name))[1] = auth.uid()::text);
-- SECURITY FIX: Doctors can only view vault files if they have explicit record_permissions for the patient's record
CREATE POLICY "Doctors can view shared medical vault documents" ON storage.objects FOR SELECT TO authenticated USING (
  bucket_id = 'patient-medical-vault'
  AND (
    -- Admin access
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
    OR
    -- Doctor access: the file's owner must have granted record_permissions to this doctor
    exists (
      select 1 from public.record_permissions rp
      join public.medical_records mr on mr.id = rp.record_id
      where rp.doctor_id = auth.uid()
        and mr.patient_id::text = (storage.foldername(name))[1]
    )
  )
);
