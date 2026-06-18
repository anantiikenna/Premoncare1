-- Premon Care System Update Patch 
-- Date: April 2026
-- Run this in your Supabase SQL Editor to fix Patient Profiles and Practitioner Uploads

-- 1. ADD MISSING PATIENT PROFILE COLUMNS
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS dob DATE,
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS blood_group TEXT,
ADD COLUMN IF NOT EXISTS next_of_kin_name TEXT,
ADD COLUMN IF NOT EXISTS next_of_kin_phone TEXT,
ADD COLUMN IF NOT EXISTS emergency_contact_name TEXT,
ADD COLUMN IF NOT EXISTS emergency_contact_phone TEXT;

-- 2. FIX RLS FOR STORAGE BUCKETS (Allows UPSERT uploads without security violation)
-- For doctor-identities
DROP POLICY IF EXISTS "Users can select their own identities" ON storage.objects;
CREATE POLICY "Users can select their own identities"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'doctor-identities' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can update their own identities" ON storage.objects;
CREATE POLICY "Users can update their own identities"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'doctor-identities' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- For doctor-verifications
DROP POLICY IF EXISTS "Users can select their own professional credentials" ON storage.objects;
CREATE POLICY "Users can select their own professional credentials"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'doctor-verifications' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can update their own professional credentials" ON storage.objects;
CREATE POLICY "Users can update their own professional credentials"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'doctor-verifications' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- For patient-verifications
DROP POLICY IF EXISTS "Users can select their own verification documents" ON storage.objects;
CREATE POLICY "Users can select their own verification documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'patient-verifications' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can update their own verification documents" ON storage.objects;
CREATE POLICY "Users can update their own verification documents"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'patient-verifications' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- For payment-receipts
DROP POLICY IF EXISTS "Users can select their own payment receipts" ON storage.objects;
CREATE POLICY "Users can select their own payment receipts"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'payment-receipts' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can update their own payment receipts" ON storage.objects;
CREATE POLICY "Users can update their own payment receipts"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'payment-receipts' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- End of patch
