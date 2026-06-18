-- SQL Patch for Admin Financial & Monitoring Modules
-- Created: 2026-05-15

-- 1. Payouts System
create type payout_status as enum ('pending', 'approved', 'rejected', 'failed');

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

-- 2. Refunds System
create type refund_status as enum ('pending', 'approved', 'rejected');

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
create type dispute_status as enum ('open', 'under_review', 'resolved', 'dismissed');

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

create policy "Users can view their own disputes"
  on disputes for select
  using (auth.uid() = user_id);

-- 4. Risk & Monitoring Updates
alter table payments add column risk_score numeric default 0;
alter table payments add column risk_level text check (risk_level in ('low', 'medium', 'high')) default 'low';
alter table payments add column flagged_reasons text[] default '{}';

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

create policy "Anyone can see if they are blocked"
  on blocked_users for select
  using (true);

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

-- Seed defaults
insert into notification_channels_config (id, is_enabled)
values 
  ('in_app', true),
  ('email', true),
  ('sms', true),
  ('push', true),
  ('telegram', false),
  ('whatsapp', false)
on conflict (id) do nothing;

-- 6. Analytics Helper Functions (for Dashboard stats)
create or replace function get_admin_financial_stats()
returns json
language plpgsql
security definer
as $$
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
$$;

-- ============================================================
-- DATA API GRANTS (Supabase May 30 Update Compliance)
-- ============================================================

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
