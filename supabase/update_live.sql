-- ============================================================
-- LIVE MIGRATION: Emergency Handshake Flow
-- Run this in your Supabase SQL Editor to update the live DB
-- Safe to run multiple times (idempotent)
-- ============================================================

-- 1. Add emergency statuses to appointments check constraint
--    Drops the old constraint and recreates with new statuses
DO $$
BEGIN
  -- Drop existing check constraint on appointments.status
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'appointments_status_check'
    AND conrelid = 'public.appointments'::regclass
  ) THEN
    ALTER TABLE public.appointments DROP CONSTRAINT appointments_status_check;
  END IF;
END $$;

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

-- 2. Ensure metadata column exists (jsonb, defaults to '{}')
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'appointments'
    AND column_name = 'metadata'
  ) THEN
    ALTER TABLE public.appointments
      ADD COLUMN metadata jsonb DEFAULT '{}'::jsonb;
  END IF;
END $$;

-- 3. Ensure is_emergency column exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'appointments'
    AND column_name = 'is_emergency'
  ) THEN
    ALTER TABLE public.appointments
      ADD COLUMN is_emergency boolean DEFAULT false;
  END IF;
END $$;

-- 4. Ensure total_amount column exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'appointments'
    AND column_name = 'total_amount'
  ) THEN
    ALTER TABLE public.appointments
      ADD COLUMN total_amount numeric DEFAULT 0;
  END IF;
END $$;

-- 5. Ensure payment_instructions column exists on profiles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles'
    AND column_name = 'payment_instructions'
  ) THEN
    ALTER TABLE public.profiles
      ADD COLUMN payment_instructions text;
  END IF;
END $$;

-- 6. Index for emergency request queries (doctor dashboard real-time)
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_status
  ON public.appointments (doctor_id, status);

-- 7. Index for emergency request streaming
CREATE INDEX IF NOT EXISTS idx_appointments_emergency_requests
  ON public.appointments (doctor_id, created_at DESC)
  WHERE status = 'emergency_request';

-- 8. Ensure RLS allows emergency operations
--    The existing RLS policies should cover this since they
--    use auth.uid() matching patient_id or doctor_id.
--    But guest bookings have null patient_id, so we need a
--    policy for authenticated users to insert emergency appointments.
DO $$
BEGIN
  -- Allow authenticated users to insert emergency guest bookings
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'Allow emergency guest bookings'
    AND tablename = 'appointments'
  ) THEN
    CREATE POLICY "Allow emergency guest bookings"
      ON public.appointments
      FOR INSERT
      TO authenticated
      WITH CHECK (is_emergency = true);
  END IF;

  -- Allow doctors to update emergency request status
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'Doctors can respond to emergency requests'
    AND tablename = 'appointments'
  ) THEN
    CREATE POLICY "Doctors can respond to emergency requests"
      ON public.appointments
      FOR UPDATE
      TO authenticated
      USING (
        doctor_id = auth.uid()
        AND status IN ('emergency_request', 'emergency_accepted', 'emergency_declined')
      )
      WITH CHECK (
        status IN ('emergency_accepted', 'emergency_declined')
      );
  END IF;
END $$;

-- 9. Enable Realtime on appointments (for emergency subscriptions)
--    Only add if not already part of the publication
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

-- 10. Verify the changes
SELECT
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_name = 'appointments'
AND column_name IN ('status', 'metadata', 'is_emergency', 'total_amount')
ORDER BY ordinal_position;

-- Show the constraint
SELECT
  conname,
  pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conname = 'appointments_status_check';
