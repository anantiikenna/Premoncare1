-- Migration to support manual doctor payments
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS payment_instructions TEXT;

-- Update system settings for manual payment pivot
UPDATE system_settings 
SET allow_doctor_pricing = true, 
    base_consultation_fee = 0,
    manual_payment_instructions = 'Bank Transfer: [Naira Merchant Bank / 1234567890]. Please upload your practitioner subscription payment receipt below.'
WHERE id = 'default';

-- Function to securely increment time balance
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policy for patients to view balance (Check existence first)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_policies 
        WHERE policyname = 'Patients can view their own time balances' 
        AND tablename = 'time_balances'
    ) THEN
        CREATE POLICY "Patients can view their own time balances"
        ON time_balances FOR SELECT
        USING (auth.uid() = patient_id);
    END IF;
END $$;

-- Phase 7: Identity & Facial Verification for Practitioners 
-- Add identity verification columns to profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS identity_document_url TEXT,
ADD COLUMN IF NOT EXISTS live_selfie_url TEXT;

-- Create private bucket for doctor identities if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('doctor-identities', 'doctor-identities', false)
ON CONFLICT (id) DO NOTHING;

-- Set up RLS for the private bucket
-- 1. Doctors can upload their own identity documents
DROP POLICY IF EXISTS "Doctors can upload their own identities" ON storage.objects;
CREATE POLICY "Doctors can upload their own identities"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'doctor-identities' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- 2. Doctors can view their own identity documents
DROP POLICY IF EXISTS "Doctors can view their own identities" ON storage.objects;
CREATE POLICY "Doctors can view their own identities"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'doctor-identities' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Admins can view ALL identity documents for verification
DROP POLICY IF EXISTS "Admins can view all identites" ON storage.objects;
CREATE POLICY "Admins can view all identites"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'doctor-identities' AND
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role = 'admin'
    )
);
