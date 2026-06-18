-- Migration: Update profiles table for advanced identity verification
-- Goal: Add front/back ID document support and ID type selection.

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS identity_document_front_url text,
ADD COLUMN IF NOT EXISTS identity_document_back_url text,
ADD COLUMN IF NOT EXISTS identity_type text,
ADD COLUMN IF NOT EXISTS rejection_reason text;

-- Optional: Comment on columns for documentation
COMMENT ON COLUMN public.profiles.identity_document_front_url IS 'Path to the front side of the government-issued ID.';
COMMENT ON COLUMN public.profiles.identity_document_back_url IS 'Path to the back side of the government-issued ID (if applicable).';
COMMENT ON COLUMN public.profiles.identity_type IS 'The type of ID uploaded (e.g., Passport, National ID, Driver''s License).';

-- Ensure storage bucket exists for doctor identities (private)
INSERT INTO storage.buckets (id, name, public)
VALUES ('doctor-identities', 'doctor-identities', false)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies for doctor-identities bucket
CREATE POLICY "Doctors can upload their own identity documents."
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'doctor-identities' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Doctors can view their own identity documents."
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'doctor-identities' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Admins can view all identity documents."
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'doctor-identities' AND
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );
