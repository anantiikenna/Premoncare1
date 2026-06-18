-- SQL Patch: Dispute Resolution Center V2 Upgrade
-- Run this in your Supabase SQL Editor to upgrade the disputes table

ALTER TABLE public.disputes 
ADD COLUMN IF NOT EXISTS patient_id uuid references profiles(id),
ADD COLUMN IF NOT EXISTS doctor_id uuid references profiles(id),
ADD COLUMN IF NOT EXISTS amount numeric,
ADD COLUMN IF NOT EXISTS risk_level text check (risk_level in ('low', 'medium', 'high')) default 'low',
ADD COLUMN IF NOT EXISTS category text check (category in ('payment', 'consultation', 'refund', 'fraud', 'behavior', 'other')) default 'other';

-- Ensure API access
GRANT ALL ON TABLE public.disputes TO anon, authenticated, service_role;
